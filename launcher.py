import atexit
import msvcrt
import os
import subprocess
import sys
import tempfile
import time
import urllib.request

# Launcher constants
LAUNCHER_VERSION = "1.1"
LAUNCHER_TITLE = "LAUNCHER"
VERSION_URL = "https://raw.githubusercontent.com/Popsiclez1/Juggware/refs/heads/main/LauncherVersion"
MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/Popsiclez1/Juggware/refs/heads/main/main.py"
LOCAL_MAIN_FILENAME = "main.py"
SUPPORTED_PYTHON_MAJOR = 3
SUPPORTED_PYTHON_MINORS = {11}

# Temp directory for downloaded script
TEMP_DIR = tempfile.gettempdir()
os.makedirs(TEMP_DIR, exist_ok=True)

# Track temp files for cleanup
temp_files = set()


def set_console_title():
    os.system(f'title {LAUNCHER_TITLE}')


def get_script_dir():
    """Get the directory where the launcher exe/script is located"""
    if getattr(sys, 'frozen', False):
        # Running as compiled exe (PyInstaller/auto-py-to-exe)
        return os.path.dirname(sys.executable)
    else:
        # Running as script
        return os.path.dirname(os.path.abspath(__file__))


def add_temp_file(file_path):
    temp_files.add(file_path)


def cleanup_temp_files():
    for temp_file in list(temp_files):
        try:
            if os.path.exists(temp_file):
                os.remove(temp_file)
        except Exception:
            pass
    temp_files.clear()


atexit.register(cleanup_temp_files)


def check_launcher_version():
    print("[LAUNCHER] Checking version...")
    try:
        with urllib.request.urlopen(VERSION_URL) as response:
            remote_version = response.read().decode('utf-8').strip()
        if LAUNCHER_VERSION != remote_version:
            print("[LAUNCHER] Version outdated...")
            print("[LAUNCHER] Download newest launcher. (Run setup again)")
            sys.exit(1)
    except Exception as e:
        print(f"[LAUNCHER] Error checking version: {e}")
        sys.exit(1)

    print("[LAUNCHER] Version is up to date.")


def find_python_executable():
    """Find the Python executable with required packages installed"""
    possible_paths = [
        os.path.join(os.environ.get('LocalAppData', ''), 'Programs', 'Python', 'Python311', 'python.exe'),
        os.path.join(os.environ.get('LocalAppData', ''), 'Programs', 'Python', 'Python311', 'python3.11.exe'),
        os.path.join(os.environ.get('LocalAppData', ''), 'Programs', 'Python', 'Python313', 'python.exe'),
        os.path.join(os.environ.get('LocalAppData', ''), 'Programs', 'Python', 'Python312', 'python.exe'),
        'python3.11.exe',
        'python.exe',
        'python',
    ]

    for python_path in possible_paths:
        try:
            result = subprocess.run([python_path, '--version'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                return python_path
        except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.SubprocessError):
            continue

    return None


def check_python_compatibility(python_exe):
    print("[LAUNCHER] Checking Python compatibility...")
    try:
        result = subprocess.run(
            [python_exe, '-c', 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            print("[LAUNCHER] Could not verify Python version.")
            sys.exit(1)

        version_text = result.stdout.strip()
        major, minor = map(int, version_text.split('.'))
        if major != SUPPORTED_PYTHON_MAJOR or minor not in SUPPORTED_PYTHON_MINORS:
            print(f"[LAUNCHER] Incompatible Python version: {version_text}")
            print("[LAUNCHER] Supported version: 3.11")
            sys.exit(1)
    except Exception as e:
        print(f"[LAUNCHER] Error checking Python compatibility: {e}")
        sys.exit(1)

    print("[LAUNCHER] Python version is compatible.")


def download_main_script(script_path):
    try:
        with urllib.request.urlopen(MAIN_SCRIPT_URL) as response:
            code = response.read().decode('utf-8')

        # Save to temp file
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(code)
    except Exception as e:
        print(f"[LAUNCHER] Error downloading cheat: {e}")
        sys.exit(1)


def resolve_main_script_path(launcher_dir):
    """Prefer local main.py next to launcher; fallback to downloaded temp copy."""
    local_main = os.path.join(launcher_dir, LOCAL_MAIN_FILENAME)
    if os.path.exists(local_main):
        print(f"[LAUNCHER] Using local script: {local_main}")
        return local_main, False

    script_path = os.path.join(TEMP_DIR, 'main.py')
    add_temp_file(script_path)
    download_main_script(script_path)
    print(f"[LAUNCHER] Using downloaded script: {script_path}")
    return script_path, True


def check_required_packages(python_exe):
    print("[LAUNCHER] Checking required packages...")
    try:
        # All packages that main.py imports
        check_imports = '''
import dearpygui.dearpygui
import win32gui, win32api, win32con, win32process
import psutil
import pymem
import numpy
import pyautogui
import glfw
import PIL
import scipy
import pynput
import imgui
import requests
from OpenGL.GL import *
'''
        result = subprocess.run([python_exe, '-c', check_imports], capture_output=True, text=True, timeout=15)
        if result.returncode != 0:
            print(f"[LAUNCHER] Missing required packages.")
            print(f"[LAUNCHER] Install with: pip install dearpygui pywin32 psutil pymem numpy pyautogui glfw pillow scipy pynput imgui[glfw] PyOpenGL PyOpenGL_accelerate pygame requests")
            print(f"[LAUNCHER] Error: {result.stderr}")
            sys.exit(1)
    except Exception as e:
        print(f"[LAUNCHER] Error checking packages: {e}")
        sys.exit(1)

    print("[LAUNCHER] All packages are installed.")


def launch_main_script(python_exe, script_path, launcher_dir, mode=1):
    try:
        if mode == 2:
            # Use a single command line so cmd.exe parses quoted paths correctly.
            cmd_line = f'cmd.exe /k ""{python_exe}" "{script_path}""'
            process = subprocess.Popen(
                cmd_line,
                cwd=launcher_dir,
                creationflags=subprocess.CREATE_NEW_CONSOLE,
                text=True,
            )
            print("[LAUNCHER] Debug mode: launched cheat in new console window.")
            print("[LAUNCHER] Waiting for console window to close...")
            exit_code = process.wait()
            print(f"[LAUNCHER] Debug console closed (code: {exit_code}).")
            return

        process = subprocess.Popen(
            [python_exe, script_path],
            cwd=launcher_dir,
            creationflags=subprocess.CREATE_NO_WINDOW,
            text=True,
        )
        time.sleep(2)  # Wait a bit to see if it stays running
        if process.poll() is not None:
            exit_code = process.returncode
            print(f"[LAUNCHER] Main script exited immediately (code: {exit_code}).")
            print(f"[LAUNCHER] Check crash log if present: {os.path.join(launcher_dir, 'crash.log')}")
        else:
            print("[LAUNCHER] Cheat is running.")
            # Don't cleanup temp file while main.py is running
            temp_files.discard(script_path)
    except Exception as e:
        print(f"[LAUNCHER] Error running cheat: {e}")
        sys.exit(1)


def wait_for_enter_only(prompt):
    """Wait for Enter key only; ignore all other key presses."""
    print(prompt)
    while True:
        key = msvcrt.getwch()
        if key == "\r":
            break


def wait_for_mode_selection():
    """Prompt for launch mode and return 1 (regular) or 2 (debug)."""
    print("[LAUNCHER] Select mode:")
    print("[LAUNCHER] Press (1) for Regular Mode")
    print("[LAUNCHER] Press (2) for Debug Mode")

    while True:
        key = msvcrt.getwch()
        if key == "1":
            print("[LAUNCHER] Selected: Regular Mode")
            os.system('cls')
            return 1
        if key == "2":
            print("[LAUNCHER] Selected: Debug Mode")
            os.system('cls')
            return 2


def main():
    set_console_title()
    check_launcher_version()

    # Get the actual launcher directory (works for both script and exe)
    launcher_dir = get_script_dir()

    script_path, _ = resolve_main_script_path(launcher_dir)

    python_exe = find_python_executable()
    if not python_exe:
        print("Error: Could not find Python executable")
        sys.exit(1)

    check_python_compatibility(python_exe)

    check_required_packages(python_exe)

    os.system('cls')
    mode = wait_for_mode_selection()
    wait_for_enter_only("[LAUNCHER] Press (ENTER) to start cheat...")

    # Run the script from the launcher's directory so main.py creates folders there
    launch_main_script(python_exe, script_path, launcher_dir, mode=mode)


if __name__ == "__main__":
    main()