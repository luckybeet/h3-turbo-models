# h3-turbo-models

> ⏳ **状态**：模型正在上传 ModelScope（62 GB × 2，分批进行中）。
> 上传完成前，下方的 ModelScope 链接可能暂时无法访问；
> 脚本与配方现在即可使用（本地已有模型的话）。

## 定位与适用边界

**本仓库分发的是一套「底稿工具」，不是一个「成片工具」。**

h3-turbo-models 提供的折叠 4 步 Turbo 权重，目标是把本地视频生成的
**试错成本**压到最低，而不是在本地复现官方 H3 的 2K 成片质量。它服务
于同一个工作流的上游环节：**在本地快速把「想拍什么」想清楚，再把确定
的方案交给官方 API 出终稿。**

---

## 模型索引

| 模型 | 模式 | 大小 | ModelScope |
|---|---|---|---|
| **MiniMax-H3-FL2V-Turbo-4Step** | 首尾帧生视频（FL2V） | ~62 GB | `luckybeet/MiniMax-H3-FL2V-Turbo-4Step` |
| **MiniMax-H3-Ref2V-Turbo-4Step** | 单参考图生视频（Ref2V） | ~62 GB | `luckybeet/MiniMax-H3-Ref2V-Turbo-4Step` |

> **关于分发平台的选择**：模型发布于魔搭（ModelScope）是受上传时效性
> 的务实选择——HuggingFace 在本环境网络下不可达。发布地不构成任何
> 偏好或排他声明；条件允许时同样可以考虑 HF 镜像。账号名以实际发布
> 为准。
>
> 每个仓库包含折叠后的 `transformer/` 目录；其余组件（video_vae /
> audio_vae / text_encoder / tokenizer）请从官方
> [MiniMax/MiniMax-H3](https://www.modelscope.cn/models/MiniMax/MiniMax-H3)
> 获取，组装方法见各仓库 model card。

## 快速开始

```sh
# 1. 获取 runner：h3.c 引擎（C + Metal，Apple Silicon 原生）
git clone https://github.com/antirez/h3.c
cd h3.c && make

# 2. 拉取模型（折叠版 transformer + 官方基础模型组件）
modelscope download --model MiniMax/MiniMax-H3
modelscope download --model luckybeet/MiniMax-H3-FL2V-Turbo-4Step
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

> **加速基线（随本仓库发布，可复现）**：在 M3 Max 128 GB 上，本仓库
> 脚本与配方相对原始 20 步流程实测约 **5×+** 加速（条件见上表）。
> 该数字对应本仓库发布的脚本与配方，不构成跨硬件承诺。
>
> **实验性上限（未随本仓库发布）**：本地进一步调优后可观察到 9×+ 的
> 加速比，但该结果依赖未公开的改动，不具备开箱可复现性，暂不计入
> 发布承诺。后续若优化稳定并随本仓库发布，会更新此处基线。
>
> 这个加速的意义在于让「多试几条」变得便宜，而不在于替代终稿渲染。

**脸部黄金法则**：人物面部需占画面 ≥25%（近景），Ref2V 配合高清参考图；
无人脸的环境内容用 FL2V/T2V 任意档。

折叠前后的实测对比帧见 [`examples/`](examples/)：同一 prompt/seed 下，
原版 20 步 vs Turbo 4/6 步的四联对比。

---

## 它适合做什么

- **生成结构底稿**：验证镜头运动、构图关系、人物站位、首尾帧衔接是否符合预期；
- **低成本方案筛选**：同一提示词或关键帧快速出多条 768p 级底稿，选定后再进入精修；
- **作为官方 API 的前置环节**：确定满意的底稿后，将同一提示词与关键帧提交至 MiniMax 官方 H3 API，进行 2K 终稿渲染。

## 它不适合做什么

- **不宣称、也不试图在本地复现官方 2K / Context-IR 的输出质量。** 官方开源 H3-Base 本身不包含 2K 工作流，自托管无法复现完整的官方 2K 链路——这是产品分层设计，不是本仓库的短板，也不是本仓库要绕过的目标。
- **不构成对 MiniMax 官方 API 的替代方案。** 本地底稿的清晰度、细节与稳定性均低于官方终稿档位，不应被当作成片交付。

## 与官方 API 的关系

本仓库的立场是：**本地折叠模型与官方 API 是同一工作流上的两个环节，而非竞争关系。**

本地侧降低的是「想清楚要什么」的成本；官方侧保留的是「最终画质」的
门槛。两者叠加，用户的总试错成本低于全程走 API，而官方获得的则是
意图更明确、转化率更高的 API 调用——用户不是在海量盲试中消耗额度，
而是在本地筛出满意构图后，带着明确目标进入终稿渲染。

这不是在分流 API 流量，而是在为 API 制造更多「已经想清楚要什么」的
付费意图。

---

## 许可

> ### ⚠️ 地域限制
> 本衍生模型遵循 **MiniMax H3 Community License Agreement**，
> **授权地域排除 EU / UK / 韩国 / 美国**。上述地区的用户获取、
> 使用或分发本模型均**不在授权范围内**。

折叠权重属于 MiniMax-H3 的 Model Derivatives（模型衍生作品），遵循
**MiniMax H3 Community License Agreement**，随各模型仓库附带的
`LICENSE` 与 `NOTICE.md` 为正式条款——**README 中的任何概括都不构成对
许可证的修改**。要点：

- **适用地域**：许可证默认授权范围排除 EU / UK / KR / US；
- **商业门槛**：许可证对年化收入或托管服务设有单独书面授权要求，
  具体阈值以 `LICENSE` 原文为准，本仓库不作口头概括；
- **输出归属**：生成内容（Outputs）的权利归使用者所有。

**数据边界**：本仓库不使用、也不会使用官方 API 的输出回流训练或改进
本地折叠模型。本地侧与官方侧是工作流上的两个环节，不存在用官方输出
「喂养」本地模型的关系。

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
