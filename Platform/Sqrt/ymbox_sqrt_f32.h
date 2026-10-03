#ifndef YMBOX_SQRT_F32_H
#define YMBOX_SQRT_F32_H

#ifdef __cplusplus
extern "C" {
#endif

/* Link exactly one backend. Board startup owns initialization. */
void YMBOX_Sqrt_Init(void);

/*
 * Real single-precision square root. The EMF caller supplies a nonnegative
 * sum of squares, in V^2, and receives magnitude in V.
 * Preserve signed zero and +Inf; propagate NaN; negative inputs yield NaN.
 * errno and floating-point exception flags are not part of this API.
 * Rounding and subnormal handling follow the target floating-point mode.
 */
float YMBOX_Sqrt_f32(float value);

#ifdef __cplusplus
}
#endif
#endif
