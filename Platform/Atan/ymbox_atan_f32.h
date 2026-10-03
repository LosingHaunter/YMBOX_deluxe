#ifndef YMBOX_ATAN_F32_H
#define YMBOX_ATAN_F32_H

#ifdef __cplusplus
extern "C" {
#endif

/* Board startup owns initialization and links exactly one implementation. */
void YMBOX_Atan_Init(void);

/*
 * Principal arctangent of a dimensionless ratio, returned in radians.
 * Domain: all float values. Preserve signed zero; propagate NaN; map
 * infinities to signed pi/2. LUT implementations use range reduction
 * outside [-1, 1], so motor-profile changes cannot index past the table.
 */
float YMBOX_Atan_f32(float ratio);

#ifdef __cplusplus
}
#endif

#endif

