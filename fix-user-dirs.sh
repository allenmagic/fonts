#!/usr/bin/env bash
set -Eeuo pipefail

# 目标：真实路径为英文，GUI 显示中文标签
# 适用：Cinnamon（Nemo 文件管理器）

# 彩色输出（可选）
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

# 检查环境
[[ -n "${HOME:-}" ]] || { red "HOME 未设置"; exit 1; }
command -v nemo >/dev/null 2>&1 || yellow "未检测到 nemo，脚本仍可运行但无法自动重启文件管理器。"
RSYNC_AVAILABLE=0
command -v rsync >/dev/null 2>&1 && RSYNC_AVAILABLE=1

# 中文名 -> 英文名 映射（按需增减）
declare -A CN2EN=(
  [桌面]=Desktop
  [下载]=Downloads
  [文档]=Documents
  [图片]=Pictures
  [音乐]=Music
  [视频]=Videos
  [公共]=Public
  [模板]=Templates
)

# XDG 键 -> 英文目录名 映射
declare -A XDG_KEYS=(
  [DESKTOP]=Desktop
  [DOWNLOAD]=Downloads
  [DOCUMENTS]=Documents
  [MUSIC]=Music
  [PICTURES]=Pictures
  [VIDEOS]=Videos
  [PUBLICSHARE]=Public
  [TEMPLATES]=Templates
)

# 为部分目录设置中文书签标签（侧边栏显示中文）
declare -A BOOKMARK_LABELS=(
  [Desktop]=桌面
  [Downloads]=下载
  [Documents]=文档
  [Pictures]=图片
  [Music]=音乐
  [Videos]=视频
  [Public]=公共
  [Templates]=模板
)

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local ts
    ts="$(date +'%Y%m%d-%H%M%S')"
    cp -a "$f" "${f}.bak.${ts}"
    yellow "已备份 $f -> ${f}.bak.${ts}"
  fi
}

merge_or_rename() {
  local src="$1" dst="$2"
  if [[ -d "$src" && ! -d "$dst" ]]; then
    mv "$src" "$dst"
    green "重命名：$src -> $dst"
  elif [[ -d "$src" && -d "$dst" ]]; then
    if [[ "$RSYNC_AVAILABLE" -eq 1 ]]; then
      rsync -a "$src/" "$dst/"
      green "合并内容：$src => $dst"
    else
      yellow "rsync 不可用，改用 cp 合并（可能较慢）"
      cp -a "$src/." "$dst/"
      green "合并内容：$src => $dst"
    fi
    if rmdir "$src" 2>/dev/null; then
      green "已移除空目录：$src"
    else
      yellow "保留原中文目录：$src（非空），请确认内容后按需手动删除。"
    fi
  elif [[ ! -d "$src" && ! -d "$dst" ]]; then
    mkdir -p "$dst"
    green "创建英文目录：$dst"
  fi
}

update_xdg_user_dirs() {
  local cfg_dir="$HOME/.config"
  mkdir -p "$cfg_dir"
  local dirs_file="$cfg_dir/user-dirs.dirs"
  local conf_file="$cfg_dir/user-dirs.conf"

  if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    for key in "${!XDG_KEYS[@]}"; do
      local en="${XDG_KEYS[$key]}"
      xdg-user-dirs-update --set "$key" "$HOME/$en"
    done
    green "已通过 xdg-user-dirs-update 设置 XDG 用户目录到英文路径。"
  else
    backup_file "$dirs_file"
    {
      echo '# 自动生成：用户目录映射到英文路径'
      echo "XDG_DESKTOP_DIR=\"$HOME/Desktop\""
      echo "XDG_DOWNLOAD_DIR=\"$HOME/Downloads\""
      echo "XDG_DOCUMENTS_DIR=\"$HOME/Documents\""
      echo "XDG_MUSIC_DIR=\"$HOME/Music\""
      echo "XDG_PICTURES_DIR=\"$HOME/Pictures\""
      echo "XDG_VIDEOS_DIR=\"$HOME/Videos\""
      echo "XDG_PUBLICSHARE_DIR=\"$HOME/Public\""
      echo "XDG_TEMPLATES_DIR=\"$HOME/Templates\""
    } > "$dirs_file"
    green "已写入 $dirs_file"
  fi

  # 禁用自动本地化，避免被重命名
  if [[ -f "$conf_file" ]]; then
    backup_file "$conf_file"
    sed -i 's/enabled=.*/enabled=false/' "$conf_file" || true
  else
    printf "enabled=false\n" > "$conf_file"
  fi
  green "已设置 ~/.config/user-dirs.conf: enabled=false"
}

ensure_bookmark() {
  local path="$1" label="$2" bkfile="$HOME/.config/gtk-3/bookmarks"
  mkdir -p "$(dirname "$bkfile")"
  # 书签行格式：file:///absolute/path<space>Label
  local line="file://$path $label"
  if [[ -f "$bkfile" ]] && grep -Fqx "$line" "$bkfile"; then
    return
  fi
  backup_file "$bkfile"
  printf "%s\n" "$line" >> "$bkfile"
}

add_chinese_bookmarks() {
  for en in "${!BOOKMARK_LABELS[@]}"; do
    local label="${BOOKMARK_LABELS[$en]}"
    ensure_bookmark "$HOME/$en" "$label"
  done
  green "已为英文路径添加中文书签标签至 ~/.config/gtk-3/bookmarks"
}

restart_nemo() {
  if command -v nemo >/dev/null 2>&1; then
    nemo -q || true
    green "已重启 Nemo。"
  fi
}

main() {
  yellow "开始处理：将真实路径统一为英文，并在 GUI 显示中文标签。"

  # 1) 合并/重命名目录到英文
  for cn in "${!CN2EN[@]}"; do
    local src="$HOME/$cn"
    local en="${CN2EN[$cn]}"
    local dst="$HOME/$en"
    merge_or_rename "$src" "$dst"
  done

  # 2) 更新 XDG 用户目录映射
  update_xdg_user_dirs

  # 3) 添加中文书签标签（强制侧边栏显示中文）
  add_chinese_bookmarks

  # 4) 重启 Nemo
  restart_nemo

  yellow "完成。终端可使用英文路径（如 cd ~/Downloads），Nemo 侧边栏显示中文标签。"
  yellow "如中文旧目录未被删除（含未合并文件），请检查后手动处理。"
}

main "$@"
