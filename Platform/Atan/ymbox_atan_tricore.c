#include "ymbox_atan_f32.h"
#include <math.h>

void YMBOX_Atan_Init(void)
{
    /* No initialization is needed by this reference integration adapter. */
}

float YMBOX_Atan_f32(float ratio)
{
    /* Replace or link the LUT backend when the board needs a faster path.
     * This adapter alone does not claim a TriCore hardware acceleration.
     */
    return atanf(ratio);
}

