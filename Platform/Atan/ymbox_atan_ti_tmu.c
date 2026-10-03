#include "ymbox_atan_f32.h"
#include "../SharedMath/ymbox_tmu_div_inline.h"
#include <math.h>

#define YMBOX_HALF_PI_F (1.57079632679489661923F)

void YMBOX_Atan_Init(void)
{
    /* TMU is an instruction-set extension, not a configured peripheral. */
}

float YMBOX_Atan_f32(float ratio)
{
    float magnitude;
    float reduced;
    float angle;

    if ((ratio == 0.0F) || (ratio != ratio)) {
        return ratio;
    }
    magnitude = fabsf(ratio);
    if (magnitude == INFINITY) {
        return copysignf(YMBOX_HALF_PI_F, ratio);
    }
    reduced = (magnitude > 1.0F) ? YMBOX_DIV_F32(1.0F, magnitude) : magnitude;
    /* C2000: --float_support=fpu32 --tmu_support=tmu0.
     * __atan returns radians. Range reduction also bounds the TMU input.
     */
    angle = __atan(reduced);
    if (magnitude > 1.0F) {
        angle = YMBOX_HALF_PI_F - angle;
    }
    return copysignf(angle, ratio);
}
