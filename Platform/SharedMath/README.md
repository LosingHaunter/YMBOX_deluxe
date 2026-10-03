<a id="zh"></a>

**简体中文** | [English](#en)

# YMBOX 板级数学接口

控制模型通过共享 C 接口调用可加速的数学服务。SinCos、Atan、Sqrt 后端由板级工程链接选择；Hypot 使用标量服务。Mod 和 Floor 保持 MATLAB/Simulink 原生基础块及默认代码生成。模型不依赖 MCU 型号。

YMBOX 配置工具的 9.3 可保存这三个服务的实现选择，字段为 `drive.PlatformMath.SinCosBackend`、`AtanBackend`、`SqrtBackend`。普通 Simulink 仿真仍使用 GENERIC 实现；选择硬件后端后需要重新编译匹配的目标板固件。

使用 CMake 3.19 或以上版本，可直接读取计算器已写入的配置：

```cmake
include(path/to/Platform/SharedMath/ymbox_math_backend.cmake)
ymbox_link_shared_math(firmware)
```

未显式指定的服务只从项目内 `ProjectConfiguration/ApplicationParameters/YMBOX_ActiveConfiguration.json` 读取，文件不存在时提示先在计算器写入，不再读取 `.m` 参数脚本或其他回退源。配置文件作为 CMake 依赖登记，下一次构建会在配置变化后重新选择源文件。显式 `CONFIGURATION` 也只接受计算器导出的 JSON。

要锁定某份导出配置，可使用：

```cmake
ymbox_link_shared_math(firmware CONFIGURATION path/to/exported-motor.json)
```

显式 `SINCOS`、`ATAN`、`SQRT` 参数优先于配置文件中的对应选择。已有工程若写死这些参数，应移除它们或主动更新，才能跟随计算器的选择。STM32、TI、TriCore 硬件实现不能混用，通用库和 LUT 可与适用的硬件实现组合。

计算器还可导出单独的 `.cmake` 文件，供独立固件工程使用：

```cmake
include(path/to/Platform/SharedMath/ymbox_math_backend.cmake)
include(path/to/calculator-export.cmake)
ymbox_link_selected_math(firmware)
```

Sin/Cos LUT 的全周分段数跟随 `drive.PositionSensor.ControlAngleCounts`，允许 4096 或 8192，默认 4096。四分之一波形对称展开只需 1025 或 2049 个 single 点，分别占 4100 或 8196 个 8 位字节；连续角度仍使用线性插值。CMake 将分辨率传给 `MDSA_SINCOS_LUT_COUNTS`，只编译对应的一张表；不在运行时生成。`Platform/SinCos/generate_sincos_tables.py` 可复现两张常量表。

导出的 CMake 文件包含 `CONTROL_ANGLE_COUNTS`，与同份 JSON 中的控制角度配置一致。直接调用也可显式指定，例如 `ymbox_link_shared_math(firmware CONTROL_ANGLE_COUNTS 8192)`；显式值优先，必须和所用模型配置保持一致。非 CMake 工程编译 LUT 源文件时需定义 `MDSA_SINCOS_LUT_COUNTS=8192` 才能使用 8192 档，未定义时为 4096。

atan 按输入比值查表，仍为 64 段、65 点、260 字节，不随角度计数变化。STM32 CORDIC 的 Sin/Cos 和 atan 精度档位分别为 5 周期和 6 周期；周期档位不是完整函数的最坏执行时间。

| 服务 | 输入与输出 | 初始化 |
|---|---|---|
| `MDSA_SinCos_f32(angle_pu, &cos, &sin)` | 输入归一化电角度 `[0,1)`，1 表示一周；输出无量纲 | `MDSA_SinCos_Init()` |
| `YMBOX_Atan_f32(ratio)` | 输入无量纲比值，输出弧度；支持负值、超过 ±1、±0、Inf、NaN | `YMBOX_Atan_Init()` |
| `YMBOX_Sqrt_f32(value)` | 输入 single 标量，输出实数平方根；EMF 调用处输入 V²，输出 V | `YMBOX_Sqrt_Init()` |
| `YMBOX_Hypot_f32(x,y)` | 同量纲 single 标量，保留缩放式模长算法以避免中间平方溢出；内部调用 Sqrt | 无独立初始化 |

MDAS 的 `SMO_LpfPhaseAdvance` 链接 `YMBOX_SharedMath_Lib/Atan_Service`。其输出继续用于滤波相位补偿；它不是 atan2，也不接受角度输入。MDTM 启动电流旋转现在也调用同一个 SinCos 接口。

SMO 内的 `EMF_mag_sqrt` 链接 `YMBOX_SharedMath_Lib/Sqrt_Service`，调用 `YMBOX_Sqrt_f32`。上游仍计算 `Ealpha_hat² + Ebeta_hat²`；输出继续连接反电动势幅值、PLL 归一化限幅和增益调度延时。没有改成倒平方根，也没有改变这些支路的量纲或时序。

## 板级工程接入

支持 CMake 3.19 及以上的工程，可在固件目标创建后加入：

```cmake
include(path/to/YMBOX/Platform/SharedMath/ymbox_math_backend.cmake)
ymbox_link_shared_math(firmware SINCOS LUT ATAN LUT SQRT GENERIC)
```

`SINCOS` 和 `ATAN` 可以分别选择 `LUT`、`GENERIC`、`TRICORE`、`TI_TMU`、`STM32_CORDIC`。`SQRT` 可选择 `GENERIC`、`TI_TMU`、`STM32_FPU`；省略时默认 `GENERIC`，兼容原来的双服务 CMake 调用。每个接口只链接一个实现。模块加入选定源文件、头文件路径和统一初始化入口；不要同时通过 IDE 通配文件组重复加入其他后端。

```cmake
# STM32 with both CORDIC and a hardware FPU:
ymbox_link_shared_math(firmware
    SINCOS STM32_CORDIC ATAN STM32_CORDIC SQRT STM32_FPU)

# C2000 with TMU:
ymbox_link_shared_math(firmware
    SINCOS TI_TMU ATAN TI_TMU SQRT TI_TMU)
```

以上是互斥的示例。STM32 没有 CORDIC、但具有 FPU 时，可选择 `SINCOS LUT ATAN LUT SQRT STM32_FPU`。

非 CMake 工程加入以下文件及目录即可：

- `Platform/SinCos/mdsa_sincos_<backend>.c`，包含目录 `Platform/SinCos`。
- `Platform/Atan/ymbox_atan_<backend>.c`，包含目录 `Platform/Atan`。
- `Platform/Sqrt/ymbox_sqrt_<backend>.c`，包含目录 `Platform/Sqrt`。
- `Platform/SharedMath/ymbox_math_init.c`，包含目录 `Platform/SharedMath`。
- `Platform/SharedMath/ymbox_scalar_math_f32.c`，同一包含目录；TI 工程给生成代码和数学后端统一定义 `YMBOX_TMU_DIVISION=1`。
- 工具链需要时链接 C 数学库（例如 GCC 的 `-lm`）。

板级启动在外设时钟准备好后、开启控制中断前调用：

```c
#include "ymbox_math_init.h"

/* Board peripheral clocks and reset have completed here. */
YMBOX_Math_Init();
/* Initialize the generated control algorithm, then enable its control IRQ. */
```

已有工程也可分别调用三个初始化函数。使用更新后的 `YMBOX_Math_Init()` 时，需要同时链接 Sqrt 后端。生成代码只引用数学 API，`CustomSource` 不固定任何目标后端，初始化仍由板级启动管理。正常 Simulink 仿真使用 generic 主机实现；验证 LUT 时仅替换仿真源文件。

## 后端与约束

| 后端 | 实现与接入要求 |
|---|---|
| LUT | Atan 使用 65 个 single 点、线性插值、奇对称和倒数范围缩减。表为 `65*sizeof(float)`；32 位 float 为 260 个 8 位字节。当前 MDAS 正常范围小于 ±1，无运行时除法。超范围仍可计算，但需要一次倒数。 |
| GENERIC | 调用 `atanf`、`sinf`、`cosf`，用于参考、仿真及通用平台。 |
| TRICORE | 当前也是上述 C 数学库参考实现；文件名不代表已使用 TriCore 加速。可由板级工程替换同名 API 的实现。 |
| TI_TMU | C2000 C28x TMU 工具链，使用 `--float_support=fpu32 --tmu_support=tmu0`。SinCos 使用 per-unit intrinsic；Atan 使用返回弧度的 `__atan`。无需强制开启不符合 IEEE 边界语义的全局 fast-math。 |
| STM32_CORDIC | 使用目标芯片 LL/CMSIS 头文件，板级负责开启 CORDIC 时钟。可定义 `YMBOX_STM32_CORDIC_LL_HEADER` 指定头文件，兼容已有 `MDSA_STM32_CORDIC_LL_HEADER`。 |

Sqrt 后端的具体实现：

| SQRT 选择 | 实现与接入要求 |
|---|---|
| GENERIC | `sqrtf(value)`，用于仿真、参考以及没有专用后端的平台。工具链可能已将其映射为硬件指令。 |
| TI_TMU | 调用官方 intrinsic `__sqrt(value)`，对应 `SQRTF32`；需要实际芯片有 TMU，并配置 `--float_support=fpu32 --tmu_support=tmu0` 或 `tmu1`。 |
| STM32_FPU | GNU 兼容 Arm 编译器直接发出 `VSQRT.F32`。M4 可用 `-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard`；M7 可用与芯片匹配的 `-mfpu` 设置。板级启动启用 FPU，整个工程保持一致的浮点 ABI。无单精度硬件 FPU 的目标在编译时拒绝该后端。 |

Sqrt API 保留正负零和正无穷，负输入返回 NaN，NaN 继续传播；不约定 `errno` 或浮点异常标志。舍入和非正规数处理遵循板级浮点环境。STM32 后端不改 FPSCR，不访问 CORDIC，不关闭中断。该接口现已覆盖控制核心中的开方块、MATLAB Function 内的 single sqrt，以及 Hypot 服务内部的开方。

## 生成代码替换与 TMU 除法

`CoreLibrary/SharedCore_Model_Lib/rtwTargetInfo.m` 注册 `YMBOX single math`，由 `YMBOX_MathCodeReplacement.m` 定义 single sqrt/hypot 和 single 除法的替换规则。核心和代码入口模型均选择该库；正常模型 bootstrap 将此目录加入 MATLAB 路径。修改注册表后的当前 MATLAB 会话可执行 `sl_refresh_customizations` 后重新生成。

源模型的 Divide 块及 `/` 表达式不改成外部库函数。生成的 `YMBOX_DIV_F32(a,b)` 宏由 `ymbox_tmu_div_inline.h` 内联：`YMBOX_TMU_DIVISION=1` 时，适合 TMU 的有限正规数输入用官方 `__divf32`；有符号零走精确快捷路径，NaN/Inf、除零、非正规数及极端指数比保留严格 `/`。CMake 选择 TI 后端时自动定义为1，其他后端为0，0时宏等价于原始 `/`。

整个 TI 工程保持 `--fp_mode=strict --float_support=fpu32 --tmu_support=tmu0`，不需要全局 relaxed/fast-math。TMU 是 single 运算；不把原有 double 时间状态降精度。原生 Mod/Floor 由代码生成器按 MATLAB/Simulink 语义生成 `rt_modf_snf`、`floorf` 等代码；它们不经过 YMBOX 服务，也不宣称使用 TMU。加减乘、绝对值和有限性判断不额外套函数。

STM32 CORDIC 支持反正切和平方根，但这里的 single 标量开方优先使用 FPU：无需 Q 格式转换、范围缩放和外设互斥。ST AN5325 指出浮点转换开销会基本抵消 CORDIC 开方的优势。因此没有提供名为 `STM32_CORDIC` 的 Sqrt 后端；具体芯片的执行时间仍需测量。

STM32 Atan 先把比值缩减至 `[0,1]`，以 `(0.5, 0.5*ratio)` 向量做 PHASE，避免 Q1.31 向量幅值超界。每次 SinCos 调用都重新配置 COSINE 并写入单位幅值，避免 PHASE 遗留参数污染结果。两者从配置到全部结果读取都保存/恢复 PRIMASK，防止中断抢占混用；板上其他 CORDIC 使用者也必须遵守这一协议，不得在该协议外由 DMA、NMI 或其他核心操作同一外设。临界段时长需要在目标芯片上测量。

## 标定与板级验收

MDCC 的 `KfMDCC_PiKiTsId_NULL`、`KfMDCC_PiKcTsId_NULL`、`KfMDCC_PiKiTsIq_NULL`、`KfMDCC_PiKcTsIq_NULL`，以及 MDAS 的 `KfMDAS_SmoEmfLpfInvPole_s`，由原来的 single 标定值派生。改变 Ki、Kc、控制频率或滤波极点后，应重新运行参数初始化并重新生成标定/控制代码。MDCC PI 接口不再传递运行时频率，实际执行直接使用生成时派生的每拍系数。

板级验收应按当前配置的控制周期测量，覆盖实际 MDTM 分频峰值、抢占及 Flash/RAM/cache 状态。Atan 的近似误差、MIL 与 ERT 代码生成均不能代替这项测量。

参考：[TI TMU intrinsics](https://downloads.ti.com/docs/esd/SPRU514/trigonometric-math-unit-tmu-intrinsics-t365164-6.html)、[ST AN5325](https://www.st.com/resource/en/application_note/an5325-how-to-use-the-cordic-to-perform-mathematical-functions-on-stm32-mcus-stmicroelectronics.pdf)、[ST CORDIC argument requirements](https://dev.st.com/stm32cube-docs/stm32c5xx-hal-drivers/2.1.0/en/docs/drivers/hal_drivers/cordic/api/hal_cordic_exported_functions.html)。

---

<a id="en"></a>

[简体中文](#zh) | **English**

# YMBOX Board-Level Math Interface

The control model calls the math services that can be accelerated through shared C interfaces. The SinCos, Atan and Sqrt backends are selected by what the board project links; Hypot uses the scalar service. Mod and Floor keep the native MATLAB/Simulink blocks and their default code generation. The model does not depend on the MCU type.

Section 9.3 of the YMBOX configuration tool stores the implementation choice of these three services in the fields `drive.PlatformMath.SinCosBackend`, `AtanBackend` and `SqrtBackend`. Ordinary Simulink simulation still uses the GENERIC implementation; after selecting a hardware backend, the firmware of the matching target board has to be rebuilt.

With CMake 3.19 or later, the configuration written by the calculator can be read directly:

```cmake
include(path/to/Platform/SharedMath/ymbox_math_backend.cmake)
ymbox_link_shared_math(firmware)
```

Services that are not specified explicitly are read only from `ProjectConfiguration/ApplicationParameters/YMBOX_ActiveConfiguration.json` inside the project. If the file does not exist, a message asks you to write it from the calculator first; neither `.m` parameter scripts nor any other fallback source is read. The configuration file is registered as a CMake dependency, so the next build reselects the source files after the configuration changes. An explicit `CONFIGURATION` also accepts only JSON exported by the calculator.

To pin a particular exported configuration, use:

```cmake
ymbox_link_shared_math(firmware CONFIGURATION path/to/exported-motor.json)
```

Explicit `SINCOS`, `ATAN` and `SQRT` arguments take precedence over the corresponding selections in the configuration file. Existing projects that hard-code these arguments should remove them, or update them deliberately, in order to follow the calculator's selection. The STM32, TI and TriCore hardware implementations cannot be mixed; the generic library and the LUT can be combined with an applicable hardware implementation.

The calculator can also export a separate `.cmake` file for standalone firmware projects:

```cmake
include(path/to/Platform/SharedMath/ymbox_math_backend.cmake)
include(path/to/calculator-export.cmake)
ymbox_link_selected_math(firmware)
```

The number of full-turn segments of the Sin/Cos LUT follows `drive.PositionSensor.ControlAngleCounts`, which may be 4096 or 8192 (default 4096). Thanks to quarter-wave symmetry only 1025 or 2049 single-precision points are needed, taking 4100 or 8196 8-bit bytes respectively; continuous angles still use linear interpolation. CMake passes the resolution to `MDSA_SINCOS_LUT_COUNTS` and compiles only the corresponding table; nothing is generated at run time. `Platform/SinCos/generate_sincos_tables.py` reproduces the two constant tables.

The exported CMake file contains `CONTROL_ANGLE_COUNTS`, consistent with the control-angle configuration in the same JSON. A direct call can also specify it explicitly, for example `ymbox_link_shared_math(firmware CONTROL_ANGLE_COUNTS 8192)`; the explicit value takes precedence and must stay consistent with the model configuration in use. Non-CMake projects must define `MDSA_SINCOS_LUT_COUNTS=8192` when compiling the LUT source in order to use the 8192 setting; it is 4096 when undefined.

atan uses a lookup indexed by the input ratio, still with 64 segments, 65 points and 260 bytes, independent of the angle count. The STM32 CORDIC precision settings for Sin/Cos and atan are 5 and 6 cycles respectively; the cycle setting is not the worst-case execution time of the complete function.

| Service | Input and output | Initialization |
|---|---|---|
| `MDSA_SinCos_f32(angle_pu, &cos, &sin)` | Input: normalized electrical angle in `[0,1)`, where 1 is one turn; dimensionless outputs | `MDSA_SinCos_Init()` |
| `YMBOX_Atan_f32(ratio)` | Input: dimensionless ratio; output in radians; supports negative values, values beyond ±1, ±0, Inf and NaN | `YMBOX_Atan_Init()` |
| `YMBOX_Sqrt_f32(value)` | Input: single-precision scalar; output: real square root; at the EMF call site the input is in V² and the output in V | `YMBOX_Sqrt_Init()` |
| `YMBOX_Hypot_f32(x,y)` | Single-precision scalars of the same dimension; keeps the scaled magnitude algorithm to avoid overflow of the intermediate squares; calls Sqrt internally | No separate initialization |

`SMO_LpfPhaseAdvance` in MDAS links to `YMBOX_SharedMath_Lib/Atan_Service`. Its output is still used for the filter phase compensation; it is not an atan2 and does not accept an angle input. The startup current rotation in MDTM now also calls the same SinCos interface.

`EMF_mag_sqrt` inside the SMO links to `YMBOX_SharedMath_Lib/Sqrt_Service` and calls `YMBOX_Sqrt_f32`. The upstream still computes `Ealpha_hat² + Ebeta_hat²`; the output still feeds the back-EMF magnitude, the PLL normalization limit and the gain-scheduling delay. It has not been changed into an inverse square root, and neither the dimensions nor the timing of these branches have changed.

## Board project integration

Projects with CMake 3.19 or later can add this after the firmware target has been created:

```cmake
include(path/to/YMBOX/Platform/SharedMath/ymbox_math_backend.cmake)
ymbox_link_shared_math(firmware SINCOS LUT ATAN LUT SQRT GENERIC)
```

`SINCOS` and `ATAN` can each be `LUT`, `GENERIC`, `TRICORE`, `TI_TMU` or `STM32_CORDIC`. `SQRT` can be `GENERIC`, `TI_TMU` or `STM32_FPU`; it defaults to `GENERIC` when omitted, which keeps the earlier two-service CMake call working. Each interface links exactly one implementation. The module adds the selected source files, the include paths and the unified initialization entry point; do not add other backends a second time through wildcard file groups in an IDE.

```cmake
# STM32 with both CORDIC and a hardware FPU:
ymbox_link_shared_math(firmware
    SINCOS STM32_CORDIC ATAN STM32_CORDIC SQRT STM32_FPU)

# C2000 with TMU:
ymbox_link_shared_math(firmware
    SINCOS TI_TMU ATAN TI_TMU SQRT TI_TMU)
```

The examples above are mutually exclusive. An STM32 without CORDIC but with an FPU can select `SINCOS LUT ATAN LUT SQRT STM32_FPU`.

Non-CMake projects add the following files and folders:

- `Platform/SinCos/mdsa_sincos_<backend>.c`, include folder `Platform/SinCos`.
- `Platform/Atan/ymbox_atan_<backend>.c`, include folder `Platform/Atan`.
- `Platform/Sqrt/ymbox_sqrt_<backend>.c`, include folder `Platform/Sqrt`.
- `Platform/SharedMath/ymbox_math_init.c`, include folder `Platform/SharedMath`.
- `Platform/SharedMath/ymbox_scalar_math_f32.c`, same include folder; TI projects define `YMBOX_TMU_DIVISION=1` consistently for the generated code and the math backends.
- Link the C math library when the toolchain needs it (for example `-lm` with GCC).

Board startup calls this after the peripheral clocks are ready and before the control interrupt is enabled:

```c
#include "ymbox_math_init.h"

/* Board peripheral clocks and reset have completed here. */
YMBOX_Math_Init();
/* Initialize the generated control algorithm, then enable its control IRQ. */
```

Existing projects can also call the three initialization functions separately. When using the updated `YMBOX_Math_Init()`, the Sqrt backend has to be linked as well. The generated code only references the math API; `CustomSource` does not pin any target backend, and initialization remains managed by the board startup. Normal Simulink simulation uses the generic host implementation; to verify the LUT, only the simulation source file is replaced.

## Backends and constraints

| Backend | Implementation and integration requirements |
|---|---|
| LUT | Atan uses 65 single-precision points, linear interpolation, odd symmetry and reciprocal range reduction. The table is `65*sizeof(float)`; with a 32-bit float that is 260 8-bit bytes. The normal MDAS range is currently below ±1, with no run-time division. Values outside that range can still be computed but need one reciprocal. |
| GENERIC | Calls `atanf`, `sinf` and `cosf`; for reference, simulation and generic platforms. |
| TRICORE | Currently also the C math library reference implementation above; the file name does not mean that TriCore acceleration is used. The board project can replace the implementation behind the same API. |
| TI_TMU | C2000 C28x TMU toolchain with `--float_support=fpu32 --tmu_support=tmu0`. SinCos uses the per-unit intrinsics; Atan uses `__atan`, which returns radians. There is no need to force a global fast-math mode that does not meet IEEE boundary semantics. |
| STM32_CORDIC | Uses the LL/CMSIS headers of the target chip; the board enables the CORDIC clock. `YMBOX_STM32_CORDIC_LL_HEADER` can be defined to specify the header, and the existing `MDSA_STM32_CORDIC_LL_HEADER` is still supported. |

Implementations of the Sqrt backends:

| SQRT selection | Implementation and integration requirements |
|---|---|
| GENERIC | `sqrtf(value)`; for simulation, reference and platforms without a dedicated backend. The toolchain may already map it to a hardware instruction. |
| TI_TMU | Calls the official intrinsic `__sqrt(value)`, which corresponds to `SQRTF32`; the chip must actually have a TMU, with `--float_support=fpu32 --tmu_support=tmu0` or `tmu1` configured. |
| STM32_FPU | GNU-compatible Arm compilers emit `VSQRT.F32` directly. An M4 can use `-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard`; an M7 uses the `-mfpu` setting that matches the chip. Board startup enables the FPU, and the whole project keeps a consistent floating-point ABI. Targets without a single-precision hardware FPU reject this backend at compile time. |

The Sqrt API preserves positive and negative zero and positive infinity, returns NaN for negative inputs and propagates NaN; it makes no promise about `errno` or floating-point exception flags. Rounding and subnormal handling follow the board's floating-point environment. The STM32 backend does not change FPSCR, does not access the CORDIC and does not disable interrupts. This interface now covers the square-root blocks in the control core, single-precision sqrt inside MATLAB Function blocks, and the square root inside the Hypot service.

## Generated-code replacement and TMU division

`CoreLibrary/SharedCore_Model_Lib/rtwTargetInfo.m` registers `YMBOX single math`, and `YMBOX_MathCodeReplacement.m` defines the replacement rules for single-precision sqrt/hypot and single-precision division. Both the core and the code-generation entry model select this library; the normal model bootstrap adds this folder to the MATLAB path. After changing the registry, run `sl_refresh_customizations` in the current MATLAB session and regenerate.

Divide blocks and `/` expressions in the source models are not changed into external library functions. The generated `YMBOX_DIV_F32(a,b)` macro is inlined by `ymbox_tmu_div_inline.h`: with `YMBOX_TMU_DIVISION=1`, finite normal inputs that suit the TMU use the official `__divf32`; signed zeros take an exact shortcut, and NaN/Inf, division by zero, subnormals and extreme exponent ratios keep the strict `/`. CMake defines it as 1 automatically when a TI backend is selected and as 0 for the other backends; with 0 the macro is equivalent to the original `/`.

The whole TI project keeps `--fp_mode=strict --float_support=fpu32 --tmu_support=tmu0`; no global relaxed/fast-math mode is needed. The TMU works in single precision, and existing double-precision time states are not reduced in precision. Native Mod/Floor are generated by the code generator with MATLAB/Simulink semantics as `rt_modf_snf`, `floorf` and similar code; they do not go through the YMBOX services and make no claim of using the TMU. Addition, subtraction, multiplication, absolute values and finiteness checks are not wrapped in extra functions.

The STM32 CORDIC supports arctangent and square root, but here the single-precision scalar square root prefers the FPU: no Q-format conversion, range scaling or peripheral mutual exclusion is needed. ST AN5325 points out that the floating-point conversion overhead largely cancels the advantage of the CORDIC square root. Therefore no Sqrt backend named `STM32_CORDIC` is provided; the execution time on a specific chip still has to be measured.

The STM32 Atan first reduces the ratio to `[0,1]` and performs PHASE on the vector `(0.5, 0.5*ratio)`, which keeps the Q1.31 vector magnitude in range. Every SinCos call reconfigures COSINE and writes the unit magnitude, so that parameters left over from PHASE cannot contaminate the result. Both save and restore PRIMASK from the configuration until all results have been read, which prevents mixed use through interrupt preemption; other CORDIC users on the board must follow the same protocol, and DMA, NMI or other cores must not operate the same peripheral outside this protocol. The length of the critical section has to be measured on the target chip.

## Calibration and board acceptance

`KfMDCC_PiKiTsId_NULL`, `KfMDCC_PiKcTsId_NULL`, `KfMDCC_PiKiTsIq_NULL` and `KfMDCC_PiKcTsIq_NULL` of MDCC, and `KfMDAS_SmoEmfLpfInvPole_s` of MDAS, are derived from the original single-precision calibration values. After changing Ki, Kc, the control frequency or the filter pole, run the parameter initialization again and regenerate the calibration/control code. The MDCC PI interface no longer passes a run-time frequency; execution directly uses the per-step coefficients derived at generation time.

Board acceptance should measure at the control period of the current configuration and cover the actual MDTM divider peak, preemption and the Flash/RAM/cache state. Neither the approximation error of Atan nor MIL and ERT code generation can replace this measurement.

References: [TI TMU intrinsics](https://downloads.ti.com/docs/esd/SPRU514/trigonometric-math-unit-tmu-intrinsics-t365164-6.html), [ST AN5325](https://www.st.com/resource/en/application_note/an5325-how-to-use-the-cordic-to-perform-mathematical-functions-on-stm32-mcus-stmicroelectronics.pdf), [ST CORDIC argument requirements](https://dev.st.com/stm32cube-docs/stm32c5xx-hal-drivers/2.1.0/en/docs/drivers/hal_drivers/cordic/api/hal_cordic_exported_functions.html).
