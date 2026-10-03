#ifndef DRIVE_FRAMEWORK_H_
#define DRIVE_FRAMEWORK_H_

#include "drive_rte.h"
#include "drive_state_machine.h"

#ifdef __cplusplus
extern "C" {
#endif

/* 框架配置：状态机配置 + PWM 输出限幅，换硬件时优先改这里。 */
typedef struct {
    DriveStateMachineConfig stateConfig;
    DriveFloat minDuty;
    DriveFloat maxDuty;
    DriveFloat neutralDuty;
} DriveFrameworkConfig;

/*
 * 底层框架总上下文。
 * 上层 CAN 写 appRequest，板级驱动写 feedback/fault/calibration，
 * 模型写 modelOutput，框架负责合成 modelInput 和 hwCommand。
 */
typedef struct {
    DriveFrameworkConfig config;
    DriveStateMachineContext stateMachine;
    DriveAppRequest appRequest;
    DriveSensorFeedback sensorFeedback;
    DriveFaultStatus faultStatus;
    DriveCalibrationStatus calibrationStatus;
    DriveModelInput modelInput;
    DriveModelOutput modelOutput;
    DriveHwCommand hwCommand;
    DriveRuntimeDiagnostics diagnostics;
    uint_least8_t initComplete;
    uint32_t readyFeatures;
} DriveFrameworkContext;

void DriveFramework_defaultConfig(DriveFrameworkConfig *config);
void DriveFramework_init(DriveFrameworkContext *context,
                         const DriveFrameworkConfig *config);

/* 板级初始化完成后置位；掉电、复位或关键外设异常时应清零。 */
void DriveFramework_setInitComplete(DriveFrameworkContext *context, uint_least8_t initComplete);

/* 写入当前已就绪的硬件能力位，由 ADC/PWM/CAN/位置采样等驱动共同维护。 */
void DriveFramework_setReadyFeatures(DriveFrameworkContext *context, uint32_t readyFeatures);

/* 写入上层命令，通常由 CAN 解码层调用。 */
void DriveFramework_setAppRequest(DriveFrameworkContext *context,
                                  const DriveAppRequest *request);

/* 写入采样反馈，通常由 ADC、母线电压、温度和位置传感驱动调用。 */
void DriveFramework_setSensorFeedback(DriveFrameworkContext *context,
                                      const DriveSensorFeedback *feedback);

/* 写入故障状态，通常由硬件保护、采样诊断和通信监控共同更新。 */
void DriveFramework_setFaultStatus(DriveFrameworkContext *context,
                                   const DriveFaultStatus *fault);

/* 写入调零状态，用于状态机判断是否可以进入 READY/RUN。 */
void DriveFramework_setCalibrationStatus(DriveFrameworkContext *context,
                                         const DriveCalibrationStatus *calibration);

/* 写入模型输出；框架会在 composeHwCommand 中再次做安全门控。 */
void DriveFramework_setModelOutput(DriveFrameworkContext *context,
                                   const DriveModelOutput *output);

/* 先刷新状态机授权。推荐顺序：set 输入 -> stepState -> buildModelInput -> 跑模型 -> setModelOutput -> refresh。 */
void DriveFramework_stepState(DriveFrameworkContext *context);

/* 将 CAN 请求、采样反馈、调零状态和状态机授权打包给模型。 */
void DriveFramework_buildModelInput(DriveFrameworkContext *context);

/* 根据状态机授权和模型输出合成最终硬件命令。 */
void DriveFramework_composeHwCommand(DriveFrameworkContext *context);

/* 便捷刷新：构造模型输入、合成硬件命令并更新诊断计数。 */
void DriveFramework_refresh(DriveFrameworkContext *context);

const DriveModelInput *DriveFramework_getModelInput(const DriveFrameworkContext *context);
const DriveHwCommand *DriveFramework_getHwCommand(const DriveFrameworkContext *context);
const DriveSystemStatus *DriveFramework_getSystemStatus(const DriveFrameworkContext *context);
const DriveRuntimeDiagnostics *DriveFramework_getDiagnostics(const DriveFrameworkContext *context);

#ifdef __cplusplus
}
#endif

#endif
