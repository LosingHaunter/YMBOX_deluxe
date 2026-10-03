/* Adapt IRQ names/acknowledgement order to the actual MCU. This example is
 * deliberately excluded from the library source list. Board_* are placeholders. */
#include "ymbox_runtime.h"

extern void Board_Init(void);
extern void Board_StartSampling(void);
extern void Board_AcknowledgeAdcIrq(void);
extern void Board_AcknowledgeBreakIrq(void);
extern uint16_t Board_ReadBreakCode(void);

int main(void)
{
    Board_Init(); /* hardware trip active; outputs off; all YMBOX callbacks stopped */
    if (!YMBOX_Init()) {
        for (;;) { /* report initialization failure; leave outputs off */ }
    }
    Board_StartSampling(); /* PWM-triggered ADC; does not enable bridge outputs */
    for (;;) {
        YMBOX_Background();
    }
}

void ADC_Control_IRQHandler(void)
{
    Board_AcknowledgeAdcIrq();
    YMBOX_FastISR();
}

void PWM_Break_IRQHandler(void)
{
    YMBOX_TripISR(Board_ReadBreakCode()); /* hardware must have already tripped */
    Board_AcknowledgeBreakIrq();
}

bool OnAcceptedCommand(uint16_t mode, float speed_rpm, bool enable)
{
    YMBOX_Command command = {0};
    command.mode = mode;
    command.speed_rpm = speed_rpm;
    command.enable = enable;
    return YMBOX_SetCommand(&command); /* never call just to repeat stale input */
}
