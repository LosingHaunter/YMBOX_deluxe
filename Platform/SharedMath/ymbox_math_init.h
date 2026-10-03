#ifndef YMBOX_MATH_INIT_H
#define YMBOX_MATH_INIT_H
#ifdef __cplusplus
extern "C" {
#endif
/* Call after board peripheral clocks are ready, before the control IRQ. */
void YMBOX_Math_Init(void);
#ifdef __cplusplus
}
#endif
#endif
