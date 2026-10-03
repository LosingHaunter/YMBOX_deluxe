#ifndef YMBOX_TYPES_H_
#define YMBOX_TYPES_H_

#include <stdbool.h>
#include <stdint.h>
#include "drive_rte.h"

#define YMBOX_PORT_ABI_VERSION 1U
#define YMBOX_VALID_IU       (1U << 0)
#define YMBOX_VALID_IV       (1U << 1)
#define YMBOX_VALID_IW       (1U << 2)
#define YMBOX_VALID_VDC      (1U << 3)
#define YMBOX_VALID_IDC      (1U << 4)
#define YMBOX_VALID_POSITION (1U << 5)
#define YMBOX_VALID_CURRENTS (YMBOX_VALID_IU | YMBOX_VALID_IV | YMBOX_VALID_IW)
#define YMBOX_MODE_BIT(mode) (UINT32_C(1) << (mode))

#define YMBOX_FAULT_SAMPLE       (UINT32_C(1) << 0)
#define YMBOX_FAULT_SAMPLE_AGE   (UINT32_C(1) << 1)
#define YMBOX_FAULT_COMMAND_AGE  (UINT32_C(1) << 2)
#define YMBOX_FAULT_HARDWARE     (UINT32_C(1) << 3)
#define YMBOX_FAULT_READINESS    (UINT32_C(1) << 4)
#define YMBOX_FAULT_OUTPUT       (UINT32_C(1) << 5)
#define YMBOX_FAULT_DEADLINE     (UINT32_C(1) << 6)
#define YMBOX_FAULT_REENTRANT    (UINT32_C(1) << 7)
#define YMBOX_FAULT_EXTERNAL_TRIP (UINT32_C(1) << 8)
#define YMBOX_RUNTIME_HW_CODE UINT16_C(0xF001)

/* Generated from the same calculator configuration as the model code.
 * This is an in-process C interface, not a packed CAN or binary file format.
 * uint_least8_t/boolean are intentionally usable on 16-bit-char C2000. */
typedef struct {
    uint32_t abiVersion;
    uint32_t controlPeriod_us;
    uint32_t mdtmDivider;
    uint32_t commandTimeout_us;
    uint32_t sampleMaxAge_us;
    uint32_t positionCountsPerRev;
    uint32_t supportedModes;
    uint32_t positionRequiredModes;
    uint32_t requiredFeatures;
    float pwmFrequency_Hz;
    float deadTime_s;
    float minDuty;
    float maxDuty;
    float timingTolerance_ppm;
    bool physicalDcCurrentRequired;
    const char *configurationSha256;
    const char *hardwareDeviceType;
} YMBOX_BuildInfo;

/* Report actual configured peripheral values, not a copy of buildInfo.
 * A stricter board duty limit requires a matching calculator export. */
typedef struct {
    uint32_t abiVersion;
    uint32_t controlPeriod_us;
    uint32_t positionCountsPerRev;
    uint32_t supportedModes;
    uint32_t features;
    float pwmFrequency_Hz;
    float deadTime_s;
    float minDuty;
    float maxDuty;
} YMBOX_BoardInfo;

typedef struct {
    float phaseCurrent_A[3];       /* calibrated, positive into U/V/W */
    float dcVoltage_V;             /* physical unfiltered voltage */
    float dcCurrent_A;             /* positive from DC source into inverter */
    uint32_t positionCount;        /* native mechanical counts, [0, CPR) */
    uint32_t sequence;             /* new ADC frame, modulo 2^32 */
    uint32_t sampleTime_us;        /* acquisition time, same clock as TimeUs */
    uint32_t readyFeatures;
    uint32_t platformFaultMask;
    uint32_t platformWarningMask;
    uint16_t validMask;
    uint16_t hwFaultCode;
    float torqueLimitFactor;       /* [0,1], 1 when not derating */
    bool hwFaultActive;            /* live cause, not a stale trip latch */
    bool currentZeroDone;
    bool currentZeroFailed;
} YMBOX_FastSample;

typedef struct {
    uint16_t mode;                 /* public 0..6 only */
    float speed_rpm;
    float torque_Nm;
    float testD;                   /* mode 1/2: V; mode 3: A */
    float testQ;                   /* mode 1/2: V; mode 3: A */
    bool enable;
    bool clearFault;               /* accepted only with enable=false */
} YMBOX_Command;

typedef struct {
    float dutyU;
    float dutyV;
    float dutyW;
    bool pwmEnable;
    bool gatePowerEnable;
    bool gateLogicEnable;
} YMBOX_OutputCommand;

/* Private generated-code bridge types; board code never needs rtwtypes.h. */
typedef struct {
    YMBOX_FastSample sample;
    YMBOX_Command command;
    uint16_t commandAlive;
    bool enable;
    bool clearFault;
    bool runtimeFaultActive;
} YMBOX_ModelInput;

typedef struct {
    float dutyU;
    float dutyV;
    float dutyW;
    float id_A;
    float iq_A;
    float dcVoltage_V;
    float torqueLimitFactor;
    uint32_t rawFaultMask;
    uint32_t latchedFaultMask;
    uint16_t mode;
    uint16_t faultCode;
    uint_least8_t faultAction;
    bool stopRequest;
    bool pwmDisableRequest;
    bool faultLatched;
    bool clearReady;
    bool warningActive;
} YMBOX_ModelOutput;

typedef struct {
    YMBOX_ModelOutput model;
    YMBOX_OutputCommand applied;
    DriveSystemState state;
    uint32_t runtimeFaults;
    uint32_t fastCalls;
    uint32_t modelSteps;
    uint32_t backgroundCalls;
    uint32_t acceptedCommands;
    uint32_t rejectedCommands;
    uint32_t commandAge_us;
    uint32_t sampleAge_us;
    uint32_t lastExecution_us;
    uint32_t maxExecution_us;
    uint16_t tripCode;
    bool initialized;
    bool modelStarted;
    bool tripLatched;
} YMBOX_Status;

#endif
