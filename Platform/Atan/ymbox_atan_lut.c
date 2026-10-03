#include "ymbox_atan_f32.h"
#include <math.h>
#include <stdint.h>

#define YMBOX_ATAN_SEGMENTS (64U)
#define YMBOX_HALF_PI_F (1.57079632679489661923F)

/* atan(i/64), i=0..64. Table data occupies 65 * sizeof(float).
 * Linear interpolation; odd symmetry and reciprocal range reduction.
 */
static const float YMBOX_AtanTable[YMBOX_ATAN_SEGMENTS + 1U] = {
    0.000000000F,
    0.01562372862F,
    0.03123983343F,
    0.04684071292F,
    0.06241881000F,
    0.07796663383F,
    0.09347678116F,
    0.1089419570F,
    0.1243549945F,
    0.1397088743F,
    0.1549967419F,
    0.1702119253F,
    0.1853479500F,
    0.2003985538F,
    0.2153576997F,
    0.2302195873F,
    0.2449786631F,
    0.2596296294F,
    0.2741674511F,
    0.2885873619F,
    0.3028848684F,
    0.3170557532F,
    0.3310960767F,
    0.3450021772F,
    0.3587706703F,
    0.3723984467F,
    0.3858826694F,
    0.3992207696F,
    0.4124104416F,
    0.4254496374F,
    0.4383365599F,
    0.4510696560F,
    0.4636476090F,
    0.4760693303F,
    0.4883339511F,
    0.5004408131F,
    0.5123894603F,
    0.5241796288F,
    0.5358112380F,
    0.5472843810F,
    0.5585993153F,
    0.5697564535F,
    0.5807563536F,
    0.5915997103F,
    0.6022873461F,
    0.6128202022F,
    0.6231993299F,
    0.6334258830F,
    0.6435011088F,
    0.6534263412F,
    0.6632029927F,
    0.6728325476F,
    0.6823165549F,
    0.6916566219F,
    0.7008544079F,
    0.7099116185F,
    0.7188299996F,
    0.7276113326F,
    0.7362574290F,
    0.7447701257F,
    0.7531512810F,
    0.7614027698F,
    0.7695264804F,
    0.7775243104F,
    0.7853981634F
};

void YMBOX_Atan_Init(void)
{
    /* Constant table requires no runtime initialization. */
}

float YMBOX_Atan_f32(float ratio)
{
    float magnitude;
    float reduced;
    float position;
    float fraction;
    float angle;
    uint32_t index;

    if ((ratio == 0.0F) || (ratio != ratio)) {
        return ratio;
    }
    magnitude = fabsf(ratio);
    reduced = (magnitude > 1.0F) ? (1.0F / magnitude) : magnitude;
    position = reduced * (float)YMBOX_ATAN_SEGMENTS;
    index = (uint32_t)position;
    if (index >= YMBOX_ATAN_SEGMENTS) {
        angle = YMBOX_AtanTable[YMBOX_ATAN_SEGMENTS];
    } else {
        fraction = position - (float)index;
        angle = YMBOX_AtanTable[index] +
            fraction * (YMBOX_AtanTable[index + 1U] - YMBOX_AtanTable[index]);
    }
    if (magnitude > 1.0F) {
        angle = YMBOX_HALF_PI_F - angle;
    }
    return copysignf(angle, ratio);
}

