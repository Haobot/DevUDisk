# Debug Session: trae-sandbox-arg-error

**Status**: `[OPEN]`
**Created**: 2026-06-17
**Session ID**: `trae-sandbox-arg-error`

## Problem Description

User reports that `trae-sandbox.exe exec` repeatedly emits:

```
error: unexpected argument 'Start-Sleep' found

Usage: trae-sandbox.exe exec [OPTIONS] --storage-path <STORAGE_PATH> --config-name <CONFIG_NAME> --shell-path <SHELL_PATH> --command-line <COMMAND_LINE>
```

User has pasted this exact error text three times in a row without additional context. The user does not appear to be answering direct questions.

## Already-Confirmed Facts (Static Evidence)

- `grep -r "Start-Sleep"` across the entire `d:\` tree (bat/cmd/ps1/json/md/sh/toml/yml/yaml/ini/xml/code-workspace/tasks/settings) → **0 matches**
- `grep -r "trae-sandbox"` across the entire `d:\` tree → **0 matches**
- `trae-sandbox.exe` is a Rust binary (clap-rs style error) — not part of the DevUDisk project
- DevUDisk project uses `ping -n 2 127.0.0.1 >nul` and `$proc.WaitForExit(2000)` for delays — no `Start-Sleep` anywhere
- The `StartDevEnv.bat` modifications made earlier (RAMDisk letter auto-fallback) do not invoke `Start-Sleep`

## Hypotheses (5)

| ID | Hypothesis | Likelihood | Effort | Expected Signal |
|----|------------|------------|--------|-----------------|
| A | User manually executed a PowerShell command containing `Start-Sleep` in the Trae terminal | High | Low | PowerShell ReadLine history (`$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`) contains the exact command line |
| B | A Trae IDE extension (Continue / Trae AI / Code Runner) is repeatedly triggering PowerShell via trae-sandbox with malformed args | Medium | Medium | Recurring `trae-sandbox.exe` processes with `ParentProcessId` pointing to a `Code.exe` / extension host child process |
| C | `trae-sandbox.exe` config / storage is corrupt | Low | Low | Storage path contains a malformed config file referencing `Start-Sleep` |
| D | Trigger source is a DevUDisk project script being executed by Trae | Very Low | Low | Already falsified by grep |
| E | User is pasting this from an external source (clipboard / web page / history) and the error has no live trigger in their current session | Medium | Low | No `trae-sandbox.exe` process active in `Get-Process` |

## Blocking Issue

Step 6 (Interactive Reproduction) **cannot proceed** because:
- The user has not answered the previous round's diagnostic questions
- The trigger source is not in the project, so instrumentation on project code would be useless
- A `Debug Server` cannot collect evidence from a process we cannot identify

## Required User Input

To break out of this loop, the user must provide **at least one** of:

1. The exact command line that produced this error (full string, including the `trae-sandbox.exe exec ...` prefix)
2. The output of `Get-CimInstance Win32_Process -Filter "Name='trae-sandbox.exe'" | Format-List` run **while the error is occurring**
3. Confirmation that this is being pasted from an external source (web page, README, screenshot, etc.) and is **not** currently being produced in their environment

If none of the above can be provided, the user is encouraged to select **D. Abort debugging** to clean up this session.

## Cleanup Status

- No instrumentation added (none was appropriate — bug is not in project code)
- No Debug Server started (no instrumentation to receive logs)
- Only artifact is this `debug-trae-sandbox-error.md` file
