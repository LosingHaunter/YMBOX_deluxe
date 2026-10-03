(function (global, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else global.YMBOXPositionPll = factory();
})(typeof window === "object" ? window : globalThis, function () {
  "use strict";

  // Shared by the PI calculator and YMBOX configuration recommendations.
  // The model uses a critically damped position PLL: Kp = 2B, Ki = B².
  function recommend({polePairs, accelerationRads2, angleErrorDeg = 3, speedLagRads}) {
    for (const [value, label] of [[polePairs, "极对数"], [accelerationRads2, "机械加速度"], [angleErrorDeg, "允许电角度误差"]]) {
      if (!(Number.isFinite(value) && value > 0)) throw new Error(`PLL 推荐需要大于 0 的${label}`);
    }
    const angleErrorRad = angleErrorDeg * Math.PI / 180;
    const omegaByAngle = Math.sqrt(polePairs * accelerationRads2 / angleErrorRad);
    let omegaBySpeed = null;
    if (speedLagRads !== undefined && speedLagRads !== null) {
      if (!(Number.isFinite(speedLagRads) && speedLagRads > 0)) throw new Error("PLL 允许机械转速滞后须大于 0；留空表示不使用此约束");
      omegaBySpeed = 2 * accelerationRads2 / speedLagRads;
    }
    const bandwidthRads = Math.max(omegaByAngle, omegaBySpeed || 0);
    return {bandwidthRads, omegaByAngle, omegaBySpeed, accelerationRads2};
  }

  return Object.freeze({recommend});
});
