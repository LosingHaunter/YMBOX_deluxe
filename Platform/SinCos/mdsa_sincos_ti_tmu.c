#include "mdsa_sincos_f32.h"

void MDSA_SinCos_Init(void)
{
    /* No peripheral initialization is required for the C28x TMU. */
}

void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta)
{
    /*
     * Build for F28379D with --float_support=fpu32 and
     * --tmu_support=tmu0.  The per-unit intrinsics consume one electrical
     * turn directly, so no radian conversion is required.
     */
    *cos_theta = __cospuf32(angle_pu);
    *sin_theta = __sinpuf32(angle_pu);
}
