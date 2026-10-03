#ifndef DRIVE_STATE_MACHINE_H_
#define DRIVE_STATE_MACHINE_H_

#include "drive_rte.h"

#ifdef __cplusplus
extern "C" {
#endif

/* 状态机配置：不同控制器只需要调整必需硬件能力和是否要求电流调零。 */
typedef struct {
    uint32_t requiredFeatures;
    uint_least8_t requireCurrentZeroCalibration;
} DriveStateMachineConfig;

/* 状态机单步输入：只保留安全授权相关信号，不混入具体控制算法量。 */
typedef struct {
    uint_least8_t initComplete;
    uint32_t readyFeatures;
    uint_least8_t enableRequest;
    uint_least8_t runRequest;
    uint_least8_t faultResetRequest;
    uint_least8_t calibrationRequest;
    uint_least8_t currentZeroDone;
    uint_least8_t currentZeroFailed;
    uint_least8_t faultActive;
    uint_least8_t faultLatched;
} DriveStateMachineInput;

/* 状态机上下文，调用方长期持有；不要在运行中直接改 status，统一走 step。 */
typedef struct {
    DriveStateMachineConfig config;
    DriveSystemStatus status;
} DriveStateMachineContext;

/* 填充默认配置，适合框架启动时先初始化再按项目覆盖。 */
void DriveStateMachine_defaultConfig(DriveStateMachineConfig *config);

/* 初始化状态机上下文，初始状态固定为 INIT。 */
void DriveStateMachine_init(DriveStateMachineContext *context,
                            const DriveStateMachineConfig *config);

/* 执行一次状态迁移和授权位刷新，建议在主循环固定周期调用。 */
void DriveStateMachine_step(DriveStateMachineContext *context,
                            const DriveStateMachineInput *input);

/* 只读获取当前状态机输出，用于构造模型输入和硬件命令。 */
const DriveSystemStatus *DriveStateMachine_getStatus(const DriveStateMachineContext *context);

#ifdef __cplusplus
}
#endif

#endif
