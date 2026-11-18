# THANKS

## 基座

> 所有站在基座上的工作，都应该先说出基座的名字。

**h3.c** 是 antirez（Salvatore Sanfilippo，Redis 之父）用 C 和 Metal
写给 Apple Silicon 的作品——[github.com/antirez/h3.c](https://github.com/antirez/h3.c)，
视频推理引擎领域的第二次出手。3072 个 star 证明了一件事：**你不必等待
大厂，一个程序员（和他的 AI 伙伴）就能把 22B 的视频模型跑进 128 GB
统一内存里。**

Turbo 折叠模型的价值只有一半属于折叠本身——另一半属于那个让模型跑得
飞快的引擎。h3.c 就是那一半。

> Credit where it is due: every tool that stands on a foundation should
> name the foundation first. **h3.c** is antirez's second act after
> Redis — a C + Metal video inference engine proving that one programmer
> and an AI collaborator can run a 22B video model in 128 GB of unified
> memory. Half the value of the Turbo checkpoints belongs to the engine
> that runs them.

## 社区

- **MiniMax** — the H3 model family and the Turbo LoRA adapters
  (Community License Agreement, distributed officially on HuggingFace
  and ModelScope).
- **ComfyUI ecosystem** — whose generic LoRA format is the de-facto
  standard the adapters come in.
- **[PR #14](https://github.com/antirez/h3.c/pull/14)** (guyz) — a fellow
  traveler on the same road: offline LoRA folding for h3.c. If you find
  this index, read that PR too. Same destination, different route.
- **[Issue #37](https://github.com/antirez/h3.c/issues/37)** ("LoRA
  support") — where we registered our production experience: runtime
  merge works and is fast (12× denoise on M3 Max); folded checkpoints
  ship on ModelScope. Upstreaming, if ever welcome, would follow the
  engine author's code conventions.

## 关于折叠实现

折叠模型的生成方法（离线 LoRA→checkpoint 折叠，含全部 ComfyUI 格式陷阱
的处理）**未随本仓库公开**。模型以「已验证的成品」形式在 ModelScope
分发；runner 在 h3.c。本仓库只提供消费端配套：一键脚本与实测配方。
