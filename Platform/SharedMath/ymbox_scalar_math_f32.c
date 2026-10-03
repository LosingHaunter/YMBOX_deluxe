#include "ymbox_scalar_math_f32.h"
#include "ymbox_tmu_div_inline.h"
#include "../Sqrt/ymbox_sqrt_f32.h"
#include <math.h>

float YMBOX_Hypot_f32(float x, float y)
{
    /* Preserve the generated model's scaled hypot algorithm, including its
     * NaN/Inf precedence, and avoid replacing it with sqrt(x*x+y*y).
     */
    float a = fabsf(x);
    float b = fabsf(y);
    float ratio;
    if (a < b) {
        ratio = YMBOX_DIV_F32(a, b);
        return YMBOX_Sqrt_f32(ratio * ratio + 1.0F) * b;
    }
    if (a > b) {
        ratio = YMBOX_DIV_F32(b, a);
        return YMBOX_Sqrt_f32(ratio * ratio + 1.0F) * a;
    }
    if (isnan(b)) {
        return NAN;
    }
    return a * 1.41421354F;
}
