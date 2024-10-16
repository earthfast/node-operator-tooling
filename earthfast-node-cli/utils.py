import subprocess
import sys
import platform
import shutil

def run_command(command, shell=True, check=True):
    try:
        result = subprocess.run(command, shell=shell, check=check, text=True, capture_output=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error output: {e.stderr}")
        sys.exit(1)

def is_tool(name):
    """Check whether `name` is on PATH and marked as executable."""
    return shutil.which(name) is not None

def get_os():
    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    elif system == "linux":
        return "linux"
    else:
        raise OSError(f"Unsupported operating system: {system}")

def install_package(package_name):
    os_type = get_os()
    if os_type == "macos":
        if not is_tool("brew"):
            print("Homebrew is not installed. Please install Homebrew first.")
            sys.exit(1)
        run_command(f"brew install {package_name}")
    elif os_type == "linux":
        if is_tool("apt-get"):
            run_command(f"sudo apt-get update && sudo apt-get install -y {package_name}")
        elif is_tool("yum"):
            run_command(f"sudo yum install -y {package_name}")
        elif is_tool("dnf"):
            run_command(f"sudo dnf install -y {package_name}")
        else:
            print("Unsupported package manager. Please install the required packages manually.")
            sys.exit(1)
