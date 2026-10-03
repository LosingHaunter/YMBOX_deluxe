#include "ymbox_model_adapter.h"
#include "YMBOX_Deluxe_code.h"
#include "ymbox_build_info.h"

const YMBOX_BuildInfo *YMBOX_Model_BuildInfo(void)
{
    return &YMBOX_BUILD_INFO;
}

void YMBOX_Model_Initialize(void)
{
    ymbox_deluxe_initialize();
}

void YMBOX_Model_Step(const YMBOX_ModelInput *in, YMBOX_ModelOutput *out)
{
    const YMBOX_HardwareOutputBus *hw;
    VMIN_Dir_UCurSenrCurDet_A = in->sample.phaseCurrent_A[0];
    VMIN_Dir_VCurSenrCurDet_A = in->sample.phaseCurrent_A[1];
    VMIN_Dir_WCurSenrCurDet_A = in->sample.phaseCurrent_A[2];
    VMIN_Dir_DCBusVolt_V = in->sample.dcVoltage_V;
    VMIN_Dir_DCBusCur_A = in->sample.dcCurrent_A;
    VMIN_Dir_ResolverPosition_NULL = in->sample.positionCount;
    VMIN_Dir_UCurSenrCurErr_NULL = (in->sample.validMask & YMBOX_VALID_IU) == 0U;
    VMIN_Dir_VCurSenrCurErr_NULL = (in->sample.validMask & YMBOX_VALID_IV) == 0U;
    VMIN_Dir_WCurSenrCurErr_NULL = (in->sample.validMask & YMBOX_VALID_IW) == 0U;
    VMIN_Dir_HwFaultActive_flg = in->sample.hwFaultActive || in->runtimeFaultActive;
    VMIN_Dir_HwFaultCode_enum = in->sample.hwFaultActive ? in->sample.hwFaultCode :
        (in->runtimeFaultActive ? YMBOX_RUNTIME_HW_CODE : 0U);
    VMIN_Dir_PlatformFaultMask_u32 = in->sample.platformFaultMask;
    VMIN_Dir_PlatformWarningMask_u32 = in->sample.platformWarningMask;
    VMIN_Dir_PlatformTorqueLimitFactor_NULL = in->sample.torqueLimitFactor;
    VMIN_ECAN_MCUEnb_flg = in->enable;
    VMIN_ECAN_MotWrkMd_enum = in->command.mode;
    VMIN_ECAN_MotTrgtSpd_rpm = in->command.speed_rpm;
    VMIN_ECAN_MotTrgtTq_Nm = in->command.torque_Nm;
    VMIN_Dir_TestUaUdId_NULL = in->command.testD;
    VMIN_Dir_TestUbUqIq_NULL = in->command.testQ;
    VMIN_ECAN_CommandAliveCounter_u16 = in->commandAlive;
    VMIN_ECAN_ClearFaultRequest_flg = in->clearFault;
    VMIN_ECAN_FaultHistoryReadIndex_u8 = 0U;
    ymbox_deluxe_step();
    hw = &rtY.HardwareOutput;
    out->dutyU = hw->dutyU;
    out->dutyV = hw->dutyV;
    out->dutyW = hw->dutyW;
    out->mode = hw->mode;
    out->stopRequest = hw->stopRequest;
    out->pwmDisableRequest = hw->pwmDisableRequest;
    out->faultLatched = hw->faultLatched;
    out->faultCode = hw->faultCode;
    out->clearReady = hw->clearReady;
    out->rawFaultMask = hw->rawFaultMask;
    out->latchedFaultMask = hw->latchedFaultMask;
    out->warningActive = hw->warningActive;
    out->faultAction = hw->faultAction;
    out->torqueLimitFactor = hw->torqueLimitFactor;
    out->id_A = hw->id_A;
    out->iq_A = hw->iq_A;
    out->dcVoltage_V = hw->vdc_V;
}
