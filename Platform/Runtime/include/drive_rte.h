#ifndef DRIVE_RTE_H_
#define DRIVE_RTE_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef float DriveFloat;

/* 硬件能力位：由板级驱动在初始化/自检后置位，状态机用它判断系统是否具备运行条件。 */
#define DRIVE_FEATURE_GATE_POWER          (1UL << 0)
#define DRIVE_FEATURE_GATE_LOGIC          (1UL << 1)
#define DRIVE_FEATURE_PWM_OUTPUT          (1UL << 2)
#define DRIVE_FEATURE_CURRENT_FEEDBACK    (1UL << 3)
#define DRIVE_FEATURE_VOLTAGE_FEEDBACK    (1UL << 4)
#define DRIVE_FEATURE_TEMPERATURE_FEEDBACK (1UL << 5)
#define DRIVE_FEATURE_POSITION_FEEDBACK   (1UL << 6)
#define DRIVE_FEATURE_COMMAND_INTERFACE   (1UL << 7)
#define DRIVE_FEATURE_CURRENT_ZERO_CAL    (1UL << 8)

/* 底层最终支持的 PWM 输出形式。当前框架只真正下发占空比模式。 */
typedef enum {
    DRIVE_PWM_MODE_OFF = 0,
    DRIVE_PWM_MODE_DUTY = 1,
    DRIVE_PWM_MODE_VOLTAGE_VECTOR = 2
} DrivePwmMode;

/* 固定硬件状态机状态，描述控制器硬件是否允许模型运行和 PWM 输出。 */
typedef enum {
    DRIVE_SYSTEM_STATE_INIT = 0,
    DRIVE_SYSTEM_STATE_CALIBRATION = 1,
    DRIVE_SYSTEM_STATE_READY = 2,
    DRIVE_SYSTEM_STATE_RUN = 3,
    DRIVE_SYSTEM_STATE_FAULT = 4,
    DRIVE_SYSTEM_STATE_RESETTING = 5
} DriveSystemState;

/* 模型内部运行模式，主要由 MATLAB/Simulink 的 MDSM 输出，用于诊断和模式管理。 */
typedef enum {
    DRIVE_MODEL_RUN_STATE_IDLE = 0,
    DRIVE_MODEL_RUN_STATE_ZERO_CALIBRATION = 1,
    DRIVE_MODEL_RUN_STATE_ALIGN = 2,
    DRIVE_MODEL_RUN_STATE_OPEN_LOOP = 3,
    DRIVE_MODEL_RUN_STATE_CLOSED_LOOP_SENSORED = 4,
    DRIVE_MODEL_RUN_STATE_TORQUE_CONTROL = 5,
    DRIVE_MODEL_RUN_STATE_CLOSED_LOOP_SENSORLESS = 6,
    DRIVE_MODEL_RUN_STATE_FAULT = 7
} DriveModelRunState;

/*
 * 模型控制模式号。
 * 外部请求接口允许 0..10；当前已实现 0..6，7..10 预留给未来公共模式。
 * 11..15 当前无效；16..31 只用于 MDSM 内部命令和诊断，禁止作为
 * controlModeRequest 输入。
 */
typedef enum {
    DRIVE_CONTROL_MODE_GATE_OFF = 0,
    DRIVE_CONTROL_MODE_VOLTAGE_ALPHA_BETA_OPEN_LOOP = 1,
    DRIVE_CONTROL_MODE_VOLTAGE_DQ_OPEN_LOOP = 2,
    DRIVE_CONTROL_MODE_CURRENT_DQ_OPEN_LOOP = 3,
    DRIVE_CONTROL_MODE_SENSORED_SPEED_LOOP = 4,
    DRIVE_CONTROL_MODE_TORQUE_CONTROL = 5,
    DRIVE_CONTROL_MODE_SENSORLESS_SPEED_LOOP = 6,
    DRIVE_CONTROL_MODE_IMPLEMENTED_MAX = DRIVE_CONTROL_MODE_SENSORLESS_SPEED_LOOP,
    DRIVE_CONTROL_MODE_PUBLIC_RESERVED_MIN = 7,
    DRIVE_CONTROL_MODE_PUBLIC_RESERVED_MAX = 10,
    DRIVE_CONTROL_MODE_PUBLIC_MAX = 10,
    DRIVE_CONTROL_MODE_RESERVED_START = 16,
    DRIVE_CONTROL_MODE_INTERNAL_MIN = 16,
    DRIVE_CONTROL_MODE_IF_STARTUP_INTERNAL = 16,
    DRIVE_CONTROL_MODE_SMO_CLOSED_LOOP_INTERNAL = 17,
    DRIVE_CONTROL_MODE_INTERNAL_MAX = 31
} DriveControlMode;

/* 角度/速度闭环使用的传感模式。 */
typedef enum {
    DRIVE_MODEL_SENSOR_MODE_NONE = 0,
    DRIVE_MODEL_SENSOR_MODE_SENSORED = 1,
    DRIVE_MODEL_SENSOR_MODE_SENSORLESS = 2,
    DRIVE_MODEL_SENSOR_MODE_BLENDED = 3
} DriveModelSensorMode;

/* 模型当前使用的电角度来源，便于 CAN 上报和故障分析。 */
typedef enum {
    DRIVE_MODEL_ANGLE_SRC_NONE = 0,
    DRIVE_MODEL_ANGLE_SRC_SENSOR = 1,
    DRIVE_MODEL_ANGLE_SRC_OBSERVER = 2,
    DRIVE_MODEL_ANGLE_SRC_OPEN_LOOP = 3
} DriveModelAngleSource;

/* 运行期故障统一编码；具体硬件项目可在 sourceMask 中进一步细分来源。 */
typedef enum {
    DRIVE_RUNTIME_FAULT_NONE = 0,
    DRIVE_RUNTIME_FAULT_HARDWARE = 1,
    DRIVE_RUNTIME_FAULT_CURRENT = 2,
    DRIVE_RUNTIME_FAULT_VOLTAGE = 3,
    DRIVE_RUNTIME_FAULT_TEMPERATURE = 4,
    DRIVE_RUNTIME_FAULT_SENSOR = 5,
    DRIVE_RUNTIME_FAULT_COMMUNICATION = 6,
    DRIVE_RUNTIME_FAULT_CALIBRATION = 7,
    DRIVE_RUNTIME_FAULT_MODEL = 8
} DriveRuntimeFaultCode;

typedef struct {
    DriveFloat ia;
    DriveFloat ib;
    DriveFloat ic;
    DriveFloat iDc;
    uint_least8_t valid;
} DriveCurrentFeedback;

/* 采样反馈统一用 valid 标志保护，模型只在 valid=1 时信任对应数据。 */
typedef struct {
    DriveFloat va;
    DriveFloat vb;
    DriveFloat vc;
    DriveFloat vDc;
    uint_least8_t valid;
} DriveVoltageFeedback;

typedef struct {
    DriveFloat moduleA;
    DriveFloat moduleB;
    DriveFloat moduleC;
    DriveFloat board;
    uint_least8_t valid;
} DriveTemperatureFeedback;

typedef struct {
    DriveFloat mechanicalAngleRad;
    DriveFloat electricalAngleRad;
    DriveFloat mechanicalSpeedRpm;
    DriveFloat electricalSpeedRadPerSec;
    uint_least8_t valid;
} DrivePositionFeedback;

typedef struct {
    DriveCurrentFeedback current;
    DriveVoltageFeedback voltage;
    DriveTemperatureFeedback temperature;
    DrivePositionFeedback position;
} DriveSensorFeedback;

typedef struct {
    uint_least8_t active;
    uint_least8_t latched;
    DriveRuntimeFaultCode code;
    uint32_t sourceMask;
} DriveFaultStatus;

typedef struct {
    DrivePwmMode mode;
    DriveFloat dutyA;
    DriveFloat dutyB;
    DriveFloat dutyC;
    uint_least8_t valid;
} DriveDutyCommand;

/*
 * 上层命令统一入口。
 * CAN、串口或本地调试命令都先转换成 DriveAppRequest，再交给状态机和模型。
 */
typedef struct {
    uint_least8_t enableRequest;
    uint_least8_t runRequest;
    uint_least8_t faultResetRequest;
    uint_least8_t calibrationRequest;
    DriveControlMode controlModeRequest;
    DriveFloat speedRefRpm;
    DriveFloat torqueRefNm;
    DriveFloat idRefA;
    DriveFloat iqRefA;
    uint32_t sequenceCounter;
    uint32_t ageTicks;
} DriveAppRequest;

typedef struct {
    uint_least8_t currentZeroActive;
    uint_least8_t currentZeroDone;
    uint_least8_t currentZeroFailed;
    uint32_t currentZeroSampleCount;
    DriveFloat iaOffset;
    DriveFloat ibOffset;
    DriveFloat icOffset;
    DriveFloat iDcOffset;
} DriveCalibrationStatus;

/* 状态机输出的硬件授权结果；模型和底层 PWM 都应以这里的允许位为准。 */
typedef struct {
    DriveSystemState state;
    DriveSystemState previousState;
    uint32_t transitionCount;
    uint32_t readyFeatures;
    uint32_t missingFeatures;
    uint_least8_t initComplete;
    uint_least8_t featuresReady;
    uint_least8_t faultActive;
    uint_least8_t faultLatched;
    uint_least8_t calibrationRequired;
    uint_least8_t calibrationAllowed;
    uint_least8_t gatePowerAllowed;
    uint_least8_t gateLogicAllowed;
    uint_least8_t pwmAllowed;
    uint_least8_t modelStepAllowed;
    uint_least8_t resetRequest;
} DriveSystemStatus;

typedef struct {
    DriveAppRequest request;
    DriveSensorFeedback feedback;
    DriveCalibrationStatus calibration;
    DriveSystemStatus system;
} DriveModelInput;

/* MATLAB/Simulink 模型输出；底层会再次检查状态机授权和 valid 位后才真正开 PWM。 */
typedef struct {
    DriveDutyCommand duty;
    DriveModelRunState runState;
    DriveControlMode controlMode;
    DriveModelSensorMode sensorMode;
    DriveModelAngleSource angleSource;
    DriveFloat electricalAngleRad;
    DriveFloat mechanicalSpeedRpm;
    uint_least8_t voltageOpenLoopActive;
    uint_least8_t currentLoopActive;
    uint_least8_t speedLoopActive;
    uint_least8_t valid;
    uint_least8_t requestStop;
} DriveModelOutput;

/* 最终下发给板级驱动的硬件命令，由框架根据状态机和模型输出合成。 */
typedef struct {
    DriveDutyCommand duty;
    uint_least8_t gatePowerEnable;
    uint_least8_t gateLogicEnable;
    uint_least8_t pwmEnable;
    uint_least8_t clearFaultRequest;
    uint_least8_t modelStepEnable;
} DriveHwCommand;

/* 低频诊断快照，用于 CAN 上报、调试窗口或运行日志。 */
typedef struct {
    uint32_t backgroundLoopCounter;
    uint32_t fastLoopCounter;
    DriveSystemState systemState;
    DriveModelRunState modelRunState;
    DriveControlMode controlMode;
    DriveRuntimeFaultCode faultCode;
    uint_least8_t pwmEnabled;
    uint_least8_t modelStepEnabled;
} DriveRuntimeDiagnostics;

#ifdef __cplusplus
}
#endif

#endif
