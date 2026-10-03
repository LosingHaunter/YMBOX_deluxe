function [routeSupported, stage1Mode, stage1Ready, stage1SwitchSpd, ...
    stage1AcquireCnt, stage2Enable, stage2Mode, stage2Ready, ...
    stage2SwitchSpd, stage2Fallback] = YMBOX_SmoProductRouteConfig( ...
    modeReq, smoReady, ifSwitchSpdRpm, smoSwitchSpdRpm, ...
    observerLossConfirmCnt, directHandoverCnt)
%YMBOX_SMOPRODUCTROUTECONFIG Configure the product mode-6 SMO route.
%#codegen

modeOff = uint16(0);
modeSensorlessRequest = uint16(6);
modeSmoClosedLoop = uint16(17);
routeSupported = false;
stage1Mode = modeOff;
stage1Ready = false;
stage1SwitchSpd = single(ifSwitchSpdRpm);
stage1AcquireCnt = uint32(observerLossConfirmCnt);
stage2Enable = false;
stage2Mode = modeOff;
stage2Ready = false;
stage2SwitchSpd = single(ifSwitchSpdRpm);
stage2Fallback = false;

if uint16(modeReq) == modeSensorlessRequest
    routeSupported = true;
    stage1Mode = modeSmoClosedLoop;
    stage1Ready = (smoReady ~= 0);
    stage1SwitchSpd = single(smoSwitchSpdRpm);
    stage1AcquireCnt = uint32(directHandoverCnt);
end
end
