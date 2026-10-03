(function () {
  "use strict";
  const engine = window.YMBOXConfig, labels = window.YMBOXLabels;
  const numbers = window.YMBOXNumberFormat;
  const root = document.getElementById("ymboxConfigurationView");
  const layout = window.YMBOXLayout;
  layout.validate(engine.fields);
  const byPath = new Map(engine.fields.map(field => [field.path, field]));
  const hiddenFields = new Set(["CurrentReference.AllocationModes_enum", "Features.SensoredFieldWeakeningEnable"]);
  const switchFields = new Set(["Feedforward.VoltageMode_enum", "Feedforward.ElectricalAngleCompEnable"]);
  const visibleFields = engine.fields.filter(field => !hiddenFields.has(field.path));
  const motorPresetPaths = ["Motor.PolePairs","Motor.StatorResistance_Ohm","Motor.Ld_H","Motor.Lq_H","Motor.PmFlux_Wb","Motor.Inertia_kgm2","Motor.RatedCurrent_A","Motor.MaxCurrent_A"];
  const groupFields = new Map(layout.groups.map(group => [group.id, group.sections.flatMap(section => section.paths.filter(path => !hiddenFields.has(path)).map(path => byPath.get(path)))]));
  const fieldLabels = {"Execution.WorkMode_enum":"仿真工作模式", "Execution.Enable":"仿真使能", "FieldWeakening.Enable":"启用有感弱磁", "Observer.PllBandwidth_rads":"SMO PLL 带宽", "PositionSensor.PllBandwidth_rads":"有感 PLL 带宽", "Timing.ControlFrequency_Hz":"控制频率"};
  fieldLabels["PositionSensor.NativeCountsPerMechanicalRev"] = "每机械圈原始计数（分辨率）";
  const fieldLabel = path => fieldLabels[path] || labels[path.split(".").at(-1)] || path.split(".").at(-1);
  const isTimingHint = field => field.readOnly && field.path.startsWith("Timing.");
  function timingHintValue(field) {
    if (field.path === "Timing.BaseTick_s") return `${numbers.format(field.defaultValue * 1e6)} μs`;
    if (field.path.endsWith("_Hz")) return `${numbers.format(field.defaultValue / 1000)} kHz`;
    return `${numbers.format(field.defaultValue)} ppm`;
  }
  const options = {
    "Feedforward.VoltageMode_enum":[["0","关闭"],["1","双轴"],["2","仅 d 轴"],["3","仅 q 轴"]],
    "Meta.MotorClass":[["SPMSM","SPMSM · 表贴式"],["IPMSM","IPMSM · 内嵌式"]],
    "Execution.ObserverBuildVariant":[["0","0 · 有感构建"],["1","1 · SMO 构建"]],
    "Execution.WorkMode_enum":[["0","0 · 停止"],["1","1 · αβ 电压开环"],["2","2 · dq 电压开环"],["3","3 · dq 电流开环"],["4","4 · 有感转速环"],["5","5 · 转矩控制"],["6","6 · SMO 转速环"]],
    "PositionSensor.Direction":[["1","+1 · 正向"],["-1","−1 · 反向"]],
    "PositionSensor.ControlAngleCounts":[["4096","12 位 · 4096 计数/电角度圈"],["8192","13 位 · 8192 计数/电角度圈"]],
    "PositionSensor.NativeCountsPerMechanicalRev":Array.from({length:13},(_,index)=>{const bits=index+12;return [String(2**bits),`${bits} 位 · 2^${bits} = ${2**bits} 计数/圈`];}),
    "PlatformMath.SinCosBackend":[["LUT","LUT 查表（线性插值）"],["GENERIC","通用数学库"],["STM32_CORDIC","STM32 CORDIC"],["TI_TMU","TI TMU"],["TRICORE","TriCore 工具链"]],
    "PlatformMath.AtanBackend":[["LUT","LUT 查表（线性插值）"],["GENERIC","通用数学库"],["STM32_CORDIC","STM32 CORDIC"],["TI_TMU","TI TMU"],["TRICORE","TriCore 工具链"]],
    "PlatformMath.SqrtBackend":[["GENERIC","通用数学库"],["STM32_FPU","STM32 FPU"],["TI_TMU","TI TMU"]],
    "DcBusMeasurement.CurrentSource_enum":[["0","0 · 母线电流传感器"],["1","1 · FOC 估算"]],
    "Limits.TorquePriorityBelowBaseSpeed":[["true","启用（Iq优先）"],["false","禁用（Id优先）"]]
  };
  const units = {s:"s",Hz:"Hz",Ohm:"Ω",H:"H",Wb:"Wb",A:"A",V:"V",rpm:"rpm",rpms:"rpm/s",rads:"rad/s",rad:"rad",Nm:"N·m",kgm2:"kg·m²",Nms:"N·m·s",Aps:"A/s",Vs:"V·s",ppm:"ppm",VperA:"V/A",AperRpm:"A/rpm",perS:"1/s",AperUnit:"A",AperUnitPerS:"A/s"};
  root.innerHTML = `
    <nav class="calculator-nav"><button class="back-button" data-back-toolbox type="button">← 返回工具箱</button><span class="breadcrumb"><strong>YMBOX</strong><i>/</i>YMBOX配置工具</span></nav>
    <header class="yc-header"><div><p class="eyebrow">MODEL CONFIGURATION</p><h1>YMBOX配置工具</h1><p>按计算关系设置参数 → 更新自动参数 → 检查并写入 JSON</p></div><div class="yc-count"><strong>${visibleFields.length}</strong><span>页面配置参数 · ${layout.groups.length} 个功能组</span></div></header>
    <section class="panel profile-panel pi-profile-panel">
      <div class="profile-fields pi-profile-fields">
        <label class="profile-name-field"><span>YMBOX 方案名称</span><input id="ycProfileName" type="text" maxlength="80" placeholder="例如：KY130 · 5k 调试配置"></label>
        <button id="ycProfileSave" class="primary-button profile-save-button" type="button">保存方案</button>
        <label class="profile-select-field"><span>已保存 YMBOX 方案</span><select id="ycProfileSelect"><option value="">选择方案</option></select></label>
        <label class="profile-link-toggle"><input id="ycLinkEnabled" type="checkbox"><span class="switch-ui" aria-hidden="true"><i></i></span><span>联动绑定</span></label>
        <label class="profile-select-field motor-binding-field"><span>绑定电机方案</span><select id="ycLinkedMotor" disabled><option value="">选择电机方案</option></select></label>
      </div>
      <div class="profile-meta"><span id="ycProfileStatus">尚未选择方案</span><span id="ycLinkStatus">未绑定电机参数</span><span id="ycStoragePath"></span></div>
      <p class="yc-hint">方案可保存未完成的设置。绑定后自动导入电机参数，同步项以电机方案为准并锁定；其他手动设置保留，取消绑定后可编辑。</p>
    </section>
    <section class="panel yc-start">
      <div class="yc-actions yc-motor-selection"><label>电机参数方案<select id="ycMotor"><option value="">选择已保存的电机</option></select></label></div>
      <div class="yc-actions yc-motor-actions"><button id="ycImportMotor" class="primary-button" type="button">导入电机参数</button><button id="ycRecommend" class="primary-button" type="button">一键更新/补全参数</button><button id="ycImportMotorFile" class="secondary-button" type="button">导入电机 JSON</button><button id="ycCurrent" class="secondary-button" type="button">载入已写入配置</button><button id="ycClear" class="secondary-button" type="button">清空配置</button><input id="ycMotorFile" type="file" accept=".json" hidden></div>
      <details class="yc-tuning"><summary>推荐设置与依据</summary><p>更新并补全所有未手动设置的参数，包括已有推荐值和空项。所有自动参数均显示计算后的数值；手动输入的数值、0 和禁用状态均保留；导入的电机参数作为计算依据。新电机按电机参数推荐 PI，并从有感转速闭环开始。电流参数采用绕组相电流峰值。</p><label><input id="ycCustomTuning" type="checkbox"> 自定义 PI 推荐目标</label><div class="yc-tuning-grid"><label>电流环带宽 / Hz<input id="ycCurrentBw" type="text" value="300"></label><label>转速环带宽 / Hz<input id="ycSpeedBw" type="text" value="5"></label><label>相位裕度 / °<input id="ycPhaseMargin" type="text" value="55"></label></div><p>修改电机、频率或推荐目标后，点击“一键更新/补全参数”重新计算自动参数。清空手动项即可恢复自动更新。SMO 启动与保护设置需按实际电机和驱动器确认。本页仿真指令用于仿真入口。</p></details>
    </section>
    <section class="panel yc-file-panel"><div class="yc-actions"><button id="ycImport" class="secondary-button" type="button">一键导入配置 JSON</button><input id="ycFile" type="file" accept=".json" hidden><button id="ycExport" class="secondary-button" type="button">导出配置 JSON</button></div><div class="yc-actions"><button id="ycValidate" class="secondary-button" type="button">检查参数</button><button id="ycApply" class="primary-button" type="button">一键写入模型</button><button id="ycGenerateCode" class="primary-button" type="button" data-i18n="ymbox.actions.directCodegen" disabled>不仿真直接生成代码</button></div><p id="ycConnection" class="yc-hint">正在检查本地 JSON 写入服务…</p><p class="yc-message" id="ycStatus" role="status" aria-live="polite">先导入电机或载入已写入配置，再点击“一键更新/补全参数”。</p></section>
    <section class="panel yc-validation" id="ycValidation" hidden><h2>参数检查结果</h2><ul id="ycIssues"></ul></section>
    <div class="yc-toolbar"><label class="yc-search"><span>查找参数</span><input id="ycSearch" type="search" placeholder="中文名、变量名或参数分组"></label><span id="ycProgress"></span><button id="ycExpand" class="secondary-button" type="button">展开全部</button><button id="ycCollapse" class="secondary-button" type="button">折叠高级参数</button></div>
    <nav id="ycGroupNav" class="yc-group-nav" aria-label="参数分组导航"></nav>
    <div id="ycGroups" class="yc-groups"></div>
    <div class="yc-floating-actions"><p id="ycFloatingStatus" class="yc-floating-status" hidden></p><button id="ycFloatingRecommend" class="primary-button yc-floating-update" type="button" title="更新所有未手动设置的参数，并补全空项"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 0 1 15-6.7L21 8M21 3v5h-5M21 12a9 9 0 0 1-15 6.7L3 16M8 16H3v5"/></svg><span>一键更新</span></button></div>`;
  const $ = id => document.getElementById(id);
  const fieldInputs = new Map(), fieldRows = new Map(), groupNodes = new Map(), referenceNodes = [];
  const motorPresetHelp = document.createElement("div");
  motorPresetHelp.id = "ycMotorPresetHelp";
  motorPresetHelp.className = "yc-motor-preset-help";
  motorPresetHelp.setAttribute("role", "note");
  motorPresetHelp.hidden = true;
  motorPresetHelp.innerHTML = '<strong>以下电机基础参数仍采用模型预设值（红色标记），请导入电机参数或按实际电机填写：</strong><div id="ycMotorPresetLinks" class="yc-motor-preset-links"></div>';
  $("ycStatus").after(motorPresetHelp);
  const motorPresetLinks = new Map();
  for (const path of motorPresetPaths) {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.path = path;
    button.textContent = fieldLabel(path);
    button.onclick = () => locate(fieldInputs.get(path));
    $("ycMotorPresetLinks").append(button);
    motorPresetLinks.set(path, button);
  }
  const common = new Set(layout.groups.filter(group => group.common).map(group => group.id));
  const profileDefaultsVersion = 2;
  const dividerPath = "Timing.MDTMTaskDivider_NULL";
  let values = engine.empty(), sources = {[dividerPath]:"模型预设值"}, origins = {[dividerPath]:"automatic"}, validating = false, service = null, nativeApi = null, revision = 0, directCodegenRunning = false;
  let bindingRequest = 0, profileRequest = 0;
  const presetMotorInputs = () => motorPresetPaths.filter(path => origins[path] === "automatic" && sources[path] === "模型预设值");
  function message(text,error=false) { $("ycStatus").textContent=text; $("ycStatus").classList.toggle("is-error",error); }
  let floatingStatusTimer;
  function floatingMessage(text,error=false) {
    clearTimeout(floatingStatusTimer);
    const status=$("ycFloatingStatus");status.textContent=text;status.hidden=!text;status.classList.toggle("is-error",error);
    if(text) floatingStatusTimer=setTimeout(()=>{status.hidden=true;},error?8000:5000);
  }
  const pllTargetInputs = {positionPllAngleErrorDeg:"ycPllAngleError",positionPllSpeedLagRads:"ycPllSpeedLag"};
  function tuningTargets() {
    const targets=$("ycCustomTuning").checked?{currentBandwidthHz:numbers.readInput($("ycCurrentBw")),speedBandwidthHz:numbers.readInput($("ycSpeedBw")),phaseMarginDeg:numbers.readInput($("ycPhaseMargin"))}:{};
    for(const [key,id] of Object.entries(pllTargetInputs)) {
      const value=numbers.readInput($(id));
      if(key==="positionPllAngleErrorDeg" ? Number(value)!==3 : String(value).trim()!=="") targets[key]=value;
    }
    if($("ycPllUseSpeedRamp").checked) targets.positionPllUseSpeedRamp=true;
    return targets;
  }
  function restoreTuning(targets={}) {
    $("ycCustomTuning").checked=["currentBandwidthHz","speedBandwidthHz","phaseMarginDeg"].some(key=>targets[key]!==undefined);
    numbers.writeInput($("ycCurrentBw"),targets.currentBandwidthHz??300);numbers.writeInput($("ycSpeedBw"),targets.speedBandwidthHz??5);numbers.writeInput($("ycPhaseMargin"),targets.phaseMarginDeg??55);
    for(const [key,id] of Object.entries(pllTargetInputs)) numbers.writeInput($(id),targets[key]??(key==="positionPllAngleErrorDeg"?3:""));
    $("ycPllUseSpeedRamp").checked=targets.positionPllUseSpeedRamp===true;
  }
  function profileData() {return {schemaVersion:1,defaultsVersion:profileDefaultsVersion,values:{...values},sources:{...sources},origins:{...origins},targets:tuningTargets(),link:{enabled:$("ycLinkEnabled").checked,motorProfile:$("ycLinkedMotor").value}};}
  function profileStatus(text,error=false) {$("ycProfileStatus").textContent=text;$("ycProfileStatus").className=error?"is-error":"is-success";}
  function linkStatus(text,error=false) {$("ycLinkStatus").textContent=text;$("ycLinkStatus").className=error?"is-error":"";}
  const editableLinkedMotorFields=new Set(["Execution.TargetSpeed_rpm","Execution.TargetTorque_Nm"]);
  function isLinkedMotorField(path) {return $("ycLinkEnabled").checked&&Boolean($("ycLinkedMotor").value)&&origins[path]==="motor"&&!editableLinkedMotorFields.has(path);}
  function refreshBindingControls() {
    const enabled=$("ycLinkEnabled").checked,name=$("ycLinkedMotor").value;
    for(const id of ["ycMotor","ycImportMotor","ycImportMotorFile","ycMotorFile"]) $(id).disabled=enabled;
    if(enabled) {
      if(name&&![...$("ycMotor").options].some(option=>option.value===name)) $("ycMotor").add(new Option(name,name));
      $("ycMotor").value=name;
    }
    for(const [path,input] of fieldInputs) {
      const linked=isLinkedMotorField(path),locked=Boolean(byPath.get(path).readOnly)||linked,row=fieldRows.get(path);
      if(input.tagName==="SELECT") input.disabled=locked;
      else if(input.tagName==="INPUT") input.readOnly=locked;
      for(const button of row.querySelectorAll(".yc-segmented button")) button.disabled=locked;
      row.classList.toggle("yc-motor-linked",linked);
    }
  }
  function setBinding(link={}) {
    bindingRequest++;
    $("ycLinkEnabled").checked=Boolean(link.enabled);$("ycLinkedMotor").disabled=!link.enabled;
    const name=String(link.motorProfile||"");
    if(name&&![...$("ycLinkedMotor").options].some(option=>option.value===name)) $("ycLinkedMotor").add(new Option(name,name));
    $("ycLinkedMotor").value=name;
    refreshBindingControls();
    linkStatus(link.enabled?(name?`待同步电机：${name}`:"请选择绑定电机方案"):"未绑定电机参数");
  }
  function resetProfile() {profileRequest++;$("ycProfileName").value="";$("ycProfileSelect").value="";setBinding();profileStatus("尚未选择方案");}
  function restoreProfile(data) {
    if(!data?.values||typeof data.values!=="object"||Array.isArray(data.values)) throw new Error("方案数据无效");
    values=Object.fromEntries(engine.fields.map(field=>[field.path,data.values[field.path]===undefined?"":engine.raw(data.values[field.path])]));
    const profileSources={...data.sources},profileOrigins={...data.origins};
    if(data.values[dividerPath]===undefined) {values[dividerPath]=engine.raw(byPath.get(dividerPath).defaultValue);profileSources[dividerPath]="模型预设值";profileOrigins[dividerPath]="automatic";}
    values=engine.restoreVersionDefaults(values,data.sources,data.origins);
    ({sources,origins}=engine.normalizeState(values,profileSources,profileOrigins));
    // Defaults apply only to new configurations. Preserve values saved by the
    // previous defaults before a linked-motor refresh or automatic update can
    // reinterpret them under the new defaults.
    for(const [path,legacyDefault] of Object.entries({
      "DcBusMeasurement.CurrentSource_enum":"0",
      "Execution.TargetTorque_Nm":"2",
      "Execution.TestQ":"3"
    })) if(Number(data.defaultsVersion||1)<profileDefaultsVersion&&data.values[path]!==undefined&&engine.raw(data.values[path])===legacyDefault&&origins[path]==="automatic") {
      sources[path]="保留旧方案值";origins[path]="manual";
    }
    for(const field of engine.fields.filter(field=>field.path.startsWith("PlatformMath.")&&data.values[field.path]===undefined)) {
      values[field.path]=engine.raw(field.defaultValue);sources[field.path]="新增数学实现默认值";origins[field.path]="automatic";
    }
    for(const path of ["Feedforward.VoltageMode_enum", "Feedforward.ElectricalAngleCompEnable"]) if(data.values[path]===undefined) {
      values[path]=engine.raw(byPath.get(path).defaultValue);sources[path]="新增前馈开关 · 保持原配置行为";origins[path]="automatic";
    }
    values=engine.restoreAutoValues(values);restoreTuning(data.targets);setBinding(data.link);
  }
  function syncHiddenFields() {
    const modes="CurrentReference.AllocationModes_enum", feature="Features.SensoredFieldWeakeningEnable", owner="FieldWeakening.Enable";
    values[modes]=engine.raw(byPath.get(modes).defaultValue);sources[modes]="当前模型固定约束";origins[modes]="automatic";
    // Preserve an old manual setting from the now-hidden switch at its visible owner.
    if(origins[feature]==="manual" && origins[owner]!=="manual" && ["true","false"].includes(values[feature])) {
      values[owner]=values[feature];sources[owner]="手动设置 · 继承原有感弱磁开关";origins[owner]="manual";
    }
    values[feature]=values[owner]??"";
    sources[feature]=values[feature]?"与启用有感弱磁开关一致":"";origins[feature]="automatic";
  }
  function refresh() {
    revision++;
    syncHiddenFields();
    const pendingMotorInputs = new Set(presetMotorInputs());
    let filled=0;
    for(const field of engine.fields) {
      const input=fieldInputs.get(field.path),row=fieldRows.get(field.path);
      row.classList.toggle("yc-motor-preset", pendingMotorInputs.has(field.path));
      const presetNote=row.querySelector(".yc-motor-preset-note");
      if(presetNote) presetNote.hidden=!pendingMotorInputs.has(field.path);
      if(isTimingHint(field)) {values[field.path]=engine.raw(field.defaultValue);sources[field.path]="当前模型固定约束";origins[field.path]="automatic";}
      if(engine.isVersion(field)) {sources[field.path]="手动设置";origins[field.path]="manual";}
      if (input.matches("input[inputmode]")) {
        const full=values[field.path]??"";
        if(document.activeElement!==input || numbers.readInput(input)!==full) numbers.writeInput(input,full);
      } else input.value=isTimingHint(field)?timingHintValue(field):values[field.path]??"";
      if(input.tagName==="SELECT" && String(input.value)!==String(values[field.path]??"")) { input.add(new Option(`无效值：${numbers.raw(values[field.path])}`,values[field.path]));input.value=values[field.path]; }
      for(const button of row.querySelectorAll(".yc-segmented button")) button.setAttribute("aria-pressed",String(button.dataset.value===input.value));
      const feedforwardHint=row.querySelector(".yc-feedforward-hint");
      if(feedforwardHint) {
        const mode=Number(values["Feedforward.VoltageMode_enum"]);
        const enabled=field.path==="Feedforward.DAxisScale_NULL"?[1,2].includes(mode):field.path==="Feedforward.QAxisScale_NULL"?[1,3].includes(mode):values["Feedforward.ElectricalAngleCompEnable"]==="true";
        feedforwardHint.textContent=enabled?"当前已启用；系数为 0 时补偿量为 0。":"当前未启用；保留此系数，重新启用后恢复。";
      }
      if(!hiddenFields.has(field.path) && String(values[field.path]??"").trim())filled++;
      let source=sources[field.path]||(field.readOnly?"模型固定约束，更新时自动写入":"");
      if(field.path==="ControlTargets.SpeedLoopKiSeriesPerStep_NULL") source=source.replace("串联 KiStep = PI 零点角频率 / 控制频率","推荐积分系数，已按控制周期换算");
      row.querySelector(".yc-source").textContent=origins[field.path]==="manual"&&!source.startsWith("手动设置")?`手动设置 · ${source}`:source;
      if(field.path.startsWith("PlatformMath.")) {
        const backend=values[field.path],name=field.path.split(".").at(-1);
        const hints={GENERIC:"使用工具链的单精度数学库。",TRICORE:"链接项目已有的 TriCore 实现，由目标工具链编译。",TI_TMU:"需要带 TMU 的 TI 目标及对应编译选项。",STM32_FPU:"需要单精度硬件 FPU，并使用匹配的浮点 ABI。"};
        const counts=Number(values["PositionSensor.ControlAngleCounts"]);
        const sincosHint=[4096,8192].includes(counts)?`跟随控制角度：全周 ${counts} 段；四分之一波形 ${counts/4} 段、${counts/4+1} 点，表占 ${counts+4} B。` : "先选择控制角度计数，Sin/Cos LUT 全周分段数随之同步。";
        row.querySelector(".yc-backend-hint").textContent=backend==="LUT"?(name==="SinCosBackend"?sincosHint:"当前实现固定为 64 段、65 点，表占 260 B；atan 按输入比值查表，不随角度计数变化。"):backend==="STM32_CORDIC"?`需要带 CORDIC 的 STM32。当前精度档位固定为 ${name==="SinCosBackend"?5:6} 周期，底层负责时钟与外设互斥。`:hints[backend]||"选择目标板使用的数学实现。";
      }
    }
    $("ycProgress").textContent=`已填写 ${filled} / ${visibleFields.length} · 空项 ${visibleFields.length-filled}`;
    for(const [name,node] of groupNodes) { const items=groupFields.get(name);node.querySelector(".yc-group-count").textContent=`${items.filter(field=>String(values[field.path]??"").trim()).length} / ${items.length}`; }
    $("ycMotorPresetHelp").hidden=pendingMotorInputs.size===0;
    for(const [path,button] of motorPresetLinks) button.hidden=!pendingMotorInputs.has(path);
    groupNodes.get("Motor").classList.toggle("yc-has-motor-presets",pendingMotorInputs.size>0);
    $("ycGroupNav").querySelector('[data-go-group="Motor"]').classList.toggle("yc-has-motor-presets",pendingMotorInputs.size>0);
    refreshBindingControls();refreshReferences();
    if(validating)showValidation(false);
  }
  function showValidation(announce=true, options={}) {
    validating=true;const result=engine.validate(values,options);$("ycValidation").hidden=result.ok&&!result.warnings.length;$("ycIssues").replaceChildren();
    for(const row of fieldRows.values()) { row.classList.remove("yc-invalid");row.querySelector(".yc-error").textContent="";row.querySelector("input,select,output").removeAttribute("aria-invalid"); }
    for(const issue of result.issues) {
      const row=fieldRows.get(issue.path);row.classList.add("yc-invalid");row.querySelector(".yc-error").textContent=issue.message;row.querySelector("input,select,output").setAttribute("aria-invalid","true");
      const li=document.createElement("li"),button=document.createElement("button");button.type="button";button.textContent=`${fieldLabel(issue.path)}：${issue.message}`;
      button.onclick=()=>locate(fieldInputs.get(issue.path));li.append(button);$("ycIssues").append(li);
    }
    for(const warning of result.warnings) { const li=document.createElement("li");li.textContent=warning;$("ycIssues").append(li); }
    if(announce)message(result.ok?"页面参数检查通过，可写入 JSON。模型校验在下次更新或仿真时执行。":`有 ${result.issues.length} 项需要处理，点击下方检查结果可定位。`,!result.ok);
    return result;
  }
  function config() { showValidation();return engine.exportDocument(values,sources,origins,tuningTargets()); }
  function safe(action) { return async()=>{try {await action();}catch(error){message(error.message,true);}}; }
  function createField(field) {
  const hint=isTimingHint(field),segmented=switchFields.has(field.path),key=field.path.split(".").at(-1),row=document.createElement(hint||segmented?"div":"label");row.className=hint?"yc-field yc-constraint":segmented?"yc-field yc-switch-field":"yc-field";row.dataset.path=field.path;
  row.hidden=hiddenFields.has(field.path);
  const text=document.createElement("span");text.className="yc-label";text.textContent=fieldLabel(field.path);const unit=units[key.split("_").at(-1)];if(unit&&!hint)text.textContent+=` / ${unit}`;
  const choice=options[field.path]||(field.type==="logical"?[["true","启用"],["false","禁用"]]:null),input=document.createElement(hint?"output":choice?"select":"input");input.id=`yc-${field.path}`;input.dataset.path=field.path;
  if(hint) {input.className="yc-constraint-value";input.setAttribute("aria-label",fieldLabel(field.path));input.tabIndex=-1;}
  else if(choice) {input.add(new Option("未设置",""));for(const [value,label] of choice)input.add(new Option(label,value));input.disabled=field.readOnly;}
  else {input.type="text";input.spellcheck=false;input.readOnly=field.readOnly;input.placeholder="未设置";if(field.type!=="char")input.inputMode="decimal";}
  if(input.matches("input[inputmode]")) numbers.bindInput(input,engine.isVersion(field)?numbers.version:numbers.raw);
  const variable=document.createElement("small");variable.className="yc-variable";variable.textContent=field.path;
  const source=document.createElement("small"),error=document.createElement("small");source.className="yc-source";error.className="yc-error";
  if(!hint) input.addEventListener("input",()=>{if(isLinkedMotorField(field.path)){refresh();return;}const full=numbers.readInput(input);values[field.path]=full;sources[field.path]=full.trim()?"手动设置":"";origins[field.path]=full.trim()?"manual":"automatic";refresh();message("配置已修改。点击“一键更新/补全参数”刷新其余自动参数，导入前将重新校验。");});
  row.append(text,input,variable,source);
  if(motorPresetPaths.includes(field.path)) {
    const presetNote=document.createElement("small");presetNote.className="yc-motor-preset-note";presetNote.textContent="待提供实际电机参数";presetNote.hidden=true;row.append(presetNote);
  }
  row.append(error);
  if(segmented) {
    input.hidden=true;
    const group=document.createElement("div");group.className="yc-segmented";group.dataset.choices=choice.length;group.setAttribute("role","group");group.setAttribute("aria-label",fieldLabel(field.path));
    for(const [value,label] of choice) {
      const button=document.createElement("button");button.type="button";button.dataset.value=value;button.textContent=label;button.setAttribute("aria-pressed","false");
      button.onclick=()=>{input.value=value;input.dispatchEvent(new Event("input",{bubbles:true}));};group.append(button);
    }
    input.after(group);
  }
  if(["Feedforward.DAxisScale_NULL","Feedforward.QAxisScale_NULL","Feedforward.ElectricalAngleCompScale_NULL"].includes(field.path)) {
    const help=document.createElement("small");help.className="yc-input-task-hint yc-feedforward-hint";input.after(help);
  }
  if(field.path==="PositionSensor.NativeCountsPerMechanicalRev") {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="按位数选择，保存和导出仍使用实际每圈计数；当前模型支持 12～24 位。";input.after(help);
  }
  if(field.path==="PositionSensor.ControlAngleCounts") {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="电角度计数范围为 0～N−1；计数换算与 Sin/Cos LUT 全周分段数同步。8192 档每计数 0.04394531° 电角度，原始传感器分辨率独立设置。";input.after(help);
  }
  if(field.path.startsWith("PlatformMath.")) {
    const help=document.createElement("small");help.className="yc-input-task-hint yc-backend-hint";input.after(help);
  }
  if(field.path==="CurrentReference.MtpaTableSize") {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="允许 17～257 点的整数。";input.after(help);
  }
  const handoverHints={
    "StartupSupervisor.DirectHandoverDwellTime_s":"每次I/F转入SMO时开始计时；连续失锁确认后，窗口内可退回I/F，窗口外停机。短时恢复不延长窗口；低速退出另按退出比例处理。",
    "StartupSupervisor.ObserverLossConfirmTime_s":"SMO接管期间和接管后均连续确认失锁；恢复就绪即清零失效计时，不立即切换角度来源。",
    "StartupSupervisor.DirectHandoverTime_s":"从当前I/F控制角度平滑过渡到SMO角度；首拍继续推进角度，退回I/F时承接实际已使用的角度与转速。",
    "Simulation.PowerStageStep_s":"自动候选：PWM每周期至少200步，非零死区至少4步，并按PWM半周期整数步对齐；手动值保留。闭环稳定后，转矩和电流纹波仍须单独验证步长收敛。"
  };
  if(handoverHints[field.path]) {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent=handoverHints[field.path];input.after(help);
  }
  if(engine.isVersion(field)) {
    input.placeholder="1.0";
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="手动版本标记，默认 1.0；更新参数和保存时均保留，不自动递增。";row.append(help);
  }
  if(field.path==="Timing.InputTaskFrequencyOverride_Hz") {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="未手动设置时，更新为控制频率的实际数值。例如控制 5 kHz 时，输入频率为 5000 Hz、周期为 200 μs；当前模型不支持独立输入频率。";row.append(help);
  }
  if(field.path==="Inverter.PwmFrequencyOverride_Hz") {
    const help=document.createElement("small");help.className="yc-input-task-hint";help.textContent="未手动设置时，更新为控制频率的实际数值；手动频率须为控制频率的正整数倍。";row.append(help);
  }
    fieldInputs.set(field.path,input);fieldRows.set(field.path,row);return row;
  }
  function locate(input) {
    $("ycSearch").value="";filter();
    if(input.hidden && switchFields.has(input.dataset.path)) input=input.parentElement.querySelector('.yc-segmented button[aria-pressed="true"]')||input.parentElement.querySelector('.yc-segmented button');
    for(let parent=input.parentElement;parent&&parent!==root;parent=parent.parentElement) if(parent.tagName==="DETAILS")parent.open=true;
    input.scrollIntoView({block:"center"});input.focus({preventScroll:true});
  }
  function refreshReferences() {
    for(const {reference,output} of referenceNodes) {
      const value=reference.path?values[reference.path]:numbers.readInput($(reference.target));
      const field=reference.path?byPath.get(reference.path):null;
      const unit=reference.unit||(reference.path?units[reference.path.split("_").at(-1)]:"");
      const choices=field&&(options[field.path]||(field.type==="logical"?[["true","启用"],["false","禁用"]]:null));
      const choice=choices?.find(([key])=>key===String(value));
      output.textContent=String(value??"").trim()?`${choice?choice[1]:numbers.raw(value)}${unit?` ${unit}`:""}`:"未填写";
      if(reference.target&&!$("ycCustomTuning").checked) output.textContent+="（未启用）";
      output.title=String(value??"");
    }
  }
  function sharedParameters(references) {
    const context=document.createElement("div");context.className="yc-shared-parameters";
    const caption=document.createElement("p");caption.textContent="共用参数 · 当前值（点击定位编辑）";context.append(caption);
    const list=document.createElement("div");list.className="yc-reference-list";
    for(const reference of references) {
      const button=document.createElement("button"),name=document.createElement("span"),output=document.createElement("strong");
      button.type="button";button.className="yc-reference";
      name.textContent=`${reference.symbol?reference.symbol+" · ":""}${reference.label||fieldLabel(reference.path)}`;
      if(reference.path)button.dataset.referencePath=reference.path;else button.dataset.referenceTarget=reference.target;
      button.setAttribute("aria-label",`定位编辑：${reference.label||fieldLabel(reference.path)}`);
      button.onclick=()=>locate(reference.path?fieldInputs.get(reference.path):$(reference.target));
      button.append(name,output);list.append(button);referenceNodes.push({reference,output});
    }
    context.append(list);return context;
  }
  const piTuning=root.querySelector(".yc-tuning");
  piTuning.querySelector("summary").textContent="PI 推荐目标与更新规则";
  const speedTargets=document.createElement("div");speedTargets.className="yc-speed-targets";
  const speedNote=document.createElement("p");speedNote.textContent="以下自定义目标与电流环共用启用开关；未启用时，更新功能按当前电机和负载选择推荐目标。";
  const speedTargetGrid=document.createElement("div");speedTargetGrid.className="yc-tuning-grid";
  for(const id of ["ycSpeedBw","ycPhaseMargin"])speedTargetGrid.append($(id).closest("label"));
  const tuningLink=document.createElement("button");tuningLink.type="button";tuningLink.className="yc-inline-link";tuningLink.textContent="定位自定义目标开关";tuningLink.onclick=()=>locate($("ycCustomTuning"));
  speedTargets.append(speedNote,speedTargetGrid,tuningLink);
  for(const [groupIndex,group] of layout.groups.entries()) {
    const detail=document.createElement("details");detail.className="panel yc-group";detail.open=common.has(group.id);detail.dataset.group=group.id;detail.id=`yc-group-${group.id}`;
    const summary=document.createElement("summary"),heading=document.createElement("strong"),count=document.createElement("span");
    heading.textContent=`${String(groupIndex+1).padStart(2,"0")}  ${group.title}`;count.className="yc-group-count";summary.append(heading,count);detail.append(summary);
    for(const [sectionIndex,section] of group.sections.entries()) {
      const part=document.createElement("section");part.className="yc-section";part.dataset.section=section.id;
      const title=document.createElement("h3");title.textContent=`${groupIndex+1}.${sectionIndex+1}  ${section.title}`;part.append(title);
      if(section.id==="current-pi")part.append(piTuning);
      if(section.id==="speed-pi")part.append(speedTargets);
      if(section.formula) {
        const formula=document.createElement("p");formula.className="yc-formula";formula.textContent=section.formula;part.append(formula);
      }
      if(section.note) {
        const note=document.createElement("p");note.className="yc-formula-note";note.textContent=section.note;part.append(note);
      }
      if(section.references.length)part.append(sharedParameters(section.references));
      if(section.id==="position-pll") {
        const targets=document.createElement("div");targets.className="yc-tuning-grid";
        targets.innerHTML='<label>允许电角度误差 / °<input id="ycPllAngleError" type="text" value="3"></label><label>允许机械转速滞后 / rad/s<input id="ycPllSpeedLag" type="text" placeholder="可选；留空不约束"></label><label class="yc-check"><input id="ycPllUseSpeedRamp" type="checkbox">采用转速指令斜坡计算加速度</label>';
        part.append(targets);
      }
      const grid=document.createElement("div");grid.className=section.paths.every(path=>isTimingHint(byPath.get(path)))?"yc-timing-constraints":"yc-field-grid";
      for(const path of section.paths)grid.append(createField(byPath.get(path)));
      part.append(grid);
      if(section.id==="platform-math") {
        const button=document.createElement("button");button.id="ycMathCmake";button.type="button";button.className="secondary-button";button.textContent="导出板级数学配置（CMake）";
        button.onclick=safe(()=>download(engine.toMathCmake(config()),`${safeFileName(values["Meta.ProfileName"]||"YMBOX")}.cmake`,"text/plain;charset=utf-8"));part.append(button);
      }
      detail.append(part);
    }
    $("ycGroups").append(detail);groupNodes.set(group.id,detail);
    const jump=document.createElement("button");jump.type="button";jump.dataset.goGroup=group.id;jump.textContent=`${String(groupIndex+1).padStart(2,"0")} ${group.title}`;
    jump.onclick=()=>{$("ycSearch").value="";filter();detail.open=true;summary.scrollIntoView({block:"start"});summary.focus({preventScroll:true});};
    $("ycGroupNav").append(jump);
  }
  function filter() {
    const query=$("ycSearch").value.trim().toLowerCase();
    for(const group of layout.groups) {
      const node=groupNodes.get(group.id),groupMatch=group.title.toLowerCase().includes(query);
      let visible=0;
      for(const part of node.querySelectorAll(".yc-section")) {
        const searchable=part.cloneNode(true);searchable.querySelectorAll("[hidden]").forEach(node=>node.remove());
        part.hidden=!!query&&!groupMatch&&!searchable.textContent.toLowerCase().includes(query);
        if(!part.hidden)visible++;
      }
      node.hidden=!visible;if(query&&visible)node.open=true;
    }
  }
  function replaceProfiles(select, profiles, placeholder, selected="") {
    select.replaceChildren(new Option(placeholder,""));
    for(const profile of profiles) select.add(new Option(profile.name,profile.name));
    if(selected&&!profiles.some(profile=>profile.name===selected)) select.add(new Option(`未找到：${selected}`,selected));
    select.value=selected;
  }
  async function refreshProfiles(preferred="") {
    const result=await window.YMBOXProfiles.list("ymbox");
    if(!result.ok) throw new Error(result.error);
    const selected=preferred||$("ycProfileSelect").value;
    replaceProfiles($("ycProfileSelect"),result.profiles,"选择方案",result.profiles.some(profile=>profile.name===selected)?selected:"");
    $("ycStoragePath").textContent=`保存目录：${result.directory}`;
  }
  async function refreshMotors() {
    const result=await window.YMBOXProfiles.list("motor");
    if(!result.ok) throw new Error(result.error);
    for(const id of ["ycMotor","ycLinkedMotor"]) replaceProfiles($(id),result.profiles,id==="ycMotor"?"选择已保存的电机":"选择电机方案",$(id).value);
    refreshBindingControls();
  }
  function updateParameters() {
    const result=engine.update(values,{sources,origins,targets:tuningTargets()});
    ({values,sources,origins}=result);refresh();showValidation(false);return result;
  }
  async function syncLinkedMotor() {
    const request=++bindingRequest,name=$("ycLinkedMotor").value;
    refreshBindingControls();
    if(!$("ycLinkEnabled").checked||!name) return null;
    linkStatus(`正在同步：${name}`);
    try {
      const loaded=await window.YMBOXProfiles.load("motor",name);
      if(request!==bindingRequest||!$("ycLinkEnabled").checked||$("ycLinkedMotor").value!==name) return null;
      if(!loaded.ok) throw new Error(loaded.error);
      const seed={...values},nextSources={...sources},nextOrigins={...origins};
      // A different/partial motor must not inherit the previous motor's facts.
      for(const path of Object.keys(nextOrigins)) if(nextOrigins[path]==="motor") {seed[path]="";nextSources[path]="";nextOrigins[path]="automatic";}
      const imported=engine.importMotor(seed,loaded.data,window.YMBOXMotorCalculator.resolveProfileData(loaded.data),name,undefined,nextOrigins);
      let synced=0;
      for(const path of Object.keys(imported.sources)) {
        seed[path]=imported.values[path];nextSources[path]=imported.sources[path];nextOrigins[path]="motor";synced++;
      }
      const result=engine.update(seed,{sources:nextSources,origins:nextOrigins,targets:tuningTargets()});
      ({values,sources,origins}=result);refresh();showValidation(false);
      linkStatus(`已绑定 ${name}：同步并锁定 ${synced} 项电机参数，保留 ${result.manualCount} 项其他手动设置`);
      return result;
    } catch(error) {
      if(request===bindingRequest) linkStatus(`电机联动失败：${error.message}`,true);
      throw error;
    }
  }
  async function saveProfile() {
    const name=$("ycProfileName").value.trim();
    if(!name) {profileStatus("请先填写 YMBOX 方案名称",true);$("ycProfileName").focus();return;}
    $("ycProfileSave").disabled=true;
    try {
      await syncLinkedMotor();
      const result=await window.YMBOXProfiles.save("ymbox",name,profileData());
      if(!result.ok) throw new Error(result.error);
      $("ycProfileName").value=result.name;await refreshProfiles(result.name);profileStatus(`已保存：${result.name}`);
    } catch(error) {profileStatus(`保存失败：${error.message}`,true);}
    finally {$("ycProfileSave").disabled=false;}
  }
  async function loadProfile(name) {
    if(!name) return;
    const request=++profileRequest;
    try {
      const result=await window.YMBOXProfiles.load("ymbox",name);
      if(request!==profileRequest) return;
      if(!result.ok) throw new Error(result.error);
      restoreProfile(result.data);$("ycProfileName").value=result.name;validating=false;$("ycValidation").hidden=true;refresh();
      await refreshMotors();
      if(request!==profileRequest) return;
      await syncLinkedMotor();if(request===profileRequest)profileStatus(`当前方案：${result.name}`);
    } catch(error) {if(request===profileRequest) profileStatus(`载入失败：${error.message}`,true);}
  }
  $("ycProfileSave").onclick=saveProfile;
  $("ycProfileName").addEventListener("keydown",event=>{if(event.key==="Enter")saveProfile();});
  $("ycProfileSelect").onchange=()=>loadProfile($("ycProfileSelect").value);
  $("ycLinkEnabled").onchange=safe(async()=>{setBinding({enabled:$("ycLinkEnabled").checked,motorProfile:$("ycLinkedMotor").value});await syncLinkedMotor();});
  $("ycLinkedMotor").onchange=safe(async()=>{await syncLinkedMotor();});
  $("ycSearch").addEventListener("input",filter);$("ycExpand").onclick=()=>groupNodes.forEach(node=>node.open=true);$("ycCollapse").onclick=()=>groupNodes.forEach((node,name)=>node.open=common.has(name));
  $("ycClear").onclick=()=>{resetProfile();values=engine.empty();sources={[dividerPath]:"模型预设值"};origins={[dividerPath]:"automatic"};restoreTuning();validating=false;$("ycValidation").hidden=true;refresh();message("已清空配置。可导入电机后点击“一键更新/补全参数”。");};
  const updateButtons=[$("ycRecommend"),$("ycFloatingRecommend")];
  async function recommendParameters() {
    if($("ycRecommend").disabled) return;
    updateButtons.forEach(button=>{button.disabled=true;button.setAttribute("aria-busy","true");});
    $("ycFloatingRecommend").querySelector("span").textContent="更新中…";floatingMessage("");
    try {
      const result=await syncLinkedMotor()||updateParameters();
      const hasPresetMotorInputs=presetMotorInputs().length>0;
      const linkedMotor=$("ycLinkEnabled").checked&&$("ycLinkedMotor").value;
      const motorNotice=hasPresetMotorInputs?(linkedMotor?"当前仍有电机基础参数采用模型预设；请补充绑定电机方案中的缺失参数，或填写页面中未锁定的参数。":"当前仍有电机基础参数采用模型预设；“一键更新”不会导入电机文件。请先点击“导入电机参数”或“导入电机 JSON”载入实际电机数据。") : "";
      message(`已更新 ${result.updatedCount} 项非手动参数，其中 ${result.changedCount} 项数值变化；保留 ${result.manualCount} 项手动设置。${motorNotice}请检查推荐依据后写入 JSON。`);
      floatingMessage(hasPresetMotorInputs?(linkedMotor?"已更新；请补充绑定电机缺失的基础参数。":"已更新；电机基础参数仍有模型预设，请先导入电机。"):`已更新 ${result.updatedCount} 项，保留 ${result.manualCount} 项手动设置`);
    } catch(error) {
      message(error.message,true);floatingMessage(`更新失败：${error.message}`,true);
    } finally {
      updateButtons.forEach(button=>{button.disabled=false;button.setAttribute("aria-busy","false");});
      $("ycFloatingRecommend").querySelector("span").textContent="一键更新";
    }
  }
  updateButtons.forEach(button=>{button.onclick=recommendParameters;});
  for(const id of ["ycCurrentBw","ycSpeedBw","ycPhaseMargin",...Object.values(pllTargetInputs)]) {$(id).inputMode="decimal";numbers.bindInput($(id));}
  for(const id of ["ycCustomTuning","ycCurrentBw","ycSpeedBw","ycPhaseMargin","ycPllUseSpeedRamp",...Object.values(pllTargetInputs)]) $(id).addEventListener("input",refreshReferences);
  function motor(data,name,sourceName) {if($("ycLinkEnabled").checked)throw new Error("已启用电机联动，请在上方更换绑定电机，或取消联动后再导入。");const resolved=window.YMBOXMotorCalculator.resolveProfileData(data),result=engine.importMotor(values,data,resolved,name,sourceName,origins);setBinding();values=result.values;sources={...sources,...result.sources};origins={...origins,...result.origins};refresh();message(`已导入 ${name} 的 ${result.filledCount} 项电机参数。点击“一键更新/补全参数”刷新其余自动参数。`);}
  $("ycImportMotor").onclick=safe(async()=>{const name=$("ycMotor").value;if(!name)throw new Error("请先选择电机参数方案");const result=await window.YMBOXProfiles.load("motor",name);if(!result.ok)throw new Error(result.error);motor(result.data,name);});
  $("ycImportMotorFile").onclick=()=>$("ycMotorFile").click();$("ycMotorFile").onchange=safe(async()=>{const file=$("ycMotorFile").files[0];if(!file)return;try{const doc=JSON.parse(await file.text());if(doc.kind&&doc.kind!=="motor")throw new Error("请选择电机参数 JSON");motor(doc.data||doc,doc.name||file.name.replace(/\.json$/i,""),`文件：${file.name}`);}finally{$("ycMotorFile").value="";}});
  $("ycImport").onclick=()=>$("ycFile").click();$("ycFile").onchange=safe(async()=>{const file=$("ycFile").files[0];if(!file)return;try{const doc=JSON.parse(await file.text()),imported=engine.importState(doc,`配置文件：${file.name}`);resetProfile();({values,sources,origins}=imported);restoreTuning(imported.targets);refresh();showValidation(false);message("配置已导入页面，手动与自动来源已恢复。可点击“一键更新/补全参数”后写入 JSON。");}finally{$("ycFile").value="";}});
  function safeFileName(name) {return String(name).replace(/[<>:"/\\|?*\u0000-\u001f]/g,"_");}
  function download(text,fileName,type) {const blob=new Blob([text],{type}),url=URL.createObjectURL(blob),a=document.createElement("a");a.href=url;a.download=fileName;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
  $("ycExport").onclick=safe(()=>download(JSON.stringify(config(),null,2),`${safeFileName(values["Meta.ProfileName"]||"YMBOX")}.json`,"application/json"));$("ycValidate").onclick=()=>showValidation();
  const token=new URLSearchParams(location.search).get("ymboxToken");
  async function api(path,options={}) {
    if(nativeApi){const data=await nativeApi.configuration_request(path,options.body?JSON.parse(options.body):null);if(data.error)throw new Error(data.error);return data;}
    const response=await fetch(`/api/ymbox/${path}`,{...options,headers:{"X-YMBOX-Token":token||"","Content-Type":"application/json",...options.headers}});const data=await response.json();if(!response.ok)throw new Error(data.error||"本地服务请求失败");return data;
  }
  function directCodegenCapability() {
    if(service?.directCodegenAvailable!==true) return {available:false,reason:service?.directCodegenUnavailableReason||"本地服务未提供直接代码生成"};
    if(service?.recalculationEvidenceRequired!==true) return {available:false,reason:"本地服务未启用前端重算证据校验"};
    if(service?.recalculationEngineRevision!==engine.recalculationRevision) return {available:false,reason:"配置工具与本地代码生成服务的重算版本不一致，请刷新或重启工具"};
    return {available:true,reason:""};
  }
  function refreshDirectCodegenControl() {
    const button=$("ycGenerateCode"),capability=directCodegenCapability();
    button.disabled=directCodegenRunning||!capability.available;
    button.title=capability.reason;
  }
  async function sha256Hex(text) {
    if(!window.crypto?.subtle||!window.TextEncoder) throw new Error("当前浏览器不支持生成代码所需的 SHA-256 校验");
    const digest=await window.crypto.subtle.digest("SHA-256",new TextEncoder().encode(text));
    return [...new Uint8Array(digest)].map(value=>value.toString(16).padStart(2,"0")).join("");
  }
  async function connect() {
    $("ycApply").disabled=true;refreshDirectCodegenControl();
    if(!token){await new Promise(resolve=>setTimeout(resolve,600));if(window.pywebview?.api?.configuration_request)nativeApi=window.pywebview.api;}
    if(nativeApi||(location.protocol!=="file:"&&token)){try{service=await api("status");}catch(error){message(error.message,true);}}
    const modelFound=service?.jsonOnly===true&&service?.destinationPolicy==="detected-model-or-download"&&service?.modelFound===true;
    $("ycCurrent").disabled=!modelFound;$("ycApply").disabled=false;refreshDirectCodegenControl();
    $("ycConnection").textContent=modelFound?"已定位 YMBOX 模型目录；一键写入将直接更新模型使用的活动 JSON。":service?.jsonOnly===true&&service?.destinationPolicy==="detected-model-or-download"?"未找到 YMBOX 模型目录；一键写入时将导出 YMBOX_ActiveConfiguration.json。":service?"当前服务版本较旧，请重新运行“启动YMBOX配置工具.pyw”；本页只允许下载 JSON。":"未连接本地写入服务；无法定位模型目录，一键写入时将导出 JSON。";
  }
  $("ycCurrent").onclick=safe(async()=>{const doc=await api("current"),imported=engine.importState(doc,"已写入配置");resetProfile();({values,sources,origins}=imported);restoreTuning(imported.targets);refresh();message("已载入保存的配置及参数来源；文件保存状态不代表模型验证结果。");});
  $("ycApply").onclick=safe(async()=>{
    const document=config();if(service?.jsonOnly!==true||service?.destinationPolicy!=="detected-model-or-download"||service?.modelFound!==true){download(JSON.stringify(document,null,2),"YMBOX_ActiveConfiguration.json","application/json");message("未找到可直接写入的 YMBOX 模型目录，已导出 YMBOX_ActiveConfiguration.json。请放入模型的 ProjectConfiguration/ApplicationParameters 目录；尚未执行模型验证。");return;}
    const submittedRevision=revision;$("ycApply").disabled=true;
    try{message("正在写入模型目录中的 JSON 参数文件…");const result=await api("apply",{method:"POST",body:JSON.stringify({configuration:document})});if(result.state==="model-not-found"){service={...service,modelFound:false,modelRoot:null,activeFile:null};download(JSON.stringify(document,null,2),"YMBOX_ActiveConfiguration.json","application/json");message("写入前未能重新定位 YMBOX 模型目录，已改为导出 YMBOX_ActiveConfiguration.json；尚未执行模型验证。");return;}if(result.state!=="written"||!result.report?.Written)throw new Error(`参数写入失败：${result.error||"未收到文件写入结果"}`);message(`已直接写入模型配置：${result.report.ActiveFile}。${submittedRevision===revision?"下次模型更新/仿真会读取此配置。":"本次保存的是点击时的配置，页面随后发生的修改尚未写入。"}`);}finally{$("ycApply").disabled=false;}
  });
  $("ycGenerateCode").onclick=async()=>{
    const capability=directCodegenCapability();
    if(!capability.available) {message(`无法直接生成代码：${capability.reason}`,true);return;}
    const clickedRevision=revision;
    $("ycGenerateCode").dataset.clickedRevision=String(clickedRevision);
    directCodegenRunning=true;refreshDirectCodegenControl();$("ycGenerateCode").setAttribute("aria-busy","true");
    try {
      message("正在按当前控制频率重算参数并生成代码…");
      const linkedMotorExpected=$("ycLinkEnabled").checked&&Boolean($("ycLinkedMotor").value);
      const synchronized=await syncLinkedMotor();
      if(linkedMotorExpected&&!synchronized) throw new Error("联动电机在生成前发生变化，请重试");
      if(!synchronized) updateParameters();
      const options={mode:"direct-codegen"},checked=showValidation(false,options);
      if(!checked.ok) throw new Error(`${checked.issues.length} 项参数未通过校验：${checked.issues[0].path} ${checked.issues[0].message}`);
      const document=engine.exportDocument(values,sources,origins,tuningTargets(),options),configurationJson=JSON.stringify(document);
      const submittedRevision=revision;
      $("ycGenerateCode").dataset.submittedRevision=String(submittedRevision);
      const recalculationEvidence={
        schemaVersion:1,
        engineRevision:engine.recalculationRevision,
        controlFrequency_Hz:document.drive.Timing.ControlFrequency_Hz,
        configurationJson,
        configurationSha256:await sha256Hex(configurationJson),
        automaticFieldCount:Object.values(document.parameterOrigins).filter(origin=>origin==="automatic").length
      };
      const result=await api("generate",{method:"POST",body:JSON.stringify({configuration:document,recalculationEvidence,simulate:false})});
      if(result.state!=="generated"||result.report?.CodeBuildPassed!==true) throw new Error(result.error||"代码生成未返回成功报告");
      const separator=String(result.outputDirectory||"").includes("\\")?"\\":"/";
      const reportFile=result.reportFile||result.ReportFile||result.report?.reportFile||result.report?.ReportFile||`${result.outputDirectory}${separator}YMBOX_CodeGenerationReport.json`;
      const changedAfterSubmission=revision!==submittedRevision;
      message(`代码生成完成。输出目录：${result.outputDirectory}；报告文件：${reportFile}${changedAfterSubmission?"；页面在提交后已修改，本次生成使用提交时快照。":""}`);
    } catch(error) {
      message(`不仿真代码生成失败：${error.message}`,true);
    } finally {
      directCodegenRunning=false;$("ycGenerateCode").setAttribute("aria-busy","false");refreshDirectCodegenControl();
    }
  };
  refresh();safe(async()=>{await Promise.all([refreshProfiles(),refreshMotors()]);await syncLinkedMotor();})();connect();
  window.addEventListener("ymbox:profile-saved",event=>safe(async()=>{
    if(event.detail?.kind==="ymbox") await refreshProfiles();
    if(event.detail?.kind==="motor") {await refreshMotors();if(event.detail.name===$("ycLinkedMotor").value)await syncLinkedMotor();}
  })());
  window.addEventListener("hashchange",()=>{if(location.hash==="#/ymbox-configuration")safe(async()=>{await refreshMotors();await syncLinkedMotor();})();});
  window.YMBOXUI=Object.freeze({getDocument:()=>engine.exportDocument(values,sources,origins,tuningTargets()),getValues:()=>({...values}),getProfileData:profileData});
})();
