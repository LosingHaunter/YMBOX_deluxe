#include "mdsa_sincos_f32.h"

#include <stdint.h>

#ifndef MDSA_SINCOS_LUT_COUNTS
#define MDSA_SINCOS_LUT_COUNTS 4096
#endif
#if (MDSA_SINCOS_LUT_COUNTS != 4096) && (MDSA_SINCOS_LUT_COUNTS != 8192)
#error "MDSA_SINCOS_LUT_COUNTS must be 4096 or 8192"
#endif
#define MDSA_LUT_SEGMENTS (MDSA_SINCOS_LUT_COUNTS / 4U)

/*
 * N full-turn segments match the configured control-angle count domain.
 * Quarter-wave symmetry stores only N/4 + 1 single-precision values.
 * Linear interpolation also supports the continuous observer-angle path.
 * This data belongs to the bottom layer and is never published to Simulink.
 */
static const float MDSA_SinQuarter_f32[MDSA_LUT_SEGMENTS + 1U] = {
#if MDSA_SINCOS_LUT_COUNTS == 8192
#include "mdsa_sincos_quarter_8192.inc"
#else
#include "mdsa_sincos_quarter_4096.inc"
#endif
};

static float MDSA_WrapAnglePu(float angle_pu)
{
    int32_t whole_turns;

    if ((angle_pu >= 0.0F) && (angle_pu < 1.0F)) {
        return angle_pu;
    }

    whole_turns = (int32_t)angle_pu;
    angle_pu -= (float)whole_turns;
    if (angle_pu < 0.0F) {
        angle_pu += 1.0F;
    }
    if (angle_pu >= 1.0F) {
        angle_pu = 0.0F;
    }
    return angle_pu;
}

static float MDSA_QuarterSin(float quarter_pu)
{
    const float position = quarter_pu * (float)MDSA_LUT_SEGMENTS;
    const uint32_t index = (uint32_t)position;
    float fraction;

    if (index >= MDSA_LUT_SEGMENTS) {
        return MDSA_SinQuarter_f32[MDSA_LUT_SEGMENTS];
    }

    fraction = position - (float)index;
    return MDSA_SinQuarter_f32[index] +
        fraction * (MDSA_SinQuarter_f32[index + 1U] -
                    MDSA_SinQuarter_f32[index]);
}

void MDSA_SinCos_Init(void)
{
    /* Constant lookup data requires no runtime initialization. */
}

void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta)
{
    const float quadrant_position = MDSA_WrapAnglePu(angle_pu) * 4.0F;
    const uint32_t quadrant = (uint32_t)quadrant_position;
    const float fraction = quadrant_position - (float)quadrant;
    const float ascending = MDSA_QuarterSin(fraction);
    const float descending = MDSA_QuarterSin(1.0F - fraction);

    switch (quadrant & 3U) {
      case 0U:
        *cos_theta = descending;
        *sin_theta = ascending;
        break;
      case 1U:
        *cos_theta = -ascending;
        *sin_theta = descending;
        break;
      case 2U:
        *cos_theta = -descending;
        *sin_theta = -ascending;
        break;
      default:
        *cos_theta = ascending;
        *sin_theta = -descending;
        break;
    }
}
