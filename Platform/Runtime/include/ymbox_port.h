#ifndef YMBOX_PORT_H_
#define YMBOX_PORT_H_

#include "ymbox_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Board startup must configure clocks, peripherals and hardware trip routing
 * before YMBOX_Init. All software callers (including control/trip IRQ callbacks)
 * must stay quiescent throughout Init; hardware trip routing remains active.
 * Init may start calibration; it MUST leave PWM off and control IRQ disabled. */
bool YMBOX_Port_Init(const YMBOX_BuildInfo *build, YMBOX_BoardInfo *actual);

/* Bounded, nonblocking read of one completed, coherent ADC/position frame.
 * Never trigger-and-wait for conversion here. DMA/cache ownership is board work.
 * Temperature/gate-driver/background data must also be coherently snapshotted. */
bool YMBOX_Port_ReadFast(YMBOX_FastSample *sample);

/* Called inside a short critical section. Write all phases through preload
 * registers and latch together at the declared PWM update point. pwmEnable=false
 * means physical output disable, independent of duty. Return false on failure.
 * A hardware/software trip MUST override enable, including an intervening NMI.
 * This function MUST NOT clear a trip latch. No SPI waits, locks, or allocation. */
bool YMBOX_Port_ApplyOutput(const YMBOX_OutputCommand *output);

/* Idempotent, immediate output disable plus latch. Safe before Port_Init and
 * from the control/fault IRQ. Hardware protection must work without this call. */
void YMBOX_Port_Trip(void);

/* Nonblocking attempt to clear the latch after the live cause disappears.
 * Success MUST leave PWM/gate output disabled. Never auto-rearm hardware. */
bool YMBOX_Port_ClearTrip(void);

/* Free-running 1-us-resolution clock, wraps modulo 2^32, not an ISR counter.
 * No interval used by this API may reach 2^31 us. Must work in critical sections. */
uint32_t YMBOX_Port_TimeUs(void);

/* Save/restore the prior interrupt mask, plus compiler/memory ordering barriers.
 * Protect shared state against the command producer, fast IRQ and trip IRQ.
 * Nested use is required. NMI/multicore access to runtime APIs is unsupported;
 * NMI hardware shutdown must still override ApplyOutput at the peripheral. */
uint32_t YMBOX_Port_EnterCritical(void);
void YMBOX_Port_ExitCritical(uint32_t previousMask);

/* Optional background work. Publish only coherent board snapshots; never call
 * generated code or modify PWM permissions here. No model scheduling here. */
void YMBOX_Port_Background(void);

#ifdef __cplusplus
}
#endif
#endif
