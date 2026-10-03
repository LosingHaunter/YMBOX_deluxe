#ifndef YMBOX_STM32_CORDIC_H
#define YMBOX_STM32_CORDIC_H

#include <stdint.h>

/* Override the header in the board build when using another STM32 family.
 * Preserve the existing SinCos build's override for compatibility.
 */
#if defined(YMBOX_STM32_CORDIC_LL_HEADER)
#include YMBOX_STM32_CORDIC_LL_HEADER
#elif defined(MDSA_STM32_CORDIC_LL_HEADER)
#include MDSA_STM32_CORDIC_LL_HEADER
#elif defined(__has_include)
#if __has_include("stm32h7xx_ll_cordic.h")
#include "stm32h7xx_ll_cordic.h"
#elif __has_include("stm32g4xx_ll_cordic.h")
#include "stm32g4xx_ll_cordic.h"
#else
#error "Select a board with CORDIC and provide its STM32 LL CORDIC header"
#endif
#else
#include "stm32g4xx_ll_cordic.h"
#endif

/*
 * A complete configure/write/read transaction must not be interrupted by
 * another CORDIC user. Preserve the caller's PRIMASK, including nested calls
 * from an already-masked control ISR. All board CORDIC users must follow
 * this ownership protocol; these routines are not used by NMI/HardFault.
 */
static inline uint32_t YMBOX_CordicEnter(void)
{
    const uint32_t previous_primask = __get_PRIMASK();
    __disable_irq();
    __DMB();
    return previous_primask;
}

static inline void YMBOX_CordicLeave(uint32_t previous_primask)
{
    __DMB();
    __set_PRIMASK(previous_primask);
}

#endif

