# react-native-foldables

An agent skill for building and auditing React Native apps on screens that change shape: Android foldables and flip phones, resizable and desktop windows (tablets, phones on a monitor, iPad Split View, iPhone Mirroring) and Apple's iPhone Duo.

> **Demo project.** This skill was put together for a live demo at the **React Native community meetup in London on 22 October 2026**. It is shared so attendees can try it themselves. It is not a maintained library, and the version-sensitive facts in [STATUS.md](STATUS.md) are only accurate as of the date written there.

## The one rule

**Branch on the window you're given, never on the device you think you're on.** Your app doesn't own the screen. It gets a window, and that window changes size, splits around a hinge and moves between displays while the app runs.

## What's in here

| File | What it is |
|---|---|
| [SKILL.md](SKILL.md) | Entry point the agent loads: workflows for writing code and auditing an app |
| [RULES.md](RULES.md) | The rules, by topic: layout, subscriptions, state across layout changes, Android manifest, hinges, safe areas, iOS / iPhone Duo, overlays, testing |
| [STATUS.md](STATUS.md) | Version-sensitive facts (SDKs, library releases, open issues) with sources and an "as of" date |
| [scripts/audit.sh](scripts/audit.sh) | Static checks you run from an app's root. Prints `SEVERITY path:line — problem — fix` and exits 1 on anything blocking |
| [examples/](examples/) | A tested `useWindowWidthClass` hook, plus a test that keeps RULES.md in sync with it |
| [evals/](evals/) | Blind A/B evals comparing agent output with and without the skill, with the run results |

## Install

Clone it into a skills directory that your agent reads. For Claude Code:

```bash
# Available in every project
git clone https://github.com/kasemyn/react-native-foldables.git ~/.claude/skills/react-native-foldables

# Or just one project
git clone https://github.com/kasemyn/react-native-foldables.git .claude/skills/react-native-foldables
```

## Use

In a React Native or Expo app, either call the skill directly:

```
/react-native-foldables audit this app
```

or ask something that matches it, for example "does my app work on a foldable?" or "review this screen for Split View". The agent picks the skill up on its own.

You can also run the static checks without an agent:

```bash
bash ~/.claude/skills/react-native-foldables/scripts/audit.sh path/to/app
```

## Development

```bash
bash scripts/test-audit.sh   # audit script regression suite, against scripts/fixtures/
```

The hook tests in `examples/` need React Native's Jest tooling, so run them from inside an RN app (see SKILL.md).
