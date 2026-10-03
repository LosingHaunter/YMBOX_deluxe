# YMBOX Sin/Cos bottom-layer service

The Simulink model has one fixed dependency:

```c
void MDSA_SinCos_f32(float angle_pu,
                     float *cos_theta,
                     float *sin_theta);
```

`angle_pu` is one electrical turn in `[0, 1)`. Generated model code declares
and calls this function but does not select a processor, compile a target
adapter, or initialize a peripheral.

## Target integration rule

Link exactly one implementation into the firmware application:

- `mdsa_sincos_generic.c`: portable host/reference implementation using
  `sinf` and `cosf`.
- `mdsa_sincos_lut.c`: portable quarter-wave lookup implementation; its
  table and interpolation are fully owned by the bottom layer.
- `mdsa_sincos_stm32_cordic.c`: STM32G4 CORDIC adapter.
- `mdsa_sincos_ti_tmu.c`: TI C2000 TMU adapter.
- `mdsa_sincos_tricore.c`: TriCore integration starting point.

Do not compile two adapters together because each intentionally defines the
same two public symbols. Do not edit generated model source files.

The bottom-layer startup sequence must call `MDSA_SinCos_Init()` once before
the first control-cycle call. For a peripheral adapter, enable its clock
before this call.

## STM32G4

Add `mdsa_sincos_stm32_cordic.c` and this directory to the MCU project. Enable
the CORDIC clock in board startup, then call `MDSA_SinCos_Init()`. The model and
generated code remain unchanged.

## TMS320F28379D

Add `mdsa_sincos_ti_tmu.c` and this directory to the C2000 project. Build the
file with `--float_support=fpu32 --tmu_support=tmu0`. The adapter calls
`__cospuf32` and `__sinpuf32` directly, so the model's per-unit angle does not
need a radian conversion. `MDSA_SinCos_Init()` is intentionally empty for TMU.

## Host simulation

The checked-in `YMBOX_Control_Core.slx` already contains the fixed interface
contract. Normal simulation uses `mdsa_sincos_generic.c`; production
custom-source and initializer settings remain empty so the firmware build owns
both decisions.
