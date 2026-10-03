#ifndef YMBOX_TMU_DIV_INLINE_H_
#define YMBOX_TMU_DIV_INLINE_H_
#ifndef YMBOX_TMU_DIVISION
#define YMBOX_TMU_DIVISION 0
#endif

#if YMBOX_TMU_DIVISION
#include <stdint.h>
#if defined(__TI_COMPILER_VERSION__)
#pragma FUNC_ALWAYS_INLINE(YMBOX_tmuDivInline)
#endif
/* Code-generation operator mapping, not an out-of-line math service.
 * Keep --fp_mode=strict: only ordinary finite/normal divisions use DIVF32.
 * Zero, NaN/Inf, subnormal inputs and extreme exponent ratios need the
 * original strict arithmetic. Signed zero has an inexpensive exact path.
 */
static inline float YMBOX_tmuDivInline(float numerator, float denominator)
{
    union { float f; uint32_t u; } n, d, z;
    uint32_t na, da;
    int ne, de, delta;
    n.f = numerator;
    d.f = denominator;
    na = n.u & UINT32_C(0x7fffffff);
    da = d.u & UINT32_C(0x7fffffff);
    if (na == 0U && da != 0U && da <= UINT32_C(0x7f800000)) {
        z.u = (n.u ^ d.u) & UINT32_C(0x80000000);
        return z.f;
    }
    ne = (int)(na >> 23);
    de = (int)(da >> 23);
    delta = ne - de;
    if (ne > 0 && ne < 255 && de > 0 && de < 255 &&
        delta >= -125 && delta <= 126) {
        return __divf32(numerator, denominator);
    }
    return numerator / denominator;
}
#define YMBOX_DIV_F32(numerator, denominator) \
    YMBOX_tmuDivInline((numerator), (denominator))
#else
#define YMBOX_DIV_F32(numerator, denominator) ((numerator) / (denominator))
#endif
#endif
