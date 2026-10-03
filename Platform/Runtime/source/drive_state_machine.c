#include "drive_state_machine.h"

#include <stddef.h>
#include <string.h>

static uint_least8_t bool_u8(uint_least8_t value)
{
    return (value != 0U) ? 1U : 0U;
}

/* 判断必需硬件能力是否全部就绪。requiredFeatures 为 0 时表示不强制检查。 */
static uint_least8_t features_ready(uint32_t readyFeatures, uint32_t requiredFeatures)
{
    return ((readyFeatures & requiredFeatures) == requiredFeatures) ? 1U : 0U;
}

/* 根据当前系统状态生成授权位；状态迁移和授权输出分开，便于后续扩展。 */
static void update_authorization(DriveStateMachineContext *context,
                                 const DriveStateMachineInput *input)
{
    DriveSystemStatus *status = &context->status;

    status->gatePowerAllowed = 0U;
    status->gateLogicAllowed = 0U;
    status->pwmAllowed = 0U;
    /* Model diagnostics/recovery may run while PWM is inhibited. The runtime
     * additionally waits for its first calibrated, qualified input frame. */
    status->modelStepAllowed = bool_u8(input->initComplete);
    status->calibrationAllowed = 0U;
    status->resetRequest = 0U;

    switch (status->state) {
    case DRIVE_SYSTEM_STATE_CALIBRATION:
        /* 调零状态只允许标定动作，不允许 gate 或 PWM。 */
        status->calibrationAllowed = 1U;
        break;

    case DRIVE_SYSTEM_STATE_READY:
        /* READY 允许模型预运行和功率侧准备，但还不允许 PWM 输出。 */
        status->gatePowerAllowed = 1U;
        status->modelStepAllowed = 1U;
        break;

    case DRIVE_SYSTEM_STATE_RUN:
        /* RUN 是唯一完整放开 gate、PWM 和模型步进的状态。 */
        status->gatePowerAllowed = 1U;
        status->gateLogicAllowed = 1U;
        status->pwmAllowed = 1U;
        status->modelStepAllowed = 1U;
        break;

    case DRIVE_SYSTEM_STATE_RESETTING:
        /* 故障复位请求只在 RESETTING 状态透传给底层驱动。 */
        status->resetRequest = bool_u8(input->faultResetRequest);
        break;

    case DRIVE_SYSTEM_STATE_INIT:
    case DRIVE_SYSTEM_STATE_FAULT:
    default:
        break;
    }
}

void DriveStateMachine_defaultConfig(DriveStateMachineConfig *config)
{
    if (config == NULL) {
        return;
    }

    config->requiredFeatures = 0UL;
    config->requireCurrentZeroCalibration = 1U;
}

void DriveStateMachine_init(DriveStateMachineContext *context,
                            const DriveStateMachineConfig *config)
{
    DriveStateMachineConfig defaultConfig;

    if (context == NULL) {
        return;
    }

    memset(context, 0, sizeof(*context));
    DriveStateMachine_defaultConfig(&defaultConfig);
    context->config = (config != NULL) ? *config : defaultConfig;
    context->status.state = DRIVE_SYSTEM_STATE_INIT;
    context->status.previousState = DRIVE_SYSTEM_STATE_INIT;
}

void DriveStateMachine_step(DriveStateMachineContext *context,
                            const DriveStateMachineInput *input)
{
    DriveStateMachineInput emptyInput;
    DriveSystemState nextState;
    uint_least8_t featureReady;
    uint_least8_t calibrationRequired;
    uint_least8_t calibrationDone;
    uint_least8_t faultPresent;

    if (context == NULL) {
        return;
    }

    if (input == NULL) {
        memset(&emptyInput, 0, sizeof(emptyInput));
        input = &emptyInput;
    }

    featureReady = features_ready(input->readyFeatures, context->config.requiredFeatures);
    calibrationRequired = bool_u8(context->config.requireCurrentZeroCalibration |
                                  input->calibrationRequest);
    calibrationDone = (calibrationRequired == 0U) ? 1U : bool_u8(input->currentZeroDone);
    faultPresent = bool_u8(input->faultActive | input->faultLatched |
                           input->currentZeroFailed);

    /*
     * 状态机只负责硬件安全授权：
     * INIT 等待初始化和能力位，CALIBRATION 等待调零完成，
     * READY 等待运行请求，RUN 监控撤使能和故障。
     */
    nextState = context->status.state;

    switch (context->status.state) {
    case DRIVE_SYSTEM_STATE_INIT:
        if (faultPresent != 0U) {
            nextState = DRIVE_SYSTEM_STATE_FAULT;
        } else if ((input->initComplete != 0U) && (featureReady != 0U)) {
            nextState = (calibrationDone != 0U) ?
                        DRIVE_SYSTEM_STATE_READY :
                        DRIVE_SYSTEM_STATE_CALIBRATION;
        }
        break;

    case DRIVE_SYSTEM_STATE_CALIBRATION:
        if (faultPresent != 0U) {
            nextState = DRIVE_SYSTEM_STATE_FAULT;
        } else if ((input->initComplete == 0U) || (featureReady == 0U)) {
            nextState = DRIVE_SYSTEM_STATE_INIT;
        } else if (calibrationDone != 0U) {
            nextState = DRIVE_SYSTEM_STATE_READY;
        }
        break;

    case DRIVE_SYSTEM_STATE_READY:
        if (faultPresent != 0U) {
            nextState = DRIVE_SYSTEM_STATE_FAULT;
        } else if ((input->initComplete == 0U) || (featureReady == 0U)) {
            nextState = DRIVE_SYSTEM_STATE_INIT;
        } else if (calibrationDone == 0U) {
            nextState = DRIVE_SYSTEM_STATE_CALIBRATION;
        } else if ((input->enableRequest != 0U) && (input->runRequest != 0U)) {
            nextState = DRIVE_SYSTEM_STATE_RUN;
        }
        break;

    case DRIVE_SYSTEM_STATE_RUN:
        if (faultPresent != 0U) {
            nextState = DRIVE_SYSTEM_STATE_FAULT;
        } else if ((input->initComplete == 0U) || (featureReady == 0U)) {
            nextState = DRIVE_SYSTEM_STATE_INIT;
        } else if (calibrationDone == 0U) {
            nextState = DRIVE_SYSTEM_STATE_CALIBRATION;
        } else if ((input->enableRequest == 0U) || (input->runRequest == 0U)) {
            nextState = DRIVE_SYSTEM_STATE_READY;
        }
        break;

    case DRIVE_SYSTEM_STATE_FAULT:
        if ((input->faultResetRequest != 0U) &&
            (input->enableRequest == 0U) && (input->runRequest == 0U)) {
            nextState = DRIVE_SYSTEM_STATE_RESETTING;
        }
        break;

    case DRIVE_SYSTEM_STATE_RESETTING:
        if (faultPresent == 0U) {
            nextState = DRIVE_SYSTEM_STATE_INIT;
        } else if (input->faultResetRequest == 0U) {
            nextState = DRIVE_SYSTEM_STATE_FAULT;
        }
        break;

    default:
        nextState = DRIVE_SYSTEM_STATE_INIT;
        break;
    }

    if (nextState != context->status.state) {
        context->status.previousState = context->status.state;
        context->status.state = nextState;
        context->status.transitionCount++;
    }

    context->status.initComplete = bool_u8(input->initComplete);
    context->status.readyFeatures = input->readyFeatures;
    context->status.missingFeatures = context->config.requiredFeatures & ~input->readyFeatures;
    context->status.featuresReady = featureReady;
    context->status.faultActive = bool_u8(input->faultActive);
    context->status.faultLatched = bool_u8(input->faultLatched);
    context->status.calibrationRequired = calibrationRequired;

    update_authorization(context, input);
}

const DriveSystemStatus *DriveStateMachine_getStatus(const DriveStateMachineContext *context)
{
    return (context != NULL) ? &context->status : NULL;
}
