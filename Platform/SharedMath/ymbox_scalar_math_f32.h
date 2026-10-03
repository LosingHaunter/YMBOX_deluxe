#ifndef YMBOX_SCALAR_MATH_F32_H_
#define YMBOX_SCALAR_MATH_F32_H_
#ifdef __cplusplus
extern "C" {
#endif
/* Accelerated scalar single-precision hypot service. Mod and floor retain
 * native MATLAB/Simulink code generation. Basic arithmetic and safety
 * predicates remain in the model. No errno or exception contract.
 * Source-model division stays an operator; target code maps it inline via
 * ymbox_tmu_div_inline.h, not an external division service.
 */
float YMBOX_Hypot_f32(float x, float y);
#ifdef __cplusplus
}
#endif
#endif
