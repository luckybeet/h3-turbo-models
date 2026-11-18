# NOTICE

## What this repository contains

Consumer-side tooling and documentation:

- `README.md` — distribution index and usage guide
- `scripts/h3_turbo.sh` — one-shot CLI wrapper for the h3.c engine with
  production recipes for the folded checkpoints (MIT, same as this repo)
- `THANKS.md` — acknowledgments
- `LICENSE` — MIT, applies to everything in this repository

## What this repository does NOT contain

- **No model weights** — neither MiniMax-H3 base checkpoints, LoRA
  adapters, nor folded/derived checkpoints
- **No folding implementation** — the offline LoRA→checkpoint folding
  pipeline (and its format-trap handling) is not part of this repository

The folded Turbo models are distributed separately on ModelScope
(`luckybeet/MiniMax-H3-FL2V-Turbo-4Step`,
`luckybeet/MiniMax-H3-Ref2V-Turbo-4Step`); the runner engine is
[antirez/h3.c](https://github.com/antirez/h3.c).

## Weight licensing

The MiniMax-H3 model family is officially released under the **MiniMax H3
Community License Agreement** (dated August 2, 2026; official distributions:
`huggingface.co/MiniMaxAI/MiniMax-H3` and `modelscope.cn/MiniMax/MiniMax-H3`).
The folded checkpoints are **Model Derivatives** (modifications of the
weights), which the license permits you to use, reproduce, modify and
distribute, subject to:

1. **Territorial scope**: worldwide **excluding the EU, UK, Republic of
   Korea, and the United States**. Use/distribution outside the Applicable
   Territory is not licensed.
2. **Redistribution conditions**: every recipient must get a copy of the
   license agreement; modified files must carry prominent notices that they
   were modified; and every distribution must include a NOTICE file
   containing exactly:
   > MiniMax H3 is licensed under the MiniMax H3 Community License Agreement,
   > Copyright © 2026 MiniMax. All Rights Reserved.
3. **Commercial cap**: separate written authorization from MiniMax is required
   if your commercial products/services exceed **US$20M yearly revenue**;
   commercial UIs must display "MiniMax H3".
4. **Acceptable Use Policy** (Exhibit A of the license): standard
   prohibitions apply.
5. **Outputs**: MiniMax claims no rights over generation outputs — videos you
   generate are yours.
6. You may not use the outputs to train other AI models, and you may not
   relicense the weights under different terms.

Each folded-model repository on ModelScope ships its own `LICENSE` and
`NOTICE` files satisfying the redistribution conditions above.
