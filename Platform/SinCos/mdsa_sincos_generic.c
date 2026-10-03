#include "mdsa_sincos_f32.h"

#include <math.h>

#define MDSA_TWO_PI_F (6.2831853071795864769F)

void MDSA_SinCos_Init(void)
{
    /* No target peripheral is required by the portable implementation. */
}

void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta)
{
    const float theta_rad = angle_pu * MDSA_TWO_PI_F;

    *cos_theta = cosf(theta_rad);
    *sin_theta = sinf(theta_rad);
}
