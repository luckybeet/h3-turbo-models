# h3-turbo-models

> ⏳ **状态**：模型正在上传 ModelScope（62 GB × 2，分批进行中）。
> 上传完成前，下方的 ModelScope 链接可能暂时无法访问；
> 脚本与配方现在即可使用（本地已有模型的话）。

**MiniMax-H3 Turbo 折叠模型的分发索引与使用指南。**

本仓库是消费端配套：一个一键脚本（`scripts/h3_turbo.sh`）+ 实测配方。
它不包含模型文件，也不包含折叠实现——只告诉你三件事：

1. **折叠好的模型在哪** —— ModelScope（魔搭社区），拉下来就能用
2. **怎么跑起来** —— 配合 [h3.c](https://github.com/antirez/h3.c) 引擎（C + Metal，Apple Silicon）+ 本仓库的脚本
3. **什么场景用什么参数** —— 下方配方表（M3 Max 实测）

---

## 模型索引

| 模型 | 模式 | 大小 | ModelScope |
|---|---|---|---|
| **MiniMax-H3-FL2V-Turbo-4Step** | 首尾帧生视频（FL2V） | ~62 GB | `duanxingchen/MiniMax-H3-FL2V-Turbo-4Step` |
| **MiniMax-H3-Ref2V-Turbo-4Step** | 单参考图生视频（Ref2V） | ~62 GB | `duanxingchen/MiniMax-H3-Ref2V-Turbo-4Step` |

> **关于分发平台的选择**：模型发布于魔搭（ModelScope）是受上传时效性
> 的务实选择——HuggingFace 在本环境网络下不可达。发布地不构成任何
> 偏好或排他声明；条件允许时同样可以考虑 HF 镜像。账号名以实际发布
> 为准。
>
> 每个仓库包含折叠后的 `transformer/` 目录；其余组件（video_vae /
> audio_vae / text_encoder / tokenizer）请从官方
> [MiniMax/MiniMax-H3](https://www.modelscope.cn/models/MiniMax/MiniMax-H3)
> 获取，组装方法见各仓库 model card。

这些模型是什么：MiniMax 官方 H3 权重与 4 步蒸馏 Turbo LoRA 的离线折叠
产物，采样步数从 20 降至 4，**端到端约 6.5× 提速**（M3 Max 实测），
慢/中速内容下画质与原版 20 步视觉几乎无差。

## 快速开始

```sh
# 1. 获取 runner：h3.c 引擎（C + Metal，Apple Silicon 原生）
git clone https://github.com/antirez/h3.c
cd h3.c && make

# 2. 拉取模型（折叠版 transformer + 官方基础模型组件）
modelscope download --model MiniMax/MiniMax-H3
modelscope download --model duanxingchen/MiniMax-H3-FL2V-Turbo-4Step
# 按 model card 说明组装成完整模型目录

# 3. 环境自检（可选但推荐）：引擎在不在、模型目录齐不齐
./scripts/h3_turbo.sh --check

# 4. 用本仓库的脚本跑（等价于手敲 h3 命令，自动选模型/裁图/命名输出）
./scripts/h3_turbo.sh -p "你的提示词" \
    --first-frame first.png --last-frame last.png \
    --quality fast
```

脚本默认读取 `$HOME/models/MiniMax-H3-FL2V-Turbo-4Step`（Ref2V 模式读
`MiniMax-H3-Ref2V-Turbo-4Step`），可用环境变量覆盖
（`MODEL_FAST` / `MODEL_REF` / `H3_BIN` / `OUT_DIR`）。

### 脚本用法速查

```
h3_turbo.sh -p PROMPT                                  # t2v 纯文生视频
h3_turbo.sh -p PROMPT --first a.png --last b.png       # fl2v 首尾帧
h3_turbo.sh -p PROMPT --ref r1.png --ref r2.png        # ref2v 参考图
h3_turbo.sh ... -q fast|sharp|good                     # 质量档
h3_turbo.sh ... --fit                                  # 输入图自动居中裁到目标比例
h3_turbo.sh ... --dry-run                              # 只打印将执行的命令
h3_turbo.sh --check                                    # 环境自检
```

质量档：`fast`（默认，4步 l40 r2 最快）/ `sharp`（4步 l40 r1 更锐）/
`good`（6步 l50 r1 质量档，长片/特写）。

## 推荐配方（M3 Max 实测）

| 场景 | 模式 | 参数 | 耗时/条* | 峰值内存* |
|---|---|---|---|---|
| 环境空镜/氛围 | FL2V | `--steps 4 --layers 40 --reuse 2` | ~2.9 min | ~30 GB |
| 人物特写 | Ref2V | `--steps 4 --layers 50 --reuse 1` | ~3.4 min | ~34 GB |
| 精细质量档 | FL2V/Ref2V | `--steps 6 --layers 50 --reuse 1` | ~3.4 min | ~34 GB |
| 运动/穿越镜头 | FL2V | `--steps 4 --layers 50 --reuse 1` | ~8 min | ~37 GB |
| 高清档 | FL2V | 768×1024 + `--steps 4 --layers 40 --reuse 1` | ~10 min | ~45 GB |

\* 480×640 / 107 帧（4.46 秒）规格，除高清档外。
内存口径为 M3 Max 128 GB 统一内存实测峰值；**建议 ≥ 32 GB 统一内存的
Apple Silicon 机器**（M1 Pro/Max 及以上可跑 F2 及以下档位）。

**脸部黄金法则**：人物面部需占画面 ≥25%（近景），Ref2V 配合高清参考图；
无人脸的环境内容用 FL2V/T2V 任意档。

折叠前后的实测对比帧见 [`examples/`](examples/)：同一 prompt/seed 下，
原版 20 步 vs Turbo 4/6 步的四联对比。

## 许可

> ### ⚠️ 地域限制
> 本衍生模型遵循 **MiniMax H3 Community License Agreement**，
> **授权地域排除 EU / UK / 韩国 / 美国**。上述地区的用户获取、
> 使用或分发本模型均**不在授权范围内**。

折叠模型为 MiniMax-H3 的衍生作品（Model Derivatives），遵循
**MiniMax H3 Community License Agreement**（全文见各模型仓库的
`LICENSE`，必要声明见 `NOTICE`）。要点：授权地域排除 EU/UK/KR/US；
生成内容（Outputs）的权利归使用者所有。详见
[NOTICE.md](NOTICE.md)。

## 关于「折叠实现未公开」

折叠模型的生成方法（离线 LoRA→checkpoint 折叠，含全部 ComfyUI 格式
陷阱的处理）未随本仓库公开。这是刻意的分层策略：模型以**已验证的
成品**形式分发，保证社区拿到的每一份权重都经过相同的对拍与端到端
验证；折叠实现留在生产端，避免未经充分测试的变体在社区流通。
本仓库提供消费端配套：一键脚本与实测配方。

## 致谢

本索引站在两个基座上：**antirez** 的 [h3.c](https://github.com/antirez/h3.c)
（C + Metal 推理引擎，Redis 之父的最新作品）与 **MiniMax** 的 H3 模型家族
（官方 ModelScope 分发）。完整致谢见 [THANKS.md](THANKS.md)。
