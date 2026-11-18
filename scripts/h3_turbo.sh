#!/bin/bash
# h3_turbo.sh — one-shot CLI wrapper for h3.c + MiniMax-H3 Turbo checkpoints
#
# Wraps the h3.c engine binary with production recipes for the folded
# 4-step Turbo checkpoints (distributed on ModelScope, see README.md).
# All defaults are overridable via environment variables.
#
# 默认档（fast）：480×640 / 107帧(4.46s) / 4步 / layers 40 / reuse 2
#   → DiT ~3.1min，端到端 ~4.7min，峰值 30 GiB（实测 M3 Max 128G）
#
# 用法：
#   scripts/h3_turbo.sh -p "PROMPT"                                  # t2v 纯文生视频
#   scripts/h3_turbo.sh -p "PROMPT" --first a.png --last b.png        # fl2v 首尾帧
#   scripts/h3_turbo.sh -p "PROMPT" --ref r1.png --ref r2.png         # ref2v 参考图
#   scripts/h3_turbo.sh -p "PROMPT" --first a.png --last b.png -q good
#   scripts/h3_turbo.sh --check                                      # 环境自检（路径/模型目录）
#   scripts/h3_turbo.sh ... --dry-run                                # 只打印将执行的命令
#
# 质量档：
#   fast   4步 l40 r2  最快（默认）
#   sharp  4步 l40 r1  更锐（+25% 时间）
#   good   6步 l50 r1  质量档（长片/特写）
#
# 其他：--fit 自动把输入图居中裁到目标宽高比（官方要求首尾帧预裁比例）

set -euo pipefail

H3_BIN="${H3_BIN:-$HOME/h3.c/h3}"   # h3.c 引擎编译产物路径
MODEL_FAST="${MODEL_FAST:-$HOME/models/MiniMax-H3-FL2V-Turbo-4Step}"
MODEL_REF="${MODEL_REF:-$HOME/models/MiniMax-H3-Ref2V-Turbo-4Step}"
OUT_DIR="${OUT_DIR:-$HOME/outputs}"

# 默认参数（fast 档）
WIDTH=480; HEIGHT=640; FRAMES=107
STEPS=4; LAYERS=40; REUSE=2; SEED=42
QUALITY=fast
PROMPT=""; FIRST=""; LAST=""; OUT=""
REFS=(); FIT=0; DRY_RUN=0; CHECK=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# 模型目录自检：折叠版 transformer + 四个官方组件齐全才算组装完成
check_model_dir() {
  local base=$1 name=$2 sub ok=1
  for sub in transformer video_vae audio_vae text_encoder tokenizer; do
    [ -d "$base/$sub" ] || { echo "  ✗ 缺组件: $name/$sub" >&2; ok=0; }
  done
  [ "$ok" = 1 ] && echo "  ✓ $name 组件齐全（transformer + 4 official components）"
  return $((1-ok))
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--prompt) PROMPT=$2; shift 2;;
    --first)     FIRST=$2;  shift 2;;
    --last)      LAST=$2;   shift 2;;
    --ref)       REFS+=("$2"); shift 2;;
    -q|--quality) QUALITY=$2; shift 2;;
    -W|--width)  WIDTH=$2;  shift 2;;
    -H|--height) HEIGHT=$2; shift 2;;
    -f|--frames) FRAMES=$2; shift 2;;
    -s|--steps)  STEPS=$2;  shift 2;;
    --layers)    LAYERS=$2; shift 2;;
    --reuse)     REUSE=$2;  shift 2;;
    --seed)      SEED=$2;   shift 2;;
    -o|--out)    OUT=$2;    shift 2;;
    --fit)       FIT=1;     shift;;
    --dry-run)   DRY_RUN=1; shift;;
    --check)     CHECK=1;   shift;;
    -h|--help)   usage;;
    *) echo "未知参数: $1" >&2; usage 1;;
  esac
done

# 质量档覆盖
case "$QUALITY" in
  fast)  ;;
  sharp) REUSE=1;;
  good)  STEPS=6; LAYERS=50; REUSE=1;;
  *) echo "未知质量档: $QUALITY（fast/sharp/good）" >&2; exit 1;;
esac

# --check：环境自检模式（不生成）
if [ "$CHECK" = 1 ]; then
  echo "== h3-turbo 环境自检 =============================="
  if [ -x "$H3_BIN" ]; then
    echo "  ✓ 引擎: $H3_BIN"
    "$H3_BIN" --version 2>/dev/null | head -1 | sed 's/^/    /' || echo "    (版本获取失败，不影响使用)"
  else
    echo "  ✗ 引擎不存在: $H3_BIN（编译 h3.c 或设 H3_BIN）" >&2
  fi
  check_model_dir "$MODEL_FAST/FL2VA" "FL2V-Turbo-4Step" || true
  check_model_dir "$MODEL_REF/Ref2VA" "Ref2V-Turbo-4Step" || true
  echo "====================================================="
  exit 0
fi

[ -n "$PROMPT" ] || { echo "缺少 -p PROMPT" >&2; exit 1; }
[ -x "$H3_BIN" ] || { echo "找不到引擎: $H3_BIN（先编译 h3.c，或设 H3_BIN 环境变量；可跑 --check 自检）" >&2; exit 1; }
mkdir -p "$OUT_DIR"

# 输入模式：ref2v（参考图）/ fl2v（首尾帧）/ t2v（纯文生视频）
if [ ${#REFS[@]} -gt 0 ]; then
  MODEL=$MODEL_REF; MODE=ref2v
  check_model_dir "$MODEL/Ref2VA" "Ref2V-Turbo-4Step" || { echo "ref2v 模型目录不完整: $MODEL/Ref2VA（需 transformer + video_vae + audio_vae + text_encoder + tokenizer）" >&2; exit 1; }
  [ -n "$FIRST$LAST" ] && { echo "ref2v 与首尾帧互斥" >&2; exit 1; }
  for r in "${REFS[@]}"; do [ -f "$r" ] || { echo "参考图不存在: $r" >&2; exit 1; }; done
elif [ -n "$FIRST" ] || [ -n "$LAST" ]; then
  MODEL=$MODEL_FAST; MODE=fl2v
  check_model_dir "$MODEL/FL2VA" "FL2V-Turbo-4Step" || { echo "fl2v 模型目录不完整: $MODEL/FL2VA（需 transformer + video_vae + audio_vae + text_encoder + tokenizer）" >&2; exit 1; }
  [ -n "$FIRST" ] && [ -n "$LAST" ] || { echo "fl2v 模式需要同时给 --first 和 --last" >&2; exit 1; }
  [ -f "$FIRST" ] && [ -f "$LAST" ] || { echo "首尾帧文件不存在" >&2; exit 1; }
else
  MODEL=$MODEL_FAST; MODE=t2v
  check_model_dir "$MODEL/FL2VA" "FL2V-Turbo-4Step" || { echo "fl2v 模型目录不完整: $MODEL/FL2VA（需 transformer + video_vae + audio_vae + text_encoder + tokenizer）" >&2; exit 1; }
fi

# --fit：居中裁到目标宽高比（先缩放到覆盖，再中心裁剪）
if [ "$FIT" = 1 ]; then
  TMP=$(mktemp -d /tmp/h3fit.XXXXXX); trap 'rm -rf "$TMP"' EXIT
  fit_one() {
    local src=$1 dst=$2
    local ow oh
    ow=$(sips -g pixelWidth  "$src" | awk '/pixelWidth/{print $2}')
    oh=$(sips -g pixelHeight "$src" | awk '/pixelHeight/{print $2}')
    if [ "$ow" = "$WIDTH" ] && [ "$oh" = "$HEIGHT" ]; then cp "$src" "$dst"; return; fi
    local nw nh
    if [ $((WIDTH*1000/ow)) -ge $((HEIGHT*1000/oh)) ]; then
      nw=$WIDTH; nh=$((oh*WIDTH/ow))
    else
      nh=$HEIGHT; nw=$((ow*HEIGHT/oh))
    fi
    sips -z "$nh" "$nw" --out "$dst" "$src" >/dev/null 2>&1
    sips --cropToHeightWidth "$HEIGHT" "$WIDTH" --out "$dst" "$dst" >/dev/null 2>&1
  }
  if [ "$MODE" = fl2v ]; then
    fit_one "$FIRST" "$TMP/first.png"; fit_one "$LAST" "$TMP/last.png"
    FIRST=$TMP/first.png; LAST=$TMP/last.png
  else
    i=0; for r in "${REFS[@]}"; do
      fit_one "$r" "$TMP/ref$i.png"; REFS[$i]=$TMP/ref$i.png; i=$((i+1))
    done
  fi
fi

[ -n "$OUT" ] || OUT="$OUT_DIR/turbo_${MODE}_${WIDTH}x${HEIGHT}_${FRAMES}f_${STEPS}s_$(date +%H%M%S).mp4"

ARGS=(--profile -d "$MODEL" -p "$PROMPT"
      --width "$WIDTH" --height "$HEIGHT"
      --frames "$FRAMES" --steps "$STEPS"
      --layers "$LAYERS" --reuse "$REUSE" --seed "$SEED"
      -o "$OUT")
if [ "$MODE" = fl2v ]; then
  ARGS+=(--first-frame "$FIRST" --last-frame "$LAST")
else
  for r in "${REFS[@]}"; do ARGS+=(--ref-image "$r"); done
fi

echo "== h3 turbo =========================================="
echo "模型: $MODEL"
echo "画布: ${WIDTH}x${HEIGHT}  帧数: $FRAMES  档位: $QUALITY (steps=$STEPS layers=$LAYERS reuse=$REUSE seed=$SEED)"
echo "输出: $OUT"
echo "======================================================"

if [ "$DRY_RUN" = 1 ]; then
  echo "[dry-run] 将执行:"
  printf '  %q ' "$H3_BIN" "${ARGS[@]}"; echo
  exit 0
fi

exec "$H3_BIN" "${ARGS[@]}"
