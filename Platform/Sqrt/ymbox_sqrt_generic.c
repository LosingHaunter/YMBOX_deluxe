#include "ymbox_sqrt_f32.h"
#include <math.h>

void YMBOX_Sqrt_Init(void)
{
    /* Portable host/reference backend has no peripheral state. */
}

float YMBOX_Sqrt_f32(float value)
{
    return sqrtf(value);
}
