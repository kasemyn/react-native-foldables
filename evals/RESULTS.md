# Eval results

## 5 October 2026: with vs without the skill (Sonnet)

Rubric and prompts: [EVAL-SPEC.md](EVAL-SPEC.md), written before any run. Raw answers, grading and the unblinding key are in [runs-2026-10-05/](runs-2026-10-05/). `A` = with the skill, `B` = without.

| Prompt | With skill | Without | Max |
|---|---|---|---|
| E1 Review a screen | 7 | 7 (4 strict) | 7 |
| E2 Restart on an external monitor | 5 | 4 | 5 |
| E3 Build a two-pane layout | 6 | 2 | 6 |
| E4 Tab bar on iPhone Duo | 6 | 1 | 6 |
| E5 Snap the divider to the hinge | 5 | 3 | 6 |
| **Total** | **29** | **17** (14 strict) | 30 |

The blind grader preferred the with-skill answer on all five prompts. "Strict" removes two lenient calls the grader itself flagged on E1-B.

**Where the skill helped:**
- **Facts after the model's training cutoff.** Without the skill, E4 said it didn't know about the iPhone Duo.
- **Writing code.** Without the skill, E3 swapped element trees.
- **Edge cases.** The 240dp minimum pane width, measuring only while a hinge exists, and DisplayMetricsHolder.

**Where it didn't:** generic review (E1). The model already knows the common pitfalls.

**Fixed after this run:** RTL handling for hinge splits was missing from RULES §5, which cost the with-skill run its only point on E5.

## Caveats

- **One run per condition.** Treat differences of 1–2 points on a single prompt as noise. The E3 and E4 gaps are large enough to matter.
- **Partial blinding.** References to the skill were stripped (`blind.sh`) and labels shuffled. Phrases like "the guide's static check" survived, so a careful grader could guess the condition.
- **Sonnet graded Sonnet.**
- **Circular rubric.** The rubric was written from the same research as the skill, so it rewards what the skill teaches. That is fair only if the facts are right, which is why [../STATUS.md](../STATUS.md) carries sources and a date.

## Re-running

For each prompt in EVAL-SPEC.md:
1. Run one agent with the fixture and the instruction to read `SKILL.md` first, and one without. Both have no web access.
2. Keep both agents away from `evals/`. It contains the rubric and past answers.
3. Run `bash blind.sh <eval-dir>`.
4. Grade with a fresh agent that sees only the rubric, the fixtures and `blind/`.
