#ifndef YMBOX_RUNTIME_H_
#define YMBOX_RUNTIME_H_

#include "ymbox_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* One motor instance. Call once before starting the control IRQ. For reinit,
 * first stop all runtime callers and the control IRQ, then restart from off. */
bool YMBOX_Init(void);
void YMBOX_FastISR(void);          /* once per completed control-period sample */
void YMBOX_TripISR(uint16_t code); /* latch shutdown; does not run the model */
void YMBOX_Background(void);

/* Call only on a real accepted command/event. Same values are allowed as a
 * heartbeat; success advances the model alive counter exactly once. Invalid
 * commands return false and do not refresh the last accepted command age. */
bool YMBOX_SetCommand(const YMBOX_Command *command);
bool YMBOX_GetStatus(YMBOX_Status *status); /* coherent copy, no borrowed pointer */
const YMBOX_BuildInfo *YMBOX_GetBuildInfo(void);

#ifdef __cplusplus
}
#endif
#endif
