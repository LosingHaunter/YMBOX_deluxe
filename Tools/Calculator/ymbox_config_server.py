"""Local YMBOX UI, JSON writer and isolated direct-codegen launcher."""
from __future__ import annotations

import argparse
import functools
import hashlib
import json
import math
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys
import threading
import webbrowser
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from profile_store import ProfileStore
from configuration_file import read_configuration, validate_document, write_configuration

UI_ROOT = Path(__file__).resolve().parent
MODEL_ROOT_MARKERS = ("YMBOX_Control_Core.slx", "YMBOX_Deluxe_sim.slx")
DESTINATION_POLICY = "detected-model-or-download"
_AUTO_DESTINATION = object()
RECALCULATION_ENGINE_REVISION = "YMBOXConfigEngine/recalculate-v1"
RECALCULATION_EVIDENCE_FIELDS = {
    "schemaVersion", "engineRevision", "controlFrequency_Hz",
    "configurationJson", "configurationSha256", "automaticFieldCount",
}


class CodeGenerationError(RuntimeError):
    """Raised when a fresh MATLAB direct-codegen process does not succeed."""


def is_model_root(folder: Path) -> bool:
    """Return true only for the YMBOX folder that owns the model files."""
    try:
        root = Path(folder).resolve()
        return root.is_dir() and all((root / marker).is_file() for marker in MODEL_ROOT_MARKERS)
    except (OSError, RuntimeError):
        return False


def find_model_root(candidates=None) -> Path | None:
    """Find a YMBOX model root among explicit locations and their parents."""
    configured = os.environ.get("YMBOX_MODEL_ROOT")
    starts = ([Path(configured)] if configured else []) + list(candidates or (
        UI_ROOT,
        Path.cwd(),
        Path(sys.executable).resolve().parent,
    ))
    visited = set()
    for start in starts:
        try:
            resolved = Path(start).resolve()
        except (OSError, RuntimeError):
            continue
        if resolved.is_file():
            resolved = resolved.parent
        for folder in (resolved, *resolved.parents):
            key = os.path.normcase(str(folder))
            if key in visited:
                continue
            visited.add(key)
            if is_model_root(folder):
                return folder
    return None


MODEL_ROOT = find_model_root()
OUTPUT_ROOT = MODEL_ROOT.parent / (MODEL_ROOT.name + "_outputs") if MODEL_ROOT else None
ACTIVE_FILE = MODEL_ROOT / "ProjectConfiguration/ApplicationParameters/YMBOX_ActiveConfiguration.json" if MODEL_ROOT else None


def current_configuration(active_file):
    if active_file is None:
        raise ValueError("未找到 YMBOX 模型目录，只能导出 JSON")
    if not active_file.is_file():
        raise ValueError("尚未写入计算器配置，请先点击“一键写入模型”")
    doc = read_configuration(active_file)
    doc["active"] = True
    return doc


class ConfigurationJobs:
    def __init__(self, active_file=_AUTO_DESTINATION, output_root=OUTPUT_ROOT,
                 model_root=None):
        self.job_lock = threading.Lock()
        self.automatic_destination = active_file is _AUTO_DESTINATION
        self.automatic_output_root = output_root is None
        self.model_root = Path(model_root).resolve() if model_root is not None else None
        self.output_root = Path(output_root).resolve() if output_root is not None else None
        self.active_file = None
        if self.automatic_destination:
            self._refresh_destination()
        elif active_file is not None:
            self.active_file = Path(active_file).resolve()
            if (self.model_root is None
                    and self.active_file.parent.name == "ApplicationParameters"
                    and self.active_file.parent.parent.name == "ProjectConfiguration"):
                self.model_root = self.active_file.parent.parent.parent
        if self.output_root is None and self.model_root is not None:
            self.output_root = self.model_root.parent / (self.model_root.name + "_outputs")
        self.schema = json.loads((UI_ROOT / "ymbox-config-schema.json").read_text(encoding="utf-8"))

    def _refresh_destination(self):
        if not self.automatic_destination:
            return
        self.model_root = find_model_root()
        self.active_file = (self.model_root / "ProjectConfiguration/ApplicationParameters/YMBOX_ActiveConfiguration.json"
                            if self.model_root else None)
        if self.automatic_output_root:
            self.output_root = (self.model_root.parent / (self.model_root.name + "_outputs")
                                if self.model_root else None)

    def status(self):
        self._refresh_destination()
        model_found = self.active_file is not None
        direct_codegen_available, unavailable_reason = self._direct_codegen_availability()
        return {"writeOnly": True, "jsonOnly": True, "matlabRequired": False,
                "directCodegen": True, "matlabRequiredForGeneration": True,
                "directCodegenAvailable": direct_codegen_available,
                "directCodegenUnavailableReason": unavailable_reason,
                "recalculationEvidenceRequired": True,
                "recalculationEngineRevision": RECALCULATION_ENGINE_REVISION,
                "profileStorage": True,
                "configurationSource": "calculator-json", "destinationPolicy": DESTINATION_POLICY,
                "modelFound": model_found, "modelRoot": str(self.model_root) if self.model_root else None,
                "active": model_found and self.active_file.is_file(),
                "activeFile": str(self.active_file) if self.active_file else None,
                "outputRoot": str(self.output_root) if self.output_root else None}

    def _direct_codegen_availability(self) -> tuple[bool, str | None]:
        if self.model_root is None:
            return False, "未找到 YMBOX 模型目录"
        required = ("YMBOX_Deluxe_code.slx", "YMBOX_Control_Core.slx",
                    "YMBOX_GenerateCodeOnly.m")
        missing = [name for name in required if not (self.model_root / name).is_file()]
        if missing:
            return False, "缺少直接代码生成文件：" + "、".join(missing)
        try:
            self._matlab_executable()
        except CodeGenerationError as error:
            return False, str(error)
        return True, None

    def current(self):
        self._refresh_destination()
        return current_configuration(self.active_file)

    def start_job(self, payload):
        if not isinstance(payload, dict):
            raise ValueError("请求应为 JSON 对象")
        if payload.get("buildCode", False) is not False:
            raise ValueError("当前仅写入 JSON 参数文件，不支持在写入时生成代码")
        self._refresh_destination()
        if self.active_file is None:
            return {"state": "model-not-found", "report": {"Written": False}}
        if not self.job_lock.acquire(blocking=False):
            raise ValueError("已有参数写入正在执行，请稍后重试")
        try:
            report = write_configuration(payload.get("configuration"), self.active_file, self.schema)
            return {"state": "written", "report": report}
        finally:
            self.job_lock.release()

    @staticmethod
    def _matlab_literal(value: Path) -> str:
        return str(Path(value).resolve()).replace("'", "''")

    def _matlab_executable(self) -> str:
        configured = os.environ.get("YMBOX_MATLAB_EXECUTABLE")
        if configured:
            executable = shutil.which(configured) or str(Path(configured).resolve())
            if Path(executable).is_file():
                return executable
            raise CodeGenerationError(f"找不到 MATLAB 可执行文件：{configured}")
        executable = shutil.which("matlab")
        if not executable:
            raise CodeGenerationError("找不到 MATLAB，可设置 YMBOX_MATLAB_EXECUTABLE")
        return executable

    def _write_batch_script(self, job_dir: Path, configuration_file: Path,
                            report_file: Path) -> Path:
        script_file = job_dir / "YMBOX_DirectCodegenBatch.m"
        model_root = self._matlab_literal(self.model_root)
        configuration = self._matlab_literal(configuration_file)
        output = self._matlab_literal(job_dir)
        report = self._matlab_literal(report_file)
        script = ("clearvars;\n"
                  f"addpath('{model_root}');\n"
                  f"YMBOX_GenerateCodeOnly('{configuration}', "
                  f"'OutputRoot', '{output}', 'ReportFile', '{report}', "
                  "'AllowUnreleasedControlFrequency', true);\n")
        temporary = script_file.with_suffix(".m.tmp")
        try:
            temporary.write_text(script, encoding="utf-8", newline="\n")
            os.replace(temporary, script_file)
        finally:
            temporary.unlink(missing_ok=True)
        return script_file

    def _validate_recalculation_evidence(self, configuration: dict,
                                         evidence) -> dict:
        if not isinstance(evidence, dict) or set(evidence) != RECALCULATION_EVIDENCE_FIELDS:
            raise ValueError("直接代码生成需要当前配置的完整前端重算证据")
        if (type(evidence["schemaVersion"]) is not int
                or evidence["schemaVersion"] != 1
                or evidence["engineRevision"] != RECALCULATION_ENGINE_REVISION):
            raise ValueError("前端参数重算版本不受支持，请刷新配置工具后重试")
        frequency = evidence["controlFrequency_Hz"]
        expected_frequency = configuration["drive"]["Timing"]["ControlFrequency_Hz"]
        if (type(frequency) not in (int, float) or not math.isfinite(frequency)
                or frequency != expected_frequency):
            raise ValueError("参数重算证据与当前控制频率不一致")
        configuration_json = evidence["configurationJson"]
        digest = evidence["configurationSha256"]
        if not isinstance(configuration_json, str) or not configuration_json:
            raise ValueError("参数重算证据缺少最终配置快照")
        if (not isinstance(digest, str) or len(digest) != 64
                or any(character not in "0123456789abcdef" for character in digest)):
            raise ValueError("参数重算证据的 SHA-256 格式无效")
        actual_digest = hashlib.sha256(configuration_json.encode("utf-8")).hexdigest()
        if not secrets.compare_digest(digest, actual_digest):
            raise ValueError("参数重算证据的配置摘要不匹配")
        try:
            snapshot = json.loads(configuration_json)
        except json.JSONDecodeError as error:
            raise ValueError("参数重算证据的配置快照不是有效 JSON") from error
        if snapshot != configuration:
            raise ValueError("参数重算证据不是针对当前提交配置生成的")
        origins = configuration.get("parameterOrigins")
        expected_paths = {field["path"] for field in self.schema["fields"]}
        if not isinstance(origins, dict) or set(origins) != expected_paths:
            raise ValueError("直接代码生成需要所有参数的来源信息，请先执行一键更新")
        automatic_count = sum(value == "automatic" for value in origins.values())
        if (type(evidence["automaticFieldCount"]) is not int
                or evidence["automaticFieldCount"] != automatic_count):
            raise ValueError("参数重算证据的自动参数数量不匹配")
        return {
            "Verified": True,
            "SchemaVersion": 1,
            "EngineRevision": RECALCULATION_ENGINE_REVISION,
            "ControlFrequency_Hz": frequency,
            "ConfigurationSha256": digest,
            "AutomaticFieldCount": automatic_count,
        }

    def _build_matlab_command(self, batch_script: Path) -> list[str]:
        expression = f"run('{self._matlab_literal(batch_script)}')"
        return [self._matlab_executable(), "-batch", expression]

    def _run_matlab_generation(self, command: list[str], job_dir: Path,
                               report_file: Path) -> dict:
        log_file = job_dir / "matlab.log"
        try:
            completed = subprocess.run(
                command,
                cwd=self.model_root,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=30 * 60,
                check=False,
                shell=False,
            )
            log_file.write_text(
                (completed.stdout or "") + (completed.stderr or ""),
                encoding="utf-8",
            )
        except subprocess.TimeoutExpired as error:
            output = ((error.stdout or "") + (error.stderr or ""))
            log_file.write_text(str(output), encoding="utf-8")
            raise CodeGenerationError("MATLAB 直接代码生成超时，详情见 matlab.log") from error
        except OSError as error:
            raise CodeGenerationError(f"无法启动 MATLAB：{error}") from error
        if completed.returncode != 0:
            raise CodeGenerationError(
                f"MATLAB 直接代码生成失败（退出码 {completed.returncode}），详情见 matlab.log")
        if not report_file.is_file():
            raise CodeGenerationError("MATLAB 未生成代码生成报告，详情见 matlab.log")
        try:
            report = json.loads(report_file.read_text(encoding="utf-8-sig"))
        except (OSError, json.JSONDecodeError) as error:
            raise CodeGenerationError(f"无法读取 MATLAB 代码生成报告：{error}") from error
        if not isinstance(report, dict) or report.get("Passed") is not True:
            raise CodeGenerationError("MATLAB 代码生成报告未通过")
        return report

    def generate(self, payload):
        if not isinstance(payload, dict):
            raise ValueError("请求应为 JSON 对象")
        if payload.get("simulate", False) is not False:
            raise ValueError("直接代码生成不允许启动仿真")
        configuration = payload.get("configuration")
        validate_document(configuration, self.schema)
        evidence_summary = self._validate_recalculation_evidence(
            configuration, payload.get("recalculationEvidence"))
        self._refresh_destination()
        if self.model_root is None or self.output_root is None:
            return {"state": "model-not-found", "report": {"CodeBuildPassed": False}}
        required = ("YMBOX_Deluxe_code.slx", "YMBOX_Control_Core.slx",
                    "YMBOX_GenerateCodeOnly.m")
        if not all((self.model_root / name).is_file() for name in required):
            raise CodeGenerationError("YMBOX 模型目录缺少直接代码生成入口或代码模型")
        if not self.job_lock.acquire(blocking=False):
            raise ValueError("已有参数写入或代码生成正在执行，请稍后重试")
        try:
            job_id = (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ-")
                      + secrets.token_hex(4))
            job_dir = self.output_root / "direct-codegen" / job_id
            job_dir.mkdir(parents=True, exist_ok=False)
            configuration_file = job_dir / "YMBOX_GenerationConfiguration.json"
            report_file = job_dir / "YMBOX_CodeGenerationReport.json"
            write_configuration(configuration, configuration_file, self.schema)
            evidence_file = job_dir / "YMBOX_RecalculationEvidence.json"
            evidence_file.write_text(
                json.dumps(evidence_summary, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            batch_script = self._write_batch_script(
                job_dir, configuration_file, report_file)
            command = self._build_matlab_command(batch_script)
            (job_dir / "launch.json").write_text(
                json.dumps({"executable": command[0], "arguments": command[1:]},
                           ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            report = self._run_matlab_generation(command, job_dir, report_file)
            report["RecalculationEvidence"] = evidence_summary
            report_file.write_text(
                json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            return {"state": "generated", "jobId": job_id,
                    "outputDirectory": str(job_dir), "report": report}
        finally:
            self.job_lock.release()


class ConfigurationServer(ConfigurationJobs, ThreadingHTTPServer):
    daemon_threads = True
    # Windows can otherwise let multiple services bind the same local port.
    allow_reuse_address = False

    def __init__(self, port=18743, active_file=_AUTO_DESTINATION,
                 output_root=OUTPUT_ROOT, model_root=None):
        ConfigurationJobs.__init__(self, active_file, output_root, model_root)
        self.token = secrets.token_urlsafe(32)
        self.profiles = ProfileStore()
        ThreadingHTTPServer.__init__(self, ("127.0.0.1", port), functools.partial(Handler, directory=str(UI_ROOT)))


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        # Do not log the local session token from the page URL.
        pass

    def send_json(self, status, value):
        body = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def authorized(self):
        expected_host = f"127.0.0.1:{self.server.server_port}"
        origin = self.headers.get("Origin")
        return (self.headers.get("Host") == expected_host
                and (origin is None or origin == f"http://{expected_host}")
                and secrets.compare_digest(self.headers.get("X-YMBOX-Token", ""), self.server.token))

    def do_GET(self):
        path = urlsplit(self.path).path
        if path.startswith("/api/ymbox/"):
            if not self.authorized():
                return self.send_json(403, {"error": "本地会话验证失败，请从启动入口重新打开"})
            if path == "/api/ymbox/status":
                return self.send_json(200, self.server.status())
            if path == "/api/ymbox/current":
                try:
                    return self.send_json(200, self.server.current())
                except (ValueError, OSError) as error:
                    return self.send_json(400, {"error": str(error)})
            return self.send_json(404, {"error": "未知接口"})
        target = Path(self.translate_path(self.path)).resolve()
        if not target.is_relative_to(UI_ROOT) or target.is_dir():
            return self.send_error(403)
        super().do_GET()

    def do_POST(self):
        if not self.authorized():
            return self.send_json(403, {"error": "本地会话验证失败"})
        route = urlsplit(self.path).path
        profile_actions = {
            "/api/profiles/list": lambda data: self.server.profiles.list_profiles(data["kind"]),
            "/api/profiles/load": lambda data: self.server.profiles.load_profile(data["kind"], data["name"]),
            "/api/profiles/save": lambda data: self.server.profiles.save_profile(data["kind"], data["name"], data["data"]),
            "/api/profiles/info": lambda data: self.server.profiles.get_storage_info(),
        }
        ymbox_actions = {
            "/api/ymbox/apply": self.server.start_job,
            "/api/ymbox/generate": self.server.generate,
        }
        if route not in ymbox_actions and route not in profile_actions:
            return self.send_json(404, {"error": "未知接口"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 512000:
                raise ValueError("配置文件大小无效")
            payload = json.loads(self.rfile.read(length))
            if not isinstance(payload, dict):
                raise ValueError("请求应为 JSON 对象")
            if route in profile_actions:
                self.send_json(200, profile_actions[route](payload))
            else:
                self.send_json(200, ymbox_actions[route](payload))
        except (ValueError, TypeError, KeyError) as error:
            self.send_json(400, {"error": str(error)})
        except OSError as error:
            self.send_json(500, {"error": f"参数文件写入失败：{error}"})
        except CodeGenerationError as error:
            self.send_json(500, {"error": str(error)})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18743)
    parser.add_argument("--no-browser", action="store_true")
    parser.add_argument("--connection-file", type=Path)
    args = parser.parse_args()
    marker = args.connection_file or (UI_ROOT / "YMBOX_Data/.configuration-service.json")
    if not args.connection_file and marker.exists():
        try:
            previous = json.loads(marker.read_text(encoding="utf-8"))
            port, token = int(previous["port"]), previous["token"]
            if not 1 <= port <= 65535 or not isinstance(token, str):
                raise ValueError("Invalid local service information")
            origin = f"http://127.0.0.1:{port}"
            with urlopen(Request(origin + "/api/ymbox/status", headers={"X-YMBOX-Token": token}), timeout=2) as response:
                if response.status != 200:
                    raise ValueError("Local service is unavailable")
                status = json.load(response)
                if (not status.get("profileStorage") or status.get("writeOnly") is not True
                        or status.get("jsonOnly") is not True
                        or status.get("directCodegen") is not True
                        or status.get("configurationSource") != "calculator-json"
                        or status.get("destinationPolicy") != DESTINATION_POLICY):
                    raise ValueError("An updated file-writing service is required")
            if not args.no_browser:
                webbrowser.open(f"{origin}/index.html?ymboxToken={token}#/ymbox-configuration")
            return
        except (OSError, ValueError, KeyError, TypeError):
            pass
    try:
        server = ConfigurationServer(args.port)
    except OSError:
        server = ConfigurationServer(0)
    url = f"http://127.0.0.1:{server.server_port}/index.html?ymboxToken={server.token}#/ymbox-configuration"
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text(json.dumps({"url": url, "token": server.token, "port": server.server_port, "pid": os.getpid()}), encoding="utf-8")
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
