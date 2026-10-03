/* Copy this file into the board project and implement EVERY required function.
 * There is deliberately no success-returning empty driver or weak override.
 * Compile exactly one port implementation. See HARDWARE_PORT.md. */
#include "ymbox_port.h"

bool YMBOX_Port_Init(const YMBOX_BuildInfo *build, YMBOX_BoardInfo *actual)
{
    (void)build;
    (void)actual;
    /* TODO: keep outputs off, inspect timer/ADC/position setup, start zero
     * calibration, and return ACTUAL board capabilities and configuration. */
    return false;
}

bool YMBOX_Port_ReadFast(YMBOX_FastSample *sample)
{
    (void)sample;
    /* TODO: calibrated amperes/volts, native position counts, acquisition
     * timestamp/sequence, per-signal validity, live faults and calibration. */
    return false;
}

bool YMBOX_Port_ApplyOutput(const YMBOX_OutputCommand *output)
{
    (void)output;
    /* TODO: trip-aware PWM enable/disable; preload all U/V/W compares together.
     * Never clear fault latches or start an SPI transaction here. */
    return false;
}

void YMBOX_Port_Trip(void)
{
    /* TODO REQUIRED: immediately force PWM/gate off and latch the inhibition.
     * Must also be safe before Port_Init. Hardware trip routing is independent. */
}

bool YMBOX_Port_ClearTrip(void)
{
    /* TODO: require no live fault, clear latch but leave outputs disabled. */
    return false;
}

uint32_t YMBOX_Port_TimeUs(void)
{
    /* TODO: read a free-running hardware microsecond clock. */
    return 0U;
}

uint32_t YMBOX_Port_EnterCritical(void)
{
    /* TODO REQUIRED: save interrupt mask, mask runtime callers, memory barrier. */
    return 0U;
}

void YMBOX_Port_ExitCritical(uint32_t previousMask)
{
    (void)previousMask;
    /* TODO REQUIRED: memory barrier, restore previous mask (not always enable). */
}

void YMBOX_Port_Background(void)
{
    /* Optional: progress calibration and gate-driver/temperature diagnostics.
     * Publish the results coherently for ReadFast. */
}
