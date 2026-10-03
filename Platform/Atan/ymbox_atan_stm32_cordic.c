#include "ymbox_atan_f32.h"
#include "../SharedMath/ymbox_stm32_cordic.h"
#include <math.h>

#define YMBOX_HALF_PI_F (1.57079632679489661923F)
#define YMBOX_PHASE_Q31_TO_RAD (1.46291807926715968105E-9F)
#define YMBOX_HALF_Q31 (1073741824.0F)

void YMBOX_Atan_Init(void)
{
    /* Board startup enables the CORDIC clock. Each call selects its mode. */
}

float YMBOX_Atan_f32(float ratio)
{
    float magnitude;
    float reduced;
    float angle;
    int32_t phase_q31;
    int32_t y_q31;
    uint32_t previous_primask;

    if ((ratio == 0.0F) || (ratio != ratio)) {
        return ratio;
    }
    magnitude = fabsf(ratio);
    if (magnitude == INFINITY) {
        return copysignf(YMBOX_HALF_PI_F, ratio);
    }
    reduced = (magnitude > 1.0F) ? (1.0F / magnitude) : magnitude;

    /* Vector (0.5, 0.5*reduced) has modulus <= sqrt(0.5) < 1.
     * Both components fit Q1.31; (1, ratio) would saturate the peripheral.
     */
    y_q31 = (int32_t)(reduced * YMBOX_HALF_Q31);
    previous_primask = YMBOX_CordicEnter();
    LL_CORDIC_Config(CORDIC,
                     LL_CORDIC_FUNCTION_PHASE,
                     LL_CORDIC_PRECISION_6CYCLES,
                     LL_CORDIC_SCALE_0,
                     LL_CORDIC_NBWRITE_2,
                     LL_CORDIC_NBREAD_1,
                     LL_CORDIC_INSIZE_32BITS,
                     LL_CORDIC_OUTSIZE_32BITS);
    LL_CORDIC_WriteData(CORDIC, (uint32_t)1073741824);
    LL_CORDIC_WriteData(CORDIC, (uint32_t)y_q31);
    phase_q31 = (int32_t)LL_CORDIC_ReadData(CORDIC);
    YMBOX_CordicLeave(previous_primask);

    angle = (float)phase_q31 * YMBOX_PHASE_Q31_TO_RAD;
    if (magnitude > 1.0F) {
        angle = YMBOX_HALF_PI_F - angle;
    }
    return copysignf(angle, ratio);
}
