#include "ymbox_atan_f32.h"
#include <math.h>

void YMBOX_Atan_Init(void)
{
    /* Portable reference backend has no peripheral state. */
}

float YMBOX_Atan_f32(float ratio)
{
    return atanf(ratio);
}

