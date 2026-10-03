#ifndef YMBOX_MODEL_ADAPTER_H_
#define YMBOX_MODEL_ADAPTER_H_

#include "ymbox_types.h"

const YMBOX_BuildInfo *YMBOX_Model_BuildInfo(void);
void YMBOX_Model_Initialize(void);
void YMBOX_Model_Step(const YMBOX_ModelInput *input, YMBOX_ModelOutput *output);

#endif
