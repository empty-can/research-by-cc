#!/usr/bin/env python3
"""Fail a PowerShell-file edit that dropped the UTF-8 BOM or broke the CRLF endings.

Windows PowerShell 5.1 reads a BOM-less .ps1 as CP932, so a lost BOM silently
mojibakes every Japanese string in the script -- and the BOM is file *content*,
which .gitattributes cannot restore. Claude Code's own file tools have twice
regressed here (v2.1.77: Write silently converted line endings when overwriting
a CRLF file; v2.1.89: Edit/Write doubled CRLF on Windows), and the docs specify
no contract for either, so this is checked rather than assumed.

Measured on this repo: Edit preserves BOM + CRLF, Write does not -- a .ps1
created with Write lands as BOM-less LF.

Wired as a PostToolUse hook on Edit/Write of PowerShell files (see settings.json).
Rewriting the file from the hook would fight the tool that just wrote it, so this
reports and lets Claude fix it.
"""
import json
import pathlib
import sys

# Python writes pipes in the ANSI code page on Windows (cp932 on a Japanese machine),
# so a JSON message with any non-CP932 character dies with UnicodeEncodeError and the
# hook exits non-zero without blocking. Force UTF-8 so the report actually arrives.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="backslashreplace")
    except (AttributeError, ValueError):  # pragma: no cover - very old Python
        pass

BOM = b"\xef\xbb\xbf"
SUFFIXES = (".ps1", ".psm1", ".psd1", ".ps1.template")


def newline_problem(data: bytes) -> str:
    """Empty string when every line ends CRLF."""
    rest = data.replace(b"\r\n", b"")
    if b"\n" in rest and b"\r" in rest:
        return "改行が CRLF / LF / CR で混在している"
    if b"\n" in rest:
        return "LF だけの行が混ざっている（CRLF が必要）"
    if b"\r" in rest:
        return "CR だけの行が混ざっている（CRLF が必要）"
    return ""


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            return 0
        tool_input = payload.get("tool_input")
        if not isinstance(tool_input, dict):
            return 0
        raw = tool_input.get("file_path")
        if not isinstance(raw, str) or not raw.lower().endswith(SUFFIXES):
            return 0

        path = pathlib.Path(raw)
        if not path.is_file():
            return 0

        data = path.read_bytes()
        problems = []
        if not data.startswith(BOM):
            problems.append(
                "UTF-8 BOM が無い（Windows PowerShell 5.1 が CP932 と誤読して日本語が化ける）"
            )
        eol = newline_problem(data)
        if eol:
            problems.append(eol)
        if not problems:
            return 0

        quoted = str(path).replace("'", "''")  # a Windows path may legally contain '
        fix = (
            "PowerShell で直す:\n"
            f"  $p = '{quoted}'\n"
            "  $t = [System.IO.File]::ReadAllText($p, [System.Text.UTF8Encoding]::new($false))\n"
            "  $t = $t -replace \"`r`n\", \"`n\" -replace \"`n\", \"`r`n\"\n"
            "  [System.IO.File]::WriteAllText($p, $t, [System.Text.UTF8Encoding]::new($true))"
        )
        json.dump(
            {
                "decision": "block",
                "reason": (
                    f"{path.name} の保存形式が壊れている: {' / '.join(problems)}。\n"
                    f"PowerShell ファイルは **UTF-8 + BOM + CRLF** で保存する"
                    f"（Write ツールは BOM も CRLF も保持しないため、新規作成すると必ずこうなる）。\n{fix}"
                ),
                "hookSpecificOutput": {"hookEventName": "PostToolUse"},
            },
            sys.stdout,
            ensure_ascii=False,
        )
        return 0
    except Exception as exc:  # stay out of the way rather than break the tool call
        print(f"ps1_bom_crlf_check: 想定外のエラー（{exc!r}）", file=sys.stderr)
        return 0


if __name__ == "__main__":
    sys.exit(main())
