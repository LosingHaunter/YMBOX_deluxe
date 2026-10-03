#include "drive_framework.h"

#include <stddef.h>
#include <string.h>
#include <math.h>

static DriveFloat clamp_float(DriveFloat value, DriveFloat minValue, DriveFloat maxValue)
{
    if (value < minValue) {
        return minValue;
    }

    if (value > maxValue) {
        return maxValue;
    }

    return value;
}

/* 安全默认输出：不开 PWM，三相保持中点占空比。 */
static void set_neutral_duty(DriveFrameworkContext *context)
{
    context->hwCommand.duty.mode = DRIVE_PWM_MODE_OFF;
    context->hwCommand.duty.dutyA = context->config.neutralDuty;
    context->hwCommand.duty.dutyB = context->config.neutralDuty;
    context->hwCommand.duty.dutyC = context->config.neutralDuty;
    context->hwCommand.duty.valid = 0U;
}

void DriveFramework_defaultConfig(DriveFrameworkConfig *config)
{
    if (config == NULL) {
        return;
    }

    DriveStateMachine_defaultConfig(&config->stateConfig);
    config->minDuty = 0.0F;
    config->maxDuty = 1.0F;
    config->neutralDuty = 0.5F;
}

void DriveFramework_init(DriveFrameworkContext *context,
                         const DriveFrameworkConfig *config)
{
    DriveFrameworkConfig defaultConfig;

    if (context == NULL) {
        return;
    }

    memset(context, 0, sizeof(*context));
    DriveFramework_defaultConfig(&defaultConfig);
    context->config = (config != NULL) ? *config : defaultConfig;
    DriveStateMachine_init(&context->stateMachine, &context->config.stateConfig);
    set_neutral_duty(context);
}

void DriveFramework_setInitComplete(DriveFrameworkContext *context, uint_least8_t initComplete)
{
    if (context != NULL) {
        context->initComplete = (initComplete != 0U) ? 1U : 0U;
    }
}

void DriveFramework_setReadyFeatures(DriveFrameworkContext *context, uint32_t readyFeatures)
{
    if (context != NULL) {
        context->readyFeatures = readyFeatures;
    }
}

void DriveFramework_setAppRequest(DriveFrameworkContext *context,
                                  const DriveAppRequest *request)
{
    if ((context != NULL) && (request != NULL)) {
        context->appRequest = *request;
    }
}

void DriveFramework_setSensorFeedback(DriveFrameworkContext *context,
                                      const DriveSensorFeedback *feedback)
{
    if ((context != NULL) && (feedback != NULL)) {
        context->sensorFeedback = *feedback;
    }
}

void DriveFramework_setFaultStatus(DriveFrameworkContext *context,
                                   const DriveFaultStatus *fault)
{
    if ((context != NULL) && (fault != NULL)) {
        context->faultStatus = *fault;
    }
}

void DriveFramework_setCalibrationStatus(DriveFrameworkContext *context,
                                         const DriveCalibrationStatus *calibration)
{
    if ((context != NULL) && (calibration != NULL)) {
        context->calibrationStatus = *calibration;
    }
}

void DriveFramework_setModelOutput(DriveFrameworkContext *context,
                                   const DriveModelOutput *output)
{
    if ((context != NULL) && (output != NULL)) {
        context->modelOutput = *output;
    }
}

void DriveFramework_stepState(DriveFrameworkContext *context)
{
    DriveStateMachineInput input;

    if (context == NULL) {
        return;
    }

    memset(&input, 0, sizeof(input));
    input.initComplete = context->initComplete;
    input.readyFeatures = context->readyFeatures;
    input.enableRequest = context->appRequest.enableRequest;
    input.runRequest = context->appRequest.runRequest;
    input.faultResetRequest = context->appRequest.faultResetRequest;
    input.calibrationRequest = context->appRequest.calibrationRequest;
    input.currentZeroDone = context->calibrationStatus.currentZeroDone;
    input.currentZeroFailed = context->calibrationStatus.currentZeroFailed;
    input.faultActive = context->faultStatus.active;
    input.faultLatched = context->faultStatus.latched;

    /* 状态机只接收安全相关输入，不接收转速/转矩等控制目标。 */
    DriveStateMachine_step(&context->stateMachine, &input);
}

void DriveFramework_buildModelInput(DriveFrameworkContext *context)
{
    const DriveSystemStatus *status;

    if (context == NULL) {
        return;
    }

    status = DriveStateMachine_getStatus(&context->stateMachine);

    /*
     * 模型输入固定由四部分组成：
     * CAN/上层请求、硬件采样反馈、调零状态、状态机授权结果。
     */
    context->modelInput.request = context->appRequest;
    context->modelInput.feedback = context->sensorFeedback;
    context->modelInput.calibration = context->calibrationStatus;

    if (status != NULL) {
        context->modelInput.system = *status;
        context->modelInput.request.enableRequest =
            (status->pwmAllowed != 0U) && (context->appRequest.enableRequest != 0U);
        context->modelInput.request.runRequest =
            (status->pwmAllowed != 0U) && (context->appRequest.runRequest != 0U);
    }
}

void DriveFramework_composeHwCommand(DriveFrameworkContext *context)
{
    const DriveSystemStatus *status;

    if (context == NULL) {
        return;
    }

    status = DriveStateMachine_getStatus(&context->stateMachine);

    /* 每次合成硬件命令前先回到安全默认值，避免上一拍有效命令残留。 */
    set_neutral_duty(context);
    context->hwCommand.gatePowerEnable = 0U;
    context->hwCommand.gateLogicEnable = 0U;
    context->hwCommand.pwmEnable = 0U;
    context->hwCommand.clearFaultRequest = 0U;
    context->hwCommand.modelStepEnable = 0U;

    if (status == NULL) {
        return;
    }

    context->hwCommand.gatePowerEnable = status->gatePowerAllowed;
    context->hwCommand.gateLogicEnable = status->gateLogicAllowed;
    context->hwCommand.modelStepEnable = status->modelStepAllowed;
    context->hwCommand.clearFaultRequest = (status->resetRequest != 0U) &&
        (context->appRequest.enableRequest == 0U) && (context->appRequest.runRequest == 0U);

    /*
     * PWM 必须同时满足底层授权和模型输出有效。
     * 即使模型给出了占空比，只要状态机未允许或模型请求停机，底层仍保持关断。
     */
    if ((status->pwmAllowed != 0U) &&
        (context->modelOutput.valid != 0U) &&
        (context->modelOutput.requestStop == 0U) &&
        (context->modelOutput.duty.mode == DRIVE_PWM_MODE_DUTY) &&
        (context->modelOutput.duty.valid != 0U) &&
        isfinite(context->modelOutput.duty.dutyA) &&
        isfinite(context->modelOutput.duty.dutyB) &&
        isfinite(context->modelOutput.duty.dutyC)) {
        context->hwCommand.pwmEnable = 1U;
        context->hwCommand.duty.mode = DRIVE_PWM_MODE_DUTY;
        context->hwCommand.duty.dutyA = clamp_float(context->modelOutput.duty.dutyA,
                                                    context->config.minDuty,
                                                    context->config.maxDuty);
        context->hwCommand.duty.dutyB = clamp_float(context->modelOutput.duty.dutyB,
                                                    context->config.minDuty,
                                                    context->config.maxDuty);
        context->hwCommand.duty.dutyC = clamp_float(context->modelOutput.duty.dutyC,
                                                    context->config.minDuty,
                                                    context->config.maxDuty);
        context->hwCommand.duty.valid = 1U;
    }
}

void DriveFramework_refresh(DriveFrameworkContext *context)
{
    if (context == NULL) {
        return;
    }

    DriveFramework_buildModelInput(context);
    DriveFramework_composeHwCommand(context);

    /* 诊断量集中在这里刷新，便于 CAN 上报或调试器周期读取。 */
    context->diagnostics.backgroundLoopCounter++;
    context->diagnostics.systemState = context->modelInput.system.state;
    context->diagnostics.modelRunState = context->modelOutput.runState;
    context->diagnostics.controlMode = context->modelOutput.controlMode;
    context->diagnostics.faultCode = context->faultStatus.code;
    context->diagnostics.pwmEnabled = context->hwCommand.pwmEnable;
    context->diagnostics.modelStepEnabled = context->hwCommand.modelStepEnable;
}

const DriveModelInput *DriveFramework_getModelInput(const DriveFrameworkContext *context)
{
    return (context != NULL) ? &context->modelInput : NULL;
}

const DriveHwCommand *DriveFramework_getHwCommand(const DriveFrameworkContext *context)
{
    return (context != NULL) ? &context->hwCommand : NULL;
}

const DriveSystemStatus *DriveFramework_getSystemStatus(const DriveFrameworkContext *context)
{
    return (context != NULL) ? DriveStateMachine_getStatus(&context->stateMachine) : NULL;
}

const DriveRuntimeDiagnostics *DriveFramework_getDiagnostics(const DriveFrameworkContext *context)
{
    return (context != NULL) ? &context->diagnostics : NULL;
}
