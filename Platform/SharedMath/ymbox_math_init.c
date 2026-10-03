#include "ymbox_math_init.h"
#include "../SinCos/mdsa_sincos_f32.h"
#include "../Atan/ymbox_atan_f32.h"
#include "../Sqrt/ymbox_sqrt_f32.h"

void YMBOX_Math_Init(void)
{
    MDSA_SinCos_Init();
    YMBOX_Atan_Init();
    YMBOX_Sqrt_Init();
}
