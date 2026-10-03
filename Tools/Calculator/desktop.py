import json
import ctypes
import os
import re
import sys
import threading
import time
from datetime import datetime, timezone
from ctypes import wintypes
from pathlib import Path

import webview


WINDOW_ICON_HANDLES = []
APP_USER_MODEL_ID = "YMBOX.EngineeringToolbox"


from profile_store import ProfileStore


def asset_path(filename: str) -> Path:
    bundle_dir = Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parent))
    return bundle_dir / filename


def configure_windows_app_identity() -> None:
    if sys.platform == "win32":
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(APP_USER_MODEL_ID)


def apply_windows_taskbar_icon(window: webview.Window, icon_path: str) -> None:
    if sys.platform != "win32":
        return
    if not window.events.shown.wait(10):
        raise TimeoutError("The application window did not appear in time.")

    hwnd = int(window.native.Handle.ToInt64())
    user32 = ctypes.windll.user32
    load_image = user32.LoadImageW
    load_image.argtypes = [
        wintypes.HINSTANCE,
        wintypes.LPCWSTR,
        wintypes.UINT,
        ctypes.c_int,
        ctypes.c_int,
        wintypes.UINT,
    ]
    load_image.restype = ctypes.c_void_p
    send_message = user32.SendMessageW
    send_message.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
    send_message.restype = wintypes.LPARAM

    image_icon = 1
    load_from_file = 0x0010
    wm_seticon = 0x0080
    icon_small = 0
    icon_big = 1

    big_icon = load_image(None, icon_path, image_icon, 256, 256, load_from_file)
    small_icon = load_image(None, icon_path, image_icon, 32, 32, load_from_file)
    if not big_icon or not small_icon:
        raise OSError(f"Unable to load the application icon: {icon_path}")

    WINDOW_ICON_HANDLES.extend((big_icon, small_icon))
    send_message(hwnd, wm_seticon, icon_big, big_icon)
    send_message(hwnd, wm_seticon, icon_small, small_icon)


def initialize_window(window: webview.Window, icon_path: str, smoke_marker: str | None) -> None:
    apply_windows_taskbar_icon(window, icon_path)
    if smoke_marker:
        run_smoke_test(window, smoke_marker)


def run_smoke_test(window: webview.Window, marker_path: str) -> None:
    try:
        if not window.events.loaded.wait(20):
            raise TimeoutError("The calculator page did not finish loading.")

        window.evaluate_js(
            """
            window.__ymboxSmokeDone = false;
            window.__ymboxSmokeResult = null;
            (async () => {
            window.location.hash = '#/motor-super-calculator';
            window.dispatchEvent(new Event('hashchange'));
            document.getElementById('motorTopology').value = 'spm';
            document.getElementById('motorConnection').value = 'unknown';
            document.getElementById('motor-polePairs').value = '4';
            document.getElementById('motor-speedRpm').value = '3000';
            document.getElementById('motor-rPhase').value = '0.4';
            document.getElementById('motor-inertia').value = '0.00012';
            document.getElementById('motor-maxTorque').value = '22.2';
            document.getElementById('motor-lPhase').value = '0.8';
            document.getElementById('motor-vBus').value = '300';
            document.getElementById('motor-ratedCurrent').value = '10';
            document.getElementById('motor-psiFlux').value = '0.05';
            document.getElementById('motorCalculateButton').click();
            const lineResistanceAlternatives = document.querySelector('[data-parameter-id="rLine"] .motor-status-cell')?.textContent;
            const ratedTorqueAlternatives = document.querySelector('[data-parameter-id="ratedTorque"] .motor-status-cell')?.textContent;
            document.getElementById('motorConnection').value = 'star';
            document.getElementById('motorConnection').dispatchEvent(new Event('change'));
            const motorResult = {
              rows: document.querySelectorAll('[data-parameter-id]').length,
              lineInductance: document.getElementById('motor-lLine')?.value,
              ld: document.getElementById('motor-ld')?.value,
              lq: document.getElementById('motor-lq')?.value,
              saliency: document.getElementById('motor-saliency')?.value,
              lineVoltage: document.getElementById('motor-vLine')?.value,
              phaseVoltage: document.getElementById('motor-vPhase')?.value,
              ktIqPeak: document.getElementById('motor-ktIqPeak')?.value,
              ktPhaseRms: document.getElementById('motor-ktPhaseRms')?.value,
              tauD: document.getElementById('motor-tauD')?.value,
              copperLoss: document.getElementById('motor-copperLoss')?.value,
              ratedTorque: document.getElementById('motor-ratedTorque')?.value,
              ratedPowerKw: document.getElementById('motor-powerKw')?.value,
              lineResistanceAlternatives,
              ratedTorqueAlternatives
            };
            const savedMotor = await window.YMBOXProfiles.save(
              'motor',
              'Smoke Motor',
              window.YMBOXMotorCalculator.collectProfileData()
            );
            const loadedMotor = await window.YMBOXProfiles.load('motor', 'Smoke Motor');
            motorResult.profileRoundTrip = savedMotor.ok && loadedMotor.ok;
            motorResult.ipmLqFromLdAndRatio = window.YMBOXMotorCalculator.resolveProfileData({
              topology: 'ipm',
              connection: 'star',
              values: { ld: '0.6', saliency: '2' }
            }).values.lq;
            document.getElementById('motorClearButton').click();
            document.getElementById('motorCalculateButton').click();
            motorResult.emptyPrompt = document.getElementById('motorMessagePanel')?.textContent;
            document.getElementById('motor-polePairs').value = '4.5';
            document.getElementById('motor-polePairs').dispatchEvent(new Event('input'));
            document.getElementById('motorCalculateButton').click();
            motorResult.invalidPoleStatus = document.querySelector('[data-parameter-id="polePairs"] .motor-status-cell')?.textContent;
            window.location.hash = '#/ymbox-configuration';
            window.dispatchEvent(new Event('hashchange'));
            const defaultEnglish = document.documentElement.lang === 'en'
              && document.querySelector('#ymboxConfigurationView h1')?.textContent === 'YMBOX Configuration';
            document.querySelector('#languageSwitch [data-language="zh-CN"]')?.click();
            const chineseToggle = document.documentElement.lang === 'zh-CN'
              && document.querySelector('#ymboxConfigurationView h1')?.textContent === 'YMBOX配置工具';
            document.querySelector('#languageSwitch [data-language="en"]')?.click();
            const ymboxResult = {
              visible: !document.getElementById('ymboxConfigurationView')?.hidden,
              fields: document.querySelectorAll('#ymboxConfigurationView [data-path]').length,
              locale: window.YMBOXI18n?.getLocale(),
              hasDocumentApi: typeof window.YMBOXUI?.getDocument === 'function',
              defaultEnglish,
              chineseToggle,
              englishRestored: document.documentElement.lang === 'en'
                && document.querySelector('#ymboxConfigurationView h1')?.textContent === 'YMBOX Configuration'
            };
            window.__ymboxSmokeResult = {
              title: document.title,
              registeredTools: document.querySelectorAll('[data-tool-id]').length,
              readyTools: document.querySelectorAll('[data-tool-id]:not(:disabled)').length,
              toolboxHidden: document.getElementById('homeView')?.hidden,
              motor: motorResult,
              ymbox: ymboxResult
            };
            window.__ymboxSmokeDone = true;
            })().catch((error) => {
              window.__ymboxSmokeResult = { error: String(error) };
              window.__ymboxSmokeDone = true;
            });
            true;
            """
        )
        deadline = time.monotonic() + 25
        while time.monotonic() < deadline:
            if window.evaluate_js("window.__ymboxSmokeDone === true"):
                break
            time.sleep(0.1)
        else:
            raise TimeoutError("The profile smoke test did not finish.")

        result = window.evaluate_js("window.__ymboxSmokeResult")
        payload = {"ok": True, "result": result}
    except Exception as exc:
        payload = {"ok": False, "error": str(exc)}

    Path(marker_path).write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    window.destroy()


def main() -> None:
    os.environ.setdefault("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", "--disable-features=msSmartScreenProtection")
    configure_windows_app_identity()

    index_url = asset_path("index.html").as_uri()
    icon_path = str(asset_path("assets/icon/ymbox-app.ico"))
    profile_store = ProfileStore()
    window = webview.create_window(
        "YMBOX 工具箱",
        url=index_url,
        width=1280,
        height=860,
        min_size=(920, 640),
        background_color="#edf3df",
        text_select=True,
        js_api=profile_store,
    )
    smoke_marker = os.environ.get("MOTOR_PI_SMOKE_MARKER")
    webview.start(
        initialize_window,
        args=(window, icon_path, smoke_marker),
        gui="edgechromium",
        debug=False,
        icon=icon_path,
    )


if __name__ == "__main__":
    main()
