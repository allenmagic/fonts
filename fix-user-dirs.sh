#!/usr/bin/env bash
set -euo pipefail

# 映射表：按需调整为你当前的本地化目录名
declare -A MAP=(
  [桌面]=Desktop
  [下载]=Downloads
  [文档]=Documents
  [图片]=Pictures
  [音乐]=Music
  [视频]=Videos
  [公共]=Public
  [模板]=Templates
)

# 1) 重命名/合并目录
for cn in "${!MAP[@]}"; do
  src="$HOME/$cn"
  dst="$HOME/${MAP[$cn]}"
  if [[ -d "$src" && ! -d "$dst" ]]; then
    mv "$src" "$dst"
  elif [[ -d "$src" && -d "$dst" ]]; then
    rsync -a "$src/" "$dst/" && rmdir "$src"
  fi
done

# 2) 更新 XDG 用户目录配置
xdg-user-dirs-update --set DESKTOP      "$HOME/Desktop"
xdg-user-dirs-update --set DOWNLOAD     "$HOME/Downloads"
xdg-user-dirs-update --set DOCUMENTS    "$HOME/Documents"
xdg-user-dirs-update --set MUSIC        "$HOME/Music"
xdg-user-dirs-update --set PICTURES     "$HOME/Pictures"
xdg-user-dirs-update --set VIDEOS       "$HOME/Videos"
xdg-user-dirs-update --set PUBLICSHARE  "$HOME/Public"
xdg-user-dirs-update --set TEMPLATES    "$HOME/Templates"

# 3) 禁用自动本地化（防止再次改回）
sed -i 's/enabled=.*/enabled=false/' ~/.config/user-dirs.conf 2>/dev/null || \
printf "enabled=false\n" > ~/.config/user-dirs.conf

echo "Done. Please re-login your session."
