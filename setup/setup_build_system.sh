#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

### Download MuJoCo

download_latest_mujoco() {
  local download_type="$1"
  local output_file="$2"

  MUJOCO_LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/google-deepmind/mujoco/releases/latest | grep "browser_download_url" | grep "$download_type" | grep -v "sha256" | cut -d '"' -f 4)
  
  # ヒットしたURLが存在しかつ一つであることを確認
  read -a arr <<< "$MUJOCO_LATEST_RELEASE_URL"
  if [ "${#arr[@]}" -ne 1 ]; then
    echo "Error: Multiple or no download URLs found for $download_type."
    echo "URLs found: ${MUJOCO_LATEST_RELEASE_URL}"
    exit 1
  fi

  echo "Downloading MuJoCo from: $MUJOCO_LATEST_RELEASE_URL"
  wget -q "$MUJOCO_LATEST_RELEASE_URL" -O "$output_file"
}

# UbuntuとmacOSで場合分け
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  mujoco_dir="$REPO_DIR/mujoco"
  # mujocoディレクトリが存在する場合はスキップ
  if [ -d "$mujoco_dir" ]; then
    echo "MuJoCo already downloaded: $mujoco_dir"
  else
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
      download_latest_mujoco "linux-x86_64.tar.gz" "$REPO_DIR/mujoco.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
      download_latest_mujoco "linux-aarch64.tar.gz" "$REPO_DIR/mujoco.tar.gz"
    else
      echo "Unsupported architecture: $arch"
      exit 1
    fi
    # .tar.gzを解凍
    echo "Extracting MuJoCo to: $mujoco_dir"
    tar -xzf $REPO_DIR/mujoco.tar.gz
    mv mujoco*/ "$mujoco_dir/"
    # .tar.gzファイルを削除
    echo "Removing downloaded tar.gz file."
    rm $REPO_DIR/mujoco.tar.gz
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  mujoco_dir="$REPO_DIR/mujoco.framework"
  # mujoco.frameworkディレクトリが存在する場合はスキップ
  if [ -d "$mujoco_dir" ]; then
    echo "MuJoCo already downloaded: $mujoco_dir"
  else
    download_latest_mujoco "macos-universal2.dmg" "$REPO_DIR/mujoco.dmg"
    # .dmgをマウントして中身をコピー
    echo "Mounting MuJoCo DMG and copying to: $mujoco_dir"
    mount_point="/Volumes/MuJoCo"
    hdiutil attach "$REPO_DIR/mujoco.dmg" -mountpoint "$mount_point" -nobrowse -quiet
    echo "Copying MuJoCo framework to: $mujoco_dir"
    cp -r "$mount_point/mujoco.framework" "$mujoco_dir"
    # マウントを解除
    echo "Unmounting MuJoCo DMG."
    hdiutil detach "$mount_point" -quiet
    # .dmgファイルを削除
    echo "Removing downloaded DMG file."
    rm "$REPO_DIR/mujoco.dmg"
  fi
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi


### Install dependencies
APT_DEPENDENCIES="ninja-build ccache cmake libglfw3-dev libgl1-mesa-dev libglew-dev libosmesa6-dev libglvnd-dev"
BREW_DEPENDENCIES="ninja ccache cmake glfw"

if command -v brew >/dev/null 2>&1; then
    PM_CMD="brew"
    DEPENDENDIES="$BREW_DEPENDENCIES"
elif command -v apt >/dev/null 2>&1; then
    PM_CMD="apt"
    DEPENDENDIES="$APT_DEPENDENCIES"
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

# check if all apt dependencies are installed
INSTALL_REQUIRED=""
for dep in $DEPENDENDIES; do
    if { [ "$PM_CMD" = "apt" ] && ! dpkg -s "$dep" &> /dev/null; } || \
       { [ "$PM_CMD" = "brew" ] && ! brew list --formula | grep -q "^$dep\$"; }; then
        echo "$dep is not installed."
        INSTALL_REQUIRED="$INSTALL_REQUIRED $dep"
    else
        echo "Dependency $dep is already installed."
    fi
done

# Check if the script is run as root and not brew
if [ "$(id -u)" -ne 0 ] && [ "$PM_CMD" != "brew" ]; then
    PM_CMD="sudo $PM_CMD"
fi

# If any apt dependencies are missing, install them
if [ -n "$INSTALL_REQUIRED" ]; then
    echo "Installing missing dependencies: $INSTALL_REQUIRED"
    $PM_CMD update
    $PM_CMD install -y $INSTALL_REQUIRED
else
    echo "All dependencies are already installed."
fi