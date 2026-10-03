#include "ymbox_sqrt_f32.h"

#if !defined(__ARM_FP) || ((__ARM_FP & 4) == 0)
#error "STM32_FPU Sqrt requires an Arm target with single-precision hardware FPU enabled"
#endif
#if !defined(__GNUC__) && !defined(__clang__)
#error "STM32_FPU Sqrt supports GNU-compatible Arm compilers; use GENERIC or a board adapter otherwise"
#endif

void YMBOX_Sqrt_Init(void)
{
    /* Board startup enables the FPU. Preserve its rounding/FZ/exception mode. */
}

float YMBOX_Sqrt_f32(float value)
{
    float root;
    /* Single hardware operation; no CORDIC registers or interrupt masking. */
    __asm__("vsqrt.f32 %0, %1" : "=t" (root) : "t" (value));
    return root;
}
