"""Read and atomically write the active YMBOX JSON configuration."""
from __future__ import annotations

import json
import math
import os
from pathlib import Path
import re
import tempfile


def read_configuration(path: Path) -> dict:
    if path.suffix.lower() != ".json":
        raise ValueError("仅支持 JSON 配置文件")
    text = path.read_text(encoding="utf-8-sig")
    return json.loads(text)


def validate_document(document: dict, schema: dict) -> None:
    if (not isinstance(document, dict) or type(document.get("schemaVersion")) is not int
            or document["schemaVersion"] != 1 or document.get("kind") != "YMBOXConfiguration"):
        raise ValueError("请选择由当前工具导出的完整配置")
    drive = document.get("drive")
    defaults = schema["defaults"]
    if not isinstance(drive, dict) or set(drive) != set(defaults):
        raise ValueError("配置分组不完整或包含未知分组")
    for group, values in defaults.items():
        if not isinstance(drive[group], dict) or set(drive[group]) != set(values):
            raise ValueError(f"{group} 参数不完整或包含未知字段")
    for field in schema["fields"]:
        group, name = field["path"].split(".")
        value = drive[group][name]
        kind = field["type"]
        if kind == "char":
            valid = isinstance(value, str)
        elif kind == "logical":
            valid = type(value) is bool
        else:
            count = math.prod(field["shape"])
            values = value if isinstance(value, list) else [value]
            valid = (len(values) == count and (isinstance(value, list) == (count != 1))
                     and all(type(item) in (int, float) and math.isfinite(item) for item in values))
            if valid and kind.startswith(("uint", "int")):
                bits = int(re.search(r"\d+", kind).group(0))
                low = 0 if kind.startswith("u") else -(2 ** (bits - 1))
                high = 2 ** (bits if kind.startswith("u") else bits - 1) - 1
                valid = all(item == int(item) and low <= item <= high for item in values)
        if not valid:
            raise ValueError(f"{field['path']} 的类型、形状或数值无效")
        if field.get("readOnly") and value != field["defaultValue"]:
            raise ValueError(f"{field['path']} 是固定参数，不能修改")
        if field["path"] == "Timing.MDTMTaskDivider_NULL" and value < 1:
            raise ValueError("Timing.MDTMTaskDivider_NULL 须为正整数")
    # Also reject nonfinite numbers anywhere in metadata before writing.
    json.dumps(document, allow_nan=False)


def write_configuration(document: dict, active_file: Path, schema: dict) -> dict:
    validate_document(document, schema)
    if active_file.suffix.lower() != ".json":
        raise ValueError("活动配置必须使用 .json 文件")
    text = json.dumps(document, ensure_ascii=False, allow_nan=False, indent=2) + "\n"
    active_file.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                                         prefix=".ymbox-config-", suffix=".json.tmp",
                                         dir=active_file.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, active_file)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return {"Written": True, "ActiveFile": str(active_file),
            "BackupsCreated": False,
            "MatlabStarted": False, "ModelUpdatesPassed": False, "CodeBuildPassed": False,
            "ModelValidation": "pending", "ProfileName": document["drive"]["Meta"]["ProfileName"]}
