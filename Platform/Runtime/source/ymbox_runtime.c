#include "ymbox_runtime.h"
#include "ymbox_port.h"
#include "ymbox_model_adapter.h"
#include "drive_framework.h"
#include "ymbox_math_init.h"

#include <float.h>
#include <math.h>
#include <stddef.h>
#include <string.h>

/* Only the fast IRQ touches framework/model state. The mailbox, trip state and
 * published status are shared exclusively under the board critical-section API. */
static struct {
    const YMBOX_BuildInfo *build;
    YMBOX_BoardInfo board;
    DriveFrameworkContext framework;
    YMBOX_ModelOutput model;
    YMBOX_Command command;
    YMBOX_Status published;
    uint32_t commandTime;
    uint32_t commandSerial;
    uint32_t rejectedCommands;
    uint32_t backgroundCalls;
    uint32_t tripGeneration;
    uint32_t latchedFaults;
    uint32_t lastCallTime;
    uint32_t lastSampleSequence;
    uint32_t fastCalls;
    uint32_t modelSteps;
    uint32_t maxExecution;
    uint16_t commandAlive;
    uint16_t tripCode;
    bool initialized;
    bool inFast;
    bool tripLatched;
    bool haveCommand;
    bool haveCall;
    bool haveSample;
    bool modelStarted;
} runtime;

static YMBOX_OutputCommand off_command(void)
{
    YMBOX_OutputCommand out = {0.5F, 0.5F, 0.5F, false, false, false};
    return out;
}

static bool matches(float actual, float expected, float tolerance)
{
    return isfinite(actual) && isfinite(expected) &&
        fabsf(actual - expected) <= tolerance;
}

static void latch_fault(uint32_t faults, uint16_t code)
{
    uint32_t mask = YMBOX_Port_EnterCritical();
    runtime.latchedFaults |= faults;
    if (!runtime.tripLatched) {
        runtime.tripGeneration++;
    }
    runtime.tripLatched = true;
    if (runtime.tripCode == 0U) {
        runtime.tripCode = code;
    }
    YMBOX_Port_Trip();
    YMBOX_Port_ExitCritical(mask);
}

const YMBOX_BuildInfo *YMBOX_GetBuildInfo(void)
{
    return YMBOX_Model_BuildInfo();
}

bool YMBOX_Init(void)
{
    DriveFrameworkConfig config;
    YMBOX_OutputCommand off = off_command();
    const YMBOX_BuildInfo *b = YMBOX_Model_BuildInfo();
    YMBOX_Port_Trip();
    memset(&runtime, 0, sizeof(runtime));
    runtime.build = b;
    if (b == NULL || b->abiVersion != YMBOX_PORT_ABI_VERSION ||
        b->controlPeriod_us == 0U || b->controlPeriod_us >= UINT32_C(0x40000000) ||
        b->commandTimeout_us == 0U || b->commandTimeout_us >= UINT32_C(0x80000000) ||
        b->sampleMaxAge_us >= UINT32_C(0x80000000) || b->mdtmDivider == 0U ||
        !isfinite(b->minDuty) || !isfinite(b->maxDuty) ||
        b->minDuty < 0.0F || b->maxDuty > 1.0F || b->minDuty >= b->maxDuty ||
        !YMBOX_Port_Init(b, &runtime.board)) {
        return false;
    }
    if (runtime.board.abiVersion != b->abiVersion ||
        runtime.board.controlPeriod_us != b->controlPeriod_us ||
        (runtime.board.features & b->requiredFeatures) != b->requiredFeatures ||
        (runtime.board.supportedModes & b->supportedModes & ~UINT32_C(1)) == 0U ||
        !matches(runtime.board.pwmFrequency_Hz, b->pwmFrequency_Hz,
                 fabsf(b->pwmFrequency_Hz) * b->timingTolerance_ppm * 1.0e-6F) ||
        !matches(runtime.board.deadTime_s, b->deadTime_s,
                 fmaxf(fabsf(b->deadTime_s) * 1.0e-5F, 1.0e-10F)) ||
        !matches(runtime.board.minDuty, b->minDuty, 4.0F * FLT_EPSILON) ||
        !matches(runtime.board.maxDuty, b->maxDuty, 4.0F * FLT_EPSILON) ||
        (((runtime.board.supportedModes & b->positionRequiredModes) != 0U) &&
         (runtime.board.positionCountsPerRev != b->positionCountsPerRev ||
          (runtime.board.features & DRIVE_FEATURE_POSITION_FEEDBACK) == 0U))) {
        YMBOX_Port_Trip();
        return false;
    }
    DriveFramework_defaultConfig(&config);
    config.minDuty = b->minDuty;
    config.maxDuty = b->maxDuty;
    config.stateConfig.requiredFeatures = b->requiredFeatures;
    DriveFramework_init(&runtime.framework, &config);
    YMBOX_Math_Init();
    YMBOX_Model_Initialize();
    /* Port_Init is responsible for a safe initial off state. Clear only the
     * startup inhibition, never a live fault. Failure is a latched runtime fault. */
    if (!YMBOX_Port_ClearTrip() || !YMBOX_Port_ApplyOutput(&off)) {
        YMBOX_Port_Trip();
        return false;
    }
    runtime.initialized = true;
    runtime.published.initialized = true;
    runtime.published.applied = off;
    DriveFramework_setInitComplete(&runtime.framework, 1U);
    return true;
}

bool YMBOX_SetCommand(const YMBOX_Command *command)
{
    uint32_t mask;
    bool valid;
    const YMBOX_BuildInfo *b = runtime.build;
    valid = command != NULL && b != NULL && runtime.initialized;
    if (valid) {
        valid = command->mode <= 6U &&
            (command->mode == 0U ||
             ((b->supportedModes & runtime.board.supportedModes &
               YMBOX_MODE_BIT(command->mode)) != 0U)) &&
            !(command->clearFault && command->enable) &&
            isfinite(command->speed_rpm) && isfinite(command->torque_Nm) &&
            isfinite(command->testD) && isfinite(command->testQ);
    }
    mask = YMBOX_Port_EnterCritical();
    if (valid) {
        runtime.command = *command;
        runtime.commandTime = YMBOX_Port_TimeUs();
        runtime.commandAlive++; /* exactly once per accepted command */
        runtime.commandSerial++;
        runtime.haveCommand = true;
    } else {
        runtime.rejectedCommands++;
    }
    YMBOX_Port_ExitCritical(mask);
    return valid;
}

void YMBOX_TripISR(uint16_t code)
{
    uint32_t mask = YMBOX_Port_EnterCritical();
    /* Every asynchronous trip changes the generation, even while already off,
     * so a concurrent reset can never erase a newly arrived event. */
    runtime.tripGeneration++;
    runtime.latchedFaults |= YMBOX_FAULT_EXTERNAL_TRIP;
    runtime.tripLatched = true;
    runtime.tripCode = code != 0U ? code : YMBOX_RUNTIME_HW_CODE;
    YMBOX_Port_Trip();
    YMBOX_Port_ExitCritical(mask);
}

static uint32_t check_sample(YMBOX_FastSample *s, const YMBOX_Command *command,
                             uint32_t now, bool readOk)
{
    uint32_t faults = 0U;
    uint16_t required = YMBOX_VALID_CURRENTS | YMBOX_VALID_VDC;
    unsigned int i;
    if (runtime.build->physicalDcCurrentRequired) {
        required |= YMBOX_VALID_IDC;
    }
    if (command->enable && command->mode <= 6U &&
        (runtime.build->positionRequiredModes & YMBOX_MODE_BIT(command->mode)) != 0U) {
        required |= YMBOX_VALID_POSITION;
    }
    if (!readOk) {
        s->validMask = 0U;
        faults |= YMBOX_FAULT_SAMPLE;
    }
    for (i = 0U; i < 3U; i++) {
        if (!isfinite(s->phaseCurrent_A[i])) {
            s->phaseCurrent_A[i] = 0.0F;
            s->validMask &= (uint16_t)~(1U << i);
        }
    }
    if (!isfinite(s->dcVoltage_V)) {
        s->dcVoltage_V = 0.0F;
        s->validMask &= (uint16_t)~YMBOX_VALID_VDC;
    }
    if (!isfinite(s->dcCurrent_A)) {
        s->dcCurrent_A = 0.0F;
        s->validMask &= (uint16_t)~YMBOX_VALID_IDC;
    }
    if ((s->validMask & YMBOX_VALID_POSITION) != 0U &&
        s->positionCount >= runtime.build->positionCountsPerRev) {
        s->validMask &= (uint16_t)~YMBOX_VALID_POSITION;
    }
    if ((s->validMask & YMBOX_VALID_POSITION) == 0U) {
        s->positionCount = 0U;
    }
    if ((s->validMask & required) != required) {
        faults |= YMBOX_FAULT_SAMPLE;
    }
    if ((uint32_t)(now - s->sampleTime_us) > runtime.build->sampleMaxAge_us ||
        (runtime.haveSample && (uint32_t)(s->sequence - runtime.lastSampleSequence) != 1U)) {
        faults |= YMBOX_FAULT_SAMPLE_AGE;
    }
    if (!isfinite(s->torqueLimitFactor) || s->torqueLimitFactor < 0.0F ||
        s->torqueLimitFactor > 1.0F) {
        s->torqueLimitFactor = 0.0F;
        faults |= YMBOX_FAULT_SAMPLE;
    }
    if (s->hwFaultActive || s->currentZeroFailed) {
        faults |= YMBOX_FAULT_HARDWARE;
    }
    return faults;
}

static bool output_valid(const YMBOX_ModelOutput *o)
{
    const float eps = 4.0F * FLT_EPSILON;
    bool modeOk = o->mode <= 5U ||
        (((runtime.build->supportedModes & YMBOX_MODE_BIT(6U)) != 0U) &&
         (o->mode == 16U || o->mode == 17U));
    return modeOk && isfinite(o->dutyU) && isfinite(o->dutyV) && isfinite(o->dutyW) &&
        o->dutyU >= runtime.build->minDuty - eps &&
        o->dutyV >= runtime.build->minDuty - eps &&
        o->dutyW >= runtime.build->minDuty - eps &&
        o->dutyU <= runtime.build->maxDuty + eps &&
        o->dutyV <= runtime.build->maxDuty + eps &&
        o->dutyW <= runtime.build->maxDuty + eps;
}

void YMBOX_FastISR(void)
{
    uint32_t mask, started, generation, commandTime, activeFaults, elapsed;
    uint16_t alive;
    bool haveCommand, readOk, ready, reset, latched, validOutput = false;
    YMBOX_Command command;
    YMBOX_FastSample sample;
    YMBOX_ModelInput modelInput;
    YMBOX_OutputCommand output = off_command();
    DriveFrameworkContext *f = &runtime.framework;
    mask = YMBOX_Port_EnterCritical();
    if (!runtime.initialized || runtime.inFast) {
        bool nested = runtime.inFast;
        YMBOX_Port_ExitCritical(mask);
        latch_fault(nested ? YMBOX_FAULT_REENTRANT : YMBOX_FAULT_READINESS,
                    YMBOX_RUNTIME_HW_CODE);
        return;
    }
    runtime.inFast = true;
    command = runtime.command;
    commandTime = runtime.commandTime;
    haveCommand = runtime.haveCommand;
    alive = runtime.commandAlive;
    generation = runtime.tripGeneration;
    YMBOX_Port_ExitCritical(mask);
    started = YMBOX_Port_TimeUs();
    runtime.fastCalls++;
    memset(&sample, 0, sizeof(sample));
    readOk = YMBOX_Port_ReadFast(&sample);
    activeFaults = check_sample(&sample, &command, YMBOX_Port_TimeUs(), readOk);
    ready = readOk && sample.currentZeroDone && !sample.currentZeroFailed &&
        ((sample.readyFeatures & runtime.build->requiredFeatures) == runtime.build->requiredFeatures);
    if (runtime.haveCall &&
        (uint32_t)(started - runtime.lastCallTime) >= 2U * runtime.build->controlPeriod_us) {
        activeFaults |= YMBOX_FAULT_DEADLINE;
    }
    if (haveCommand && command.enable &&
        (uint32_t)(started - commandTime) >= runtime.build->commandTimeout_us) {
        activeFaults |= YMBOX_FAULT_COMMAND_AGE;
    }
    if (runtime.modelStarted && !ready) {
        activeFaults |= YMBOX_FAULT_READINESS;
    }
    /* Allow startup calibration without manufacturing invalid-current faults.
     * After the first qualified frame, invalid data is always reported and
     * diagnostics keep stepping with invalid/nonfinite fields sanitized. */
    if (!runtime.modelStarted && !ready) {
        activeFaults &= YMBOX_FAULT_HARDWARE | YMBOX_FAULT_COMMAND_AGE | YMBOX_FAULT_DEADLINE;
    } else if (!runtime.modelStarted && activeFaults == 0U) {
        runtime.modelStarted = true;
    }
    runtime.lastCallTime = started;
    runtime.haveCall = true;
    if (readOk) {
        runtime.lastSampleSequence = sample.sequence;
        runtime.haveSample = true;
    }
    if (activeFaults != 0U) {
        latch_fault(activeFaults, sample.hwFaultActive ? sample.hwFaultCode : YMBOX_RUNTIME_HW_CODE);
    }
    reset = haveCommand && command.clearFault && !command.enable && ready &&
        (uint32_t)(started - commandTime) < runtime.build->commandTimeout_us;
    /* Release the board inhibition before asking MDFM to finish its recovery
     * hold. No PWM is permitted until both latches clear and a new enable arrives. */
    if (reset && activeFaults == 0U && sample.platformFaultMask == 0U) {
        mask = YMBOX_Port_EnterCritical();
        if (runtime.tripGeneration == generation && YMBOX_Port_ClearTrip() &&
            runtime.tripGeneration == generation) {
            runtime.latchedFaults = 0U;
            runtime.tripLatched = false;
            runtime.tripCode = 0U;
        }
        YMBOX_Port_ExitCritical(mask);
    }
    mask = YMBOX_Port_EnterCritical();
    latched = runtime.tripLatched;
    YMBOX_Port_ExitCritical(mask);
    f->appRequest.enableRequest = command.enable && haveCommand;
    f->appRequest.runRequest = f->appRequest.enableRequest && command.mode != 0U;
    f->appRequest.faultResetRequest = reset;
    f->appRequest.controlModeRequest = (DriveControlMode)command.mode;
    f->appRequest.speedRefRpm = command.speed_rpm;
    f->appRequest.torqueRefNm = command.torque_Nm;
    f->readyFeatures = sample.readyFeatures;
    f->calibrationStatus.currentZeroDone = sample.currentZeroDone;
    f->calibrationStatus.currentZeroFailed = sample.currentZeroFailed;
    f->faultStatus.active = activeFaults != 0U;
    f->faultStatus.latched = latched || runtime.model.faultLatched;
    DriveFramework_stepState(f);
    DriveFramework_buildModelInput(f);
    if (runtime.modelStarted) {
        memset(&modelInput, 0, sizeof(modelInput));
        modelInput.sample = sample;
        modelInput.command = command;
        modelInput.commandAlive = alive;
        modelInput.enable = f->modelInput.request.runRequest && !latched && activeFaults == 0U;
        modelInput.clearFault = reset;
        modelInput.runtimeFaultActive = activeFaults != 0U;
        YMBOX_Model_Step(&modelInput, &runtime.model);
        runtime.modelSteps++;
        validOutput = output_valid(&runtime.model);
        if (!validOutput) {
            latch_fault(YMBOX_FAULT_OUTPUT, YMBOX_RUNTIME_HW_CODE);
        }
        f->modelOutput.valid = validOutput;
        f->modelOutput.requestStop = runtime.model.stopRequest || runtime.model.pwmDisableRequest ||
            runtime.model.faultLatched || runtime.model.mode == 0U;
        f->modelOutput.duty.mode = DRIVE_PWM_MODE_DUTY;
        f->modelOutput.duty.valid = validOutput;
        f->modelOutput.duty.dutyA = runtime.model.dutyU;
        f->modelOutput.duty.dutyB = runtime.model.dutyV;
        f->modelOutput.duty.dutyC = runtime.model.dutyW;
        DriveFramework_composeHwCommand(f);
        output.dutyU = f->hwCommand.duty.dutyA;
        output.dutyV = f->hwCommand.duty.dutyB;
        output.dutyW = f->hwCommand.duty.dutyC;
        output.pwmEnable = f->hwCommand.pwmEnable != 0U;
        output.gatePowerEnable = f->hwCommand.gatePowerEnable != 0U;
        output.gateLogicEnable = output.pwmEnable && f->hwCommand.gateLogicEnable != 0U;
    }
    elapsed = (uint32_t)(YMBOX_Port_TimeUs() - started);
    if (elapsed >= runtime.build->controlPeriod_us) {
        latch_fault(YMBOX_FAULT_DEADLINE, YMBOX_RUNTIME_HW_CODE);
    }
    mask = YMBOX_Port_EnterCritical();
    if (runtime.tripLatched || runtime.tripGeneration != generation || !validOutput) {
        output = off_command();
    }
    if (!YMBOX_Port_ApplyOutput(&output)) {
        latch_fault(YMBOX_FAULT_OUTPUT, YMBOX_RUNTIME_HW_CODE);
        output = off_command();
    }
    elapsed = (uint32_t)(YMBOX_Port_TimeUs() - started);
    if (elapsed >= runtime.build->controlPeriod_us) {
        latch_fault(YMBOX_FAULT_DEADLINE, YMBOX_RUNTIME_HW_CODE);
        output = off_command();
    }
    if (elapsed > runtime.maxExecution) {
        runtime.maxExecution = elapsed;
    }
    runtime.published.model = runtime.model;
    runtime.published.applied = output;
    runtime.published.state = f->stateMachine.status.state;
    runtime.published.runtimeFaults = runtime.latchedFaults;
    runtime.published.fastCalls = runtime.fastCalls;
    runtime.published.modelSteps = runtime.modelSteps;
    runtime.published.backgroundCalls = runtime.backgroundCalls;
    runtime.published.acceptedCommands = runtime.commandSerial;
    runtime.published.rejectedCommands = runtime.rejectedCommands;
    runtime.published.commandAge_us = haveCommand ? (uint32_t)(started-commandTime) : UINT32_MAX;
    runtime.published.sampleAge_us = (uint32_t)(started-sample.sampleTime_us);
    runtime.published.lastExecution_us = elapsed;
    runtime.published.maxExecution_us = runtime.maxExecution;
    runtime.published.tripCode = runtime.tripCode;
    runtime.published.modelStarted = runtime.modelStarted;
    runtime.published.tripLatched = runtime.tripLatched;
    runtime.inFast = false;
    YMBOX_Port_ExitCritical(mask);
}

void YMBOX_Background(void)
{
    uint32_t mask;
    YMBOX_Port_Background();
    mask = YMBOX_Port_EnterCritical();
    runtime.backgroundCalls++;
    YMBOX_Port_ExitCritical(mask);
}

bool YMBOX_GetStatus(YMBOX_Status *status)
{
    uint32_t mask;
    if (status == NULL) {
        return false;
    }
    mask = YMBOX_Port_EnterCritical();
    *status = runtime.published;
    /* Include asynchronous faults immediately, even if the sampling IRQ stopped. */
    status->runtimeFaults = runtime.latchedFaults;
    status->tripLatched = runtime.tripLatched;
    status->tripCode = runtime.tripCode;
    status->backgroundCalls = runtime.backgroundCalls;
    status->acceptedCommands = runtime.commandSerial;
    status->rejectedCommands = runtime.rejectedCommands;
    if (runtime.tripLatched) {
        status->applied = off_command();
    }
    YMBOX_Port_ExitCritical(mask);
    return true;
}
