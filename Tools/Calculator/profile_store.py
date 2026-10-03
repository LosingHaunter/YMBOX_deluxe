"""Shared disk storage for motor, PI and YMBOX configuration profiles."""
import json
import os
import re
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path


class ProfileStore:
    VALID_KINDS = {"motor", "pi", "ymbox"}

    def __init__(self) -> None:
        configured_dir = os.environ.get("YMBOX_PROFILE_DIR")
        if configured_dir:
            self.base_dir = Path(configured_dir)
        else:
            app_dir = Path(sys.executable).resolve().parent if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
            self.base_dir = app_dir / "YMBOX_Data" / "Profiles"
        self.lock = threading.Lock()
        self.configuration_jobs = None

    def configuration_request(self, route: str, payload=None) -> dict:
        from ymbox_config_server import ConfigurationJobs
        try:
            with self.lock:
                if self.configuration_jobs is None:
                    self.configuration_jobs = ConfigurationJobs()
            manager = self.configuration_jobs
            if route == "status":
                return manager.status()
            if route == "current":
                return manager.current()
            if route == "apply":
                return manager.start_job(payload)
            if route == "generate":
                return manager.generate(payload)
            return {"error": "未知配置接口"}
        except Exception as error:
            return {"error": str(error)}

    def _ensure_base_dir(self) -> Path:
        self.base_dir.mkdir(parents=True, exist_ok=True)
        return self.base_dir

    def _kind_dir(self, kind: str) -> Path:
        if kind not in self.VALID_KINDS:
            raise ValueError("Unsupported profile kind.")
        directory = self._ensure_base_dir() / kind
        directory.mkdir(parents=True, exist_ok=True)
        return directory

    @staticmethod
    def _safe_name(name: str) -> str:
        clean = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", str(name)).strip().rstrip(". ")
        clean = re.sub(r"\s+", " ", clean)[:80]
        if not clean:
            raise ValueError("Profile name cannot be empty.")
        if clean.upper() in {"CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "LPT1", "LPT2", "LPT3", "LPT4"}:
            clean = f"_{clean}"
        return clean

    def save_profile(self, kind: str, name: str, data: dict) -> dict:
        try:
            if not isinstance(data, dict):
                raise ValueError("Profile data must be a JSON object.")
            safe_name = self._safe_name(name)
            directory = self._kind_dir(kind)
            path = directory / f"{safe_name}.json"
            payload = {
                "schemaVersion": 1,
                "kind": kind,
                "name": safe_name,
                "updatedAt": datetime.now(timezone.utc).isoformat(),
                "data": data,
            }
            temp_path = path.with_suffix(".json.tmp")
            with self.lock:
                try:
                    temp_path.write_text(
                        json.dumps(payload, ensure_ascii=False, allow_nan=False, indent=2) + "\n",
                        encoding="utf-8",
                    )
                    os.replace(temp_path, path)
                finally:
                    temp_path.unlink(missing_ok=True)
            return {"ok": True, "name": safe_name, "path": str(path)}
        except Exception as exc:
            return {"ok": False, "error": str(exc)}

    def list_profiles(self, kind: str) -> dict:
        try:
            directory = self._kind_dir(kind)
            profiles = []
            for path in directory.glob("*.json"):
                try:
                    payload = json.loads(path.read_text(encoding="utf-8"))
                    if (payload.get("schemaVersion") != 1 or payload.get("kind") != kind
                            or not isinstance(payload.get("data"), dict)):
                        continue
                    profiles.append({
                        "name": payload.get("name", path.stem),
                        "updatedAt": payload.get("updatedAt", ""),
                    })
                except (OSError, json.JSONDecodeError):
                    continue
            profiles.sort(key=lambda item: (item["updatedAt"], item["name"]), reverse=True)
            return {"ok": True, "profiles": profiles, "directory": str(directory)}
        except Exception as exc:
            return {"ok": False, "error": str(exc), "profiles": []}

    def load_profile(self, kind: str, name: str) -> dict:
        try:
            safe_name = self._safe_name(name)
            path = self._kind_dir(kind) / f"{safe_name}.json"
            payload = json.loads(path.read_text(encoding="utf-8"))
            if payload.get("schemaVersion") != 1 or payload.get("kind") != kind:
                raise ValueError("Profile type does not match.")
            if not isinstance(payload.get("data"), dict):
                raise ValueError("Profile data must be a JSON object.")
            return {"ok": True, "name": payload.get("name", safe_name), "data": payload.get("data", {})}
        except Exception as exc:
            return {"ok": False, "error": str(exc)}

    def get_storage_info(self) -> dict:
        try:
            directory = self._ensure_base_dir()
            return {"ok": True, "directory": str(directory)}
        except Exception as exc:
            return {"ok": False, "error": str(exc)}

