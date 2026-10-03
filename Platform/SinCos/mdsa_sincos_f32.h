#ifndef MDSA_SINCOS_F32_H
#define MDSA_SINCOS_F32_H

#ifdef __cplusplus
extern "C" {
#endif

/* Called once by the bottom-layer startup code, never by generated code. */
void MDSA_SinCos_Init(void);

/*
 * Calculate a cosine/sine pair for a normalized electrical angle.
 * angle_pu is one electrical turn in [0.0F, 1.0F).  Exactly one bottom
 * implementation of this API shall be linked into a target application.
 */
void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta);

#ifdef __cplusplus
}
#endif

#endif
