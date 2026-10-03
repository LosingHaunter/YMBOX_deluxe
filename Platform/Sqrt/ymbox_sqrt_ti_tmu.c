#include "ymbox_sqrt_f32.h"
#include <math.h>

void YMBOX_Sqrt_Init(void)
{
    /* TMU is an instruction-set extension. No peripheral initialization. */
}

float YMBOX_Sqrt_f32(float value)
{
    /* Keep domain/special-value handling independent of TMU approximation. */
    if (value < 0.0F) {
        return NAN;
    }
    if ((value == 0.0F) || (value != value) || (value == INFINITY)) {
        return value;
    }
    /* C2000: --float_support=fpu32 --tmu_support=tmu0 (or tmu1).
     * The documented intrinsic is __sqrt, generating SQRTF32.
     */
    return __sqrt(value);
}
