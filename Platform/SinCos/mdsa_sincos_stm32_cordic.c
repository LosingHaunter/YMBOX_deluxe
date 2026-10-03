#include "mdsa_sincos_f32.h"

#include "../SharedMath/ymbox_stm32_cordic.h"

#define MDSA_Q31_TO_FLOAT (4.6566128730773925781E-10F)
#define MDSA_TURN_TO_Q31  (4294967296.0F)

void MDSA_SinCos_Init(void)
{
    /* The board startup code must enable the CORDIC peripheral clock. */
    const uint32_t previous_primask = YMBOX_CordicEnter();
    LL_CORDIC_Config(CORDIC,
                     LL_CORDIC_FUNCTION_COSINE,
                     LL_CORDIC_PRECISION_5CYCLES,
                     LL_CORDIC_SCALE_0,
                     LL_CORDIC_NBWRITE_2,
                     LL_CORDIC_NBREAD_2,
                     LL_CORDIC_INSIZE_32BITS,
                     LL_CORDIC_OUTSIZE_32BITS);
    YMBOX_CordicLeave(previous_primask);
}

void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta)
{
    const float signed_turn =
        (angle_pu >= 0.5F) ? (angle_pu - 1.0F) : angle_pu;
    const int32_t angle_q31 =
        (int32_t)(signed_turn * MDSA_TURN_TO_Q31);
    int32_t cos_q31;
    int32_t sin_q31;
    const uint32_t previous_primask = YMBOX_CordicEnter();

    /* Atan may have used PHASE since the previous call. Select the complete
     * COSINE transaction here instead of relying on startup configuration.
     */
    LL_CORDIC_Config(CORDIC,
                     LL_CORDIC_FUNCTION_COSINE,
                     LL_CORDIC_PRECISION_5CYCLES,
                     LL_CORDIC_SCALE_0,
                     LL_CORDIC_NBWRITE_2,
                     LL_CORDIC_NBREAD_2,
                     LL_CORDIC_INSIZE_32BITS,
                     LL_CORDIC_OUTSIZE_32BITS);
    LL_CORDIC_WriteData(CORDIC, (uint32_t)angle_q31);
    /* PHASE overwrites ARG2. Restore unit modulus on every cosine call. */
    LL_CORDIC_WriteData(CORDIC, (uint32_t)0x7FFFFFFF);
    cos_q31 = (int32_t)LL_CORDIC_ReadData(CORDIC);
    sin_q31 = (int32_t)LL_CORDIC_ReadData(CORDIC);
    YMBOX_CordicLeave(previous_primask);

    *cos_theta = (float)cos_q31 * MDSA_Q31_TO_FLOAT;
    *sin_theta = (float)sin_q31 * MDSA_Q31_TO_FLOAT;
}
