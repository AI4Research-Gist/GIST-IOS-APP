#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode-16.4.0.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode-16.4.0.app/Contents/Developer"
fi

PROJECT_PATH="${PROJECT_ROOT}/IceCubesApp.xcodeproj"
SCHEME="IceCubesApp"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="${PROJECT_ROOT}/build/stage1-device"
DEVICE_JSON="$(mktemp)"

cleanup() {
  rm -f "${DEVICE_JSON}"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  scripts/stage1_device_acceptance.sh <scenario>
  scripts/stage1_device_acceptance.sh --list

Scenarios:
  home
  library
  library-guides
  list-unread
  detail-paper
  project
  project-todo
  new-item
  toast
  explore
  tab-stacks

Notes:
  - This script targets Stage 1 Gist acceptance on a physical iPhone.
  - It builds, installs, and launches the app with the matching launch arguments.
  - Screenshot capture remains manual on-device; the script prints the suggested filename.
EOF
}

list_scenarios() {
  cat <<'EOF'
home            -> 首页工作台有数据态
library         -> 资料库目录默认态
library-guides  -> 资料库目录引导态（智能列表 / 收藏夹）
list-unread     -> 未读资料列表
detail-paper    -> 论文详情页
project         -> 项目详情页
project-todo    -> 项目待办勾选态
new-item        -> 新增资料 Sheet
toast           -> Toast “查看”跳转链路
explore         -> 探索页入口骨架
tab-stacks      -> Tab 独立导航栈验收浮层
EOF
}

scenario="${1:-}"
if [[ -z "${scenario}" ]]; then
  usage
  exit 1
fi

if [[ "${scenario}" == "--list" ]]; then
  list_scenarios
  exit 0
fi

launch_args=()
screenshot_name=""

case "${scenario}" in
  home)
    launch_args=(-GistSeed stage1 -GistInitialTab home)
    screenshot_name="阶段1-首页工作台-真机.png"
    ;;
  library)
    launch_args=(-GistSeed stage1 -GistInitialTab library)
    screenshot_name="阶段1-资料库目录-真机.png"
    ;;
  library-guides)
    launch_args=(-GistSeed stage1 -GistInitialTab library -GistDirectoryFocus favorites)
    screenshot_name="阶段1-资料库目录-引导态-真机.png"
    ;;
  list-unread)
    launch_args=(-GistSeed stage1 -GistInitialRoute list-unread)
    screenshot_name="阶段1-资料列表-真机.png"
    ;;
  detail-paper)
    launch_args=(-GistSeed stage1 -GistInitialRoute detail-paper)
    screenshot_name="阶段1-详情-论文-真机.png"
    ;;
  project)
    launch_args=(-GistSeed stage1 -GistInitialRoute project)
    screenshot_name="阶段1-项目页-真机.png"
    ;;
  project-todo)
    launch_args=(-GistSeed stage1 -GistInitialRoute project-todo -GistAutoToggleFirstTodo 1)
    screenshot_name="阶段1-项目待办-真机.png"
    ;;
  new-item)
    launch_args=(-GistInitialSheet newItem)
    screenshot_name="阶段1-新增资料Sheet-真机.png"
    ;;
  toast)
    launch_args=(-GistSeed stage1 -GistInitialRoute list-unread -GistInitialToast paper -GistAutoToastView 1)
    screenshot_name="阶段1-Toast查看跳转-真机.png"
    ;;
  explore)
    launch_args=(-GistInitialTab explore)
    screenshot_name="阶段1-探索页-真机.png"
    ;;
  tab-stacks)
    launch_args=(-GistSeed stage1 -GistPreloadTabStacks 1)
    screenshot_name="阶段1-Tab独立导航栈-真机.png"
    ;;
  *)
    echo "Unknown scenario: ${scenario}" >&2
    echo >&2
    list_scenarios >&2
    exit 1
    ;;
esac

echo "Inspecting physical devices..."
xcrun xcdevice list --timeout 5 > "${DEVICE_JSON}"

device_info="$(
  /usr/bin/python3 - <<'PY' "${DEVICE_JSON}"
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    raw = fh.read()

start = raw.find("[")
if start == -1:
    sys.exit(1)

devices = json.loads(raw[start:])
physical = [
    d for d in devices
    if not d.get("simulator", False) and d.get("platform") == "com.apple.platform.iphoneos"
]

if not physical:
    print("NONE")
    sys.exit(0)

device = physical[0]
error = device.get("error") or {}

fields = [
    device.get("identifier", ""),
    "true" if device.get("available") else "false",
    device.get("name", ""),
    device.get("modelName", ""),
    device.get("operatingSystemVersion", ""),
    error.get("description", ""),
    error.get("recoverySuggestion", ""),
]
print("\t".join(fields))
PY
)"

if [[ "${device_info}" == "NONE" ]]; then
  echo "No physical iPhone detected."
  echo "Connect the device by USB or enable wireless debugging first."
  exit 2
fi

IFS=$'\t' read -r device_id device_available device_name device_model device_os device_error device_recovery <<< "${device_info}"

echo "Detected device: ${device_name} (${device_model}, ${device_os})"
echo "UDID: ${device_id}"

if [[ "${device_available}" != "true" ]]; then
  echo
  echo "Device is not available for development yet."
  if [[ -n "${device_error}" ]]; then
    echo "Reason: ${device_error}"
  fi
  if [[ -n "${device_recovery}" ]]; then
    echo "Recovery: ${device_recovery}"
  fi
  exit 2
fi

bundle_identifier="$(
  xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination 'generic/platform=iOS' \
    -showBuildSettings 2>/dev/null | \
    awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER/ { print $2; exit }'
)"

if [[ -z "${bundle_identifier}" ]]; then
  echo "Could not determine PRODUCT_BUNDLE_IDENTIFIER." >&2
  exit 1
fi

echo
echo "Building ${SCHEME} for physical device..."
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "id=${device_id}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

app_path="$(
  find "${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphoneos" \
    -maxdepth 4 \
    -name '*.app' \
    -type d | \
    head -n 1
)"

if [[ -z "${app_path}" ]]; then
  echo "Could not locate built .app under ${DERIVED_DATA_PATH}." >&2
  exit 1
fi

echo
echo "Installing ${app_path}..."
xcrun devicectl device install app --device "${device_id}" "${app_path}"

echo
echo "Launching ${bundle_identifier} with scenario '${scenario}'..."
xcrun devicectl device process launch \
  --device "${device_id}" \
  --terminate-existing \
  "${bundle_identifier}" \
  "${launch_args[@]}"

echo
echo "Stage 1 physical-device scenario is live."
echo "Suggested screenshot filename: ${screenshot_name}"
echo "Save the screenshot under: ../迁移plan/验收截图/"
