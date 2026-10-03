function [ifMechSpd, ifMechSpdAbs, ifElecAngleRad, smoMechSpd, ...
    smoMechSpdAbs, smoReady, smoAlignedElecAngleRad, ...
    handoverBlendOut, handoverElecAngleDeltaOut] = ...
    YMBOX_SmoProductModeCore( ...
    modeCmd, modeReq, targetSpdRpm, smoElecSpd, smoAngle, smoEmfMag, ...
    smoPllErr, Ts, polePairsIn, accelRpmps, accelBlendTime, alignTime, ...
    ifBlendTime, smoSwitchSpdRpm, smoReadySpdErr, smoReadyPllErr, ...
    smoReadyConfirmCnt, smoMinEmf, directHandoverTime, observerExitRatio)
%YMBOX_SMOPRODUCTMODECORE Execute mode-6 I/F startup and SMO handover.
%#codegen

modeOff = uint16(0);
modeSensorlessRequest = uint16(6);
modeIfStartup = uint16(16);
modeSmoClosedLoop = uint16(17);
persistent ifElecSpd ifAngle smoReadyCnt;
persistent alignElapsed runElapsed prevMode prevReq;
persistent observerBlendElapsed observerSourceAngle observerSourceSpd;
persistent handoverBlend handoverDelta;

if isempty(ifElecSpd)
    ifElecSpd = single(0);
    ifAngle = single(0);
    smoReadyCnt = uint16(0);
    alignElapsed = single(0);
    runElapsed = single(0);
    prevMode = modeOff;
    prevReq = modeOff;
    observerBlendElapsed = single(0);
    observerSourceAngle = single(0);
    observerSourceSpd = single(0);
    handoverBlend = single(1);
    handoverDelta = single(0);
end

p = max(single(1), single(polePairsIn));
ts = max(single(1e-7), single(Ts));
twoPi = single(6.2831853);
modeNow = uint16(modeCmd);
req = uint16(modeReq);
exitRatio = min(single(0.95), ...
    max(single(0.10), single(observerExitRatio)));

if req ~= prevReq
    smoReadyCnt = uint16(0);
    observerBlendElapsed = single(0);
    handoverBlend = single(1);
    handoverDelta = single(0);
end

smoRpm = abs(single(smoElecSpd))/p*single(60)/twoPi;
smoFinite = isfinite(single(smoAngle)) && ...
    isfinite(single(smoElecSpd)) && isfinite(single(smoEmfMag)) && ...
    isfinite(single(smoPllErr));
smoHealth = smoFinite && (single(smoEmfMag) >= single(smoMinEmf)) && ...
    (abs(single(smoPllErr)) <= max(single(0.10), ...
    single(2)*single(smoReadyPllErr))) && ...
    (smoRpm >= max(single(50), ...
    exitRatio*single(smoSwitchSpdRpm)));

enteringIf = (modeNow == modeIfStartup) && ...
    (prevMode == modeSmoClosedLoop);
if enteringIf
    % Continue from the last applied blended angle/speed. The raw observer
    % angle can still differ substantially while handover is in progress.
    smoReadyCnt = uint16(0);
    alignElapsed = max(single(0), single(alignTime)) + ...
        max(single(0), single(ifBlendTime));
    runElapsed = max(ts, single(accelBlendTime));
end

if modeNow == modeIfStartup
    handoverBlend = single(0);
    handoverDelta = wrapDelta(ifAngle - single(smoAngle));
    if alignElapsed < max(single(0), single(alignTime)) + ...
            max(single(0), single(ifBlendTime))
        alignElapsed = alignElapsed + ts;
        ifElecSpd = single(0);
        ifAngle = single(0);
        runElapsed = single(0);
        smoReadyCnt = uint16(0);
    else
        runElapsed = runElapsed + ts;
        accelDuration = max(ts, single(accelBlendTime));
        accelBlend = smoothstep01(runElapsed/accelDuration);
        targetForIfRpm = single(targetSpdRpm);
        directLimitRpm = abs(targetForIfRpm);
        if req == modeSensorlessRequest
            directLimitRpm = min(directLimitRpm, ...
                single(smoSwitchSpdRpm) + single(50));
        end
        if targetForIfRpm < single(0)
            targetForIfRpm = -directLimitRpm;
        elseif req == modeSensorlessRequest
            targetForIfRpm = directLimitRpm;
        end
        targetElecSpd = targetForIfRpm*twoPi/single(60)*p;
        maxStep = abs(single(accelRpmps))*accelBlend*twoPi/ ...
            single(60)*p*ts;
        delta = targetElecSpd - ifElecSpd;
        if delta > maxStep
            delta = maxStep;
        elseif delta < -maxStep
            delta = -maxStep;
        end
        ifElecSpd = ifElecSpd + delta;
        ifAngle = wrapAngle(ifAngle + ifElecSpd*ts, twoPi);
        refRpm = abs(ifElecSpd)/p*single(60)/twoPi;

        smoCond = (refRpm >= single(smoSwitchSpdRpm)) && smoFinite && ...
            (single(smoEmfMag) >= single(smoMinEmf)) && ...
            (abs(single(smoPllErr)) <= single(smoReadyPllErr)) && ...
            (abs(single(smoElecSpd) - ifElecSpd) <= ...
            single(smoReadySpdErr));
        smoReadyCnt = qualifiedCount(smoReadyCnt, smoCond);
    end
    handoverBlend = single(0);
    handoverDelta = wrapDelta(ifAngle - single(smoAngle));
    observerBlendElapsed = single(0);
    observerSourceAngle = ifAngle;
    observerSourceSpd = ifElecSpd;
elseif modeNow == modeSmoClosedLoop
    [ifAngle, ifElecSpd, observerBlendElapsed, observerSourceAngle, ...
        observerSourceSpd, handoverBlend, handoverDelta] = ...
        blendObserver(prevMode, observerBlendElapsed, ...
        observerSourceAngle, observerSourceSpd, ifAngle, ifElecSpd, ...
        single(smoAngle), single(smoElecSpd), ...
        single(directHandoverTime), ts, twoPi, handoverDelta);
    smoReadyCnt = uint16(0);
    alignElapsed = single(0);
    runElapsed = single(0);
else
    ifElecSpd = single(0);
    ifAngle = single(0);
    smoReadyCnt = uint16(0);
    alignElapsed = single(0);
    runElapsed = single(0);
    observerBlendElapsed = single(0);
    observerSourceAngle = single(0);
    observerSourceSpd = single(0);
    handoverBlend = single(1);
    handoverDelta = single(0);
end

if modeNow == modeIfStartup
    % The forced I/F frame is not a rotor-angle estimate. At light load,
    % Iq aligns the rotor near +/- pi/2 from that frame; a small observer
    % error may put the raw frame difference on either side of pi/2.
    % Qualify observer lock using the consecutive EMF/PLL/speed checks
    % above. Keep the actual frame difference for bumpless handover only.
    smoReady = (req == modeSensorlessRequest) && ...
        (smoReadyCnt >= max(uint16(1), uint16(smoReadyConfirmCnt)));
elseif modeNow == modeSmoClosedLoop
    smoReady = (req == modeSensorlessRequest) && smoHealth;
else
    smoReady = false;
end

ifMechSpd = single(ifElecSpd/p);
ifMechSpdAbs = single(abs(ifElecSpd/p));
ifElecAngleRad = ifAngle;

if modeNow == modeSmoClosedLoop
    smoControlAngle = ifAngle;
    smoControlSpd = ifElecSpd;
else
    smoControlAngle = wrapAngle(single(smoAngle), twoPi);
    smoControlSpd = single(smoElecSpd);
end
smoMechSpd = single(smoControlSpd/p);
smoMechSpdAbs = single(abs(smoControlSpd/p));
smoAlignedElecAngleRad = smoControlAngle;
handoverBlendOut = single(handoverBlend);
handoverElecAngleDeltaOut = single(handoverDelta);

prevMode = modeNow;
prevReq = req;
end

function cnt = qualifiedCount(cnt, condition)
if condition
    if cnt < uint16(65535)
        cnt = cnt + uint16(1);
    end
else
    cnt = uint16(0);
end
end

function value = wrapDelta(value)
% Inputs are differences of angles normalized to [0, 2*pi), so one
% comparison and one add/subtract wrap the result to [-pi, pi].
value = single(value);
piRad = single(3.141592653589793);
twoPiRad = single(6.283185307179586);
if value > piRad
    value = value - twoPiRad;
elseif value < -piRad
    value = value + twoPiRad;
end
end

function value = smoothstep01(value)
value = single(value);
value = min(single(1), max(single(0), value));
value = value*value*(single(3) - single(2)*value);
end

function angle = wrapAngle(angle, twoPi)
% Normal control inputs need at most one add/subtract. Retain the full-range
% fallback for large values and the original NaN/Inf behavior.
if angle >= single(0) && angle < twoPi
    return;
elseif angle >= twoPi && angle < single(2)*twoPi
    angle = angle - twoPi;
elseif angle < single(0) && angle >= -twoPi
    angle = angle + twoPi;
    if angle >= twoPi
        angle = single(0);
    end
else
    angle = mod(angle, twoPi);
end
end

function [angleOut, speedOut, elapsed, sourceAngle, sourceSpd, ...
    weight, deltaOut] = blendObserver(prevMode, elapsed, sourceAngle, ...
    sourceSpd, ifAngle, ifSpd, targetAngle, targetSpd, directBlendTime, ...
    ts, twoPi, deltaPrev)
modeSmoClosedLoop = uint16(17);
if prevMode ~= modeSmoClosedLoop
    elapsed = single(0);
    % Advance the previous control angle to this tick before blending.
    sourceAngle = wrapAngle(ifAngle + ifSpd*ts, twoPi);
    sourceSpd = ifSpd;
    deltaOut = wrapDelta(sourceAngle - targetAngle);
else
    elapsed = elapsed + ts;
    deltaOut = deltaPrev;
end
weight = smoothstep01(elapsed/max(single(1e-7), directBlendTime));
angleOut = wrapAngle(targetAngle + (single(1) - weight)*single(deltaOut), twoPi);
speedOut = sourceSpd + weight*(targetSpd - sourceSpd);
end
