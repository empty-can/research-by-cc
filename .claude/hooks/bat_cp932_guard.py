#!/usr/bin/env python3
"""Let Claude work on CP932 .bat files without ever corrupting them.

`.bat` must stay CP932 on disk: cmd.exe does not skip a BOM (it breaks line 1),
and putting `chcp 65001` at the top degrades console rendering. Claude's file
tools assume UTF-8, so they read a CP932 .bat as mojibake and would write UTF-8
back over it. The original is therefore never handed to the file tools.

    read   PreToolUse rewrites Read's file_path to a UTF-8 shadow under
           .claude/.bat-shadow/ -- updatedInput works for Read.
    guide  PostToolUse(Read) tells Claude to edit that shadow, not the original.
    write  PostToolUse compiles an edited shadow back to CP932 + CRLF, but only
           after checking that the shadow still belongs to that original and the
           original has not changed underneath it. Anything unexpected -- a
           character with no CP932 code point, a stale shadow, a tampered
           sidecar, a failed write -- blocks and leaves the original untouched.
    block  settings.json denies Edit/Write on *.bat outright. updatedInput is
           IGNORED by Edit and Write (measured) -- they would reach the original
           and write UTF-8 into it -- and a hook cannot be the guarantee anyway:
           with no Python on PATH it cannot run (the Read guard in settings.json
           carries onFailure: "block" since v2.1.295 so a failed start blocks the
           Read; versions below the kit's minimum, v2.1.295, are out of scope). The deny rule is the hard guard;
           this script is the convenience. Hence the shadow is *.utf8.txt and not
           *.bat: deny beats allow, so a shadow named *.bat would be caught by the
           very rule that protects the original.

The sidecar (<shadow>.origin) records the original's path AND a hash of its bytes.
Both are checked before writing: without the path check the sidecar is an
arbitrary-file-write primitive (it names the destination), and without the hash
check a stale shadow silently reverts an original that git or the user changed.

Modes:
    pre / post   hook entry points (see .claude/settings.json)
    new <path>   scaffold a new .bat (Write is denied, so Claude cannot create one)
    sync         refresh every shadow, so Grep over .claude/.bat-shadow/ can search
                 .bat content that Grep cannot match in CP932
"""
import hashlib
import json
import os
import pathlib
import subprocess
import sys

# Python writes pipes in the ANSI code page on Windows (cp932 on a Japanese
# machine), so a JSON message containing a character outside CP932 -- which is
# exactly what the block message reports -- dies with UnicodeEncodeError and the
# hook exits non-zero WITHOUT blocking. The guard would fail open in the one case
# it exists for. (This is invisible on a machine with PYTHONIOENCODING=utf-8 set.)
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="backslashreplace")
    except (AttributeError, ValueError):  # pragma: no cover - very old Python
        pass

SHADOW_SUBDIR = pathlib.PurePosixPath(".claude/.bat-shadow")
SHADOW_SUFFIX = ".utf8.txt"
ORIGIN_SUFFIX = ".origin"

# Characters such as the em dash (U+2014) have no CP932 code point but do have a
# CP932 counterpart; normalise them instead of rejecting the write-back. (The wave
# dash U+301C does encode: Python's cp932 maps it to 0x8160, same as U+FF5E.) The table in
# the win-file-encoding skill is the source of truth -- this is only the fallback.
MAPPING_JSON = pathlib.PurePosixPath(
    ".claude/skills/win-file-encoding/references/cp932-mapping.json"
)
FALLBACK_TO_WIN = {"〜": "～", "−": "－", "—": "―", "‖": "∥", "¢": "￠", "£": "￡", "¬": "￢"}


def project_root() -> pathlib.Path:
    return pathlib.Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())


def shadow_root() -> pathlib.Path:
    return project_root() / SHADOW_SUBDIR


def is_shadow(path: pathlib.Path) -> bool:
    try:
        return shadow_root().resolve() in path.resolve().parents
    except OSError:
        return False


def shadow_for(src: pathlib.Path) -> pathlib.Path:
    """Mirror the project-relative path so two same-named .bat never collide."""
    try:
        rel = src.resolve().relative_to(project_root().resolve())
    except (ValueError, OSError):
        # Outside the project: the bare name would let A/run.bat and B/run.bat share
        # one shadow, and whichever was read last would receive the other's edits.
        tag = hashlib.sha256(str(src).encode("utf-8")).hexdigest()[:12]
        rel = pathlib.Path("_external") / f"{tag}__{src.name}"
    return shadow_root() / rel.with_name(rel.name + SHADOW_SUFFIX)


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def to_win_map() -> dict:
    try:
        data = json.loads((project_root() / MAPPING_JSON).read_text(encoding="utf-8"))
        return data.get("to_win") or FALLBACK_TO_WIN
    except (OSError, ValueError):
        return FALLBACK_TO_WIN


def normalise(text: str) -> str:
    for src, dst in to_win_map().items():
        text = text.replace(src, dst)
    return text


def unmappable(text: str) -> list:
    bad = []
    for ch in dict.fromkeys(text):
        try:
            ch.encode("cp932")
        except UnicodeEncodeError:
            bad.append(f"{ch} (U+{ord(ch):04X})")
    return bad


def emit(obj: dict) -> int:
    json.dump(obj, sys.stdout, ensure_ascii=False)
    return 0


def block(reason: str) -> int:
    return emit(
        {
            "decision": "block",
            "reason": reason,
            "hookSpecificOutput": {"hookEventName": "PostToolUse"},
        }
    )


# --- shadow lifecycle --------------------------------------------------------


def refresh(src: pathlib.Path) -> pathlib.Path:
    """Rebuild the shadow from the original. Raises UnicodeDecodeError if not CP932."""
    # The sidecar must record an ABSOLUTE path: it is later fed back through
    # shadow_for() to prove the shadow belongs to that original, and a relative path
    # would resolve against whatever directory the hook happens to run in.
    src = src.resolve()
    raw = src.read_bytes()
    text = raw.decode("cp932")
    shadow = shadow_for(src)
    shadow.parent.mkdir(parents=True, exist_ok=True)
    shadow.write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")
    sidecar(shadow).write_text(
        json.dumps({"origin": str(src), "sha256": hashlib.sha256(raw).hexdigest()}),
        encoding="utf-8",
    )
    return shadow


def sidecar(shadow: pathlib.Path) -> pathlib.Path:
    return shadow.with_name(shadow.name + ORIGIN_SUFFIX)


def read_sidecar(shadow: pathlib.Path) -> tuple:
    """Return (origin, recorded_sha256) or (None, None) if unusable."""
    ref = sidecar(shadow)
    if not ref.is_file():
        return None, None
    try:
        data = json.loads(ref.read_text(encoding="utf-8"))
        origin = pathlib.Path(data["origin"])
        return origin, data.get("sha256")
    except (OSError, ValueError, KeyError, TypeError):
        return None, None


def looks_like_utf8(raw: bytes) -> bool:
    """A UTF-8 .bat usually still decodes as CP932 -- into mojibake. Catch that."""
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return False
    return any(ord(ch) > 127 for ch in text)


# --- hook entry points -------------------------------------------------------


def handle_pre(tool: str, path: pathlib.Path, tool_input: dict) -> int:
    if is_shadow(path) or tool != "Read" or not path.is_file():
        return 0

    raw = path.read_bytes()
    if looks_like_utf8(raw):
        print(
            f"{path} は UTF-8 で保存されているように見える（.bat は CP932 で保存する）。"
            f"CP932 として読むと文字化けするため中止した。"
            f"変換: python .claude/skills/win-file-encoding/scripts/convert_encoding.py --to-win \"{path}\"",
            file=sys.stderr,
        )
        return 2
    try:
        shadow = refresh(path)
    except UnicodeDecodeError as exc:
        print(f"{path} を CP932 として読めない（{exc}）。この .bat は CP932 ではない。", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"{path} の作業コピーを作れない（{exc}）。", file=sys.stderr)
        return 2

    # updatedInput replaces the whole input object, so unchanged fields (offset /
    # limit) must be carried over or a ranged Read silently becomes a full Read.
    updated = dict(tool_input)
    updated["file_path"] = str(shadow)
    return emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": updated,
            }
        }
    )


def guide(src: pathlib.Path, shadow: pathlib.Path, stale: bool) -> int:
    warn = ""
    if stale:
        warn = (
            "  ⚠ この作業コピーは原本より古い（原本が git 操作や人手で変更された）。"
            "原本を Read し直して作業コピーを作り直すこと。今のまま保存しても書き戻しは拒否される。"
        )
    return emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"[bat-cp932-guard] {src.name} は CP932 で保存する .bat のため、"
                    f"いま読んだのは UTF-8 の作業コピー {shadow} である。"
                    f"編集するときは原本ではなく**この作業コピーを Edit すること**"
                    f"（原本への Edit / Write は permissions.deny で拒否される）。"
                    f"保存すると自動で CP932 + CRLF へ書き戻される。"
                    f"CP932 に存在しない文字（⚠ ✓ ✗ ‼ 等の記号）は書き戻し時に拒否されるので、"
                    f"メッセージ記号は ASCII（[!] / [OK] 等）を使うこと"
                    f"（〜 や — のような和字は CP932 の対応字へ自動正規化されるので使ってよい）。{warn}"
                ),
            }
        }
    )


def handle_post(tool: str, path: pathlib.Path) -> int:
    if not is_shadow(path) or not path.is_file():
        return 0

    src, recorded = read_sidecar(path)
    if src is None:
        return block(
            f"{path.name} は作業コピーだが、対応する原本の情報（{ORIGIN_SUFFIX} サイドカー）が無い/壊れている。"
            f"**原本には何も書き戻していない**。新規の .bat を作るなら "
            f"`python .claude/hooks/bat_cp932_guard.py new <path>.bat` を使い、"
            f"既存の .bat を編集するなら原本を Read し直すこと。"
        )

    # The sidecar names the file we are about to write. Without these checks it is an
    # arbitrary-file-write primitive: anyone who can write the shadow (it is not
    # covered by the deny rule) could point it at any path on disk.
    if src.suffix.lower() != ".bat" or shadow_for(src) != path:
        return block(
            f"作業コピー {path.name} と原本 {src} の対応が不正（原本が .bat でない、または"
            f"この作業コピーの写像先ではない）。**原本には何も書き戻していない**。"
            f"作業コピーは原本を Read して作られたものだけを編集すること。"
        )

    if tool == "Read":
        stale = src.is_file() and recorded is not None and digest(src) != recorded
        return guide(src, path, stale)

    if not src.is_file():
        return block(
            f"原本 {src} が存在しない。**何も書き戻していない**。"
            f"原本が削除・移動された可能性がある。Read し直すこと。"
        )
    if recorded is None or digest(src) != recorded:
        return block(
            f"原本 {src.name} は作業コピーを作った後に変更されている"
            f"（git 操作・人手の編集など）。上書きすると相手の変更が消えるため"
            f"**書き戻していない**。原本を Read し直して作業コピーを作り直し、編集をやり直すこと。"
        )

    text = normalise(path.read_text(encoding="utf-8"))
    bad = unmappable(text)
    if bad:
        return block(
            f"{src.name} は CP932 で保存する必要があるが、CP932 に存在しない文字が含まれている: "
            f"{', '.join(bad)}。**原本は書き換えていない**。"
            f"これらを ASCII（[!] / [OK] 等）へ置き換えて編集し直すこと。"
        )

    body = text.replace("\r\n", "\n").replace("\n", "\r\n")
    try:
        raw = body.encode("cp932")
        src.write_bytes(raw)
    except OSError as exc:
        return block(
            f"原本 {src} へ書き戻せない（{exc}）。**原本は変更されていない可能性が高いが、"
            f"内容を確認すること**。ファイルがロックされている・読み取り専用の可能性がある。"
        )
    sidecar(path).write_text(
        json.dumps({"origin": str(src), "sha256": hashlib.sha256(raw).hexdigest()}),
        encoding="utf-8",
    )
    return 0


def run_hook(phase: str) -> int:
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            return 0
        tool_input = payload.get("tool_input")
        if not isinstance(tool_input, dict):
            return 0
        raw = tool_input.get("file_path")
        if not isinstance(raw, str) or not raw:
            return 0

        path = pathlib.Path(raw)
        # The `if` conditions in settings.json already narrow this down, but they fail
        # open, so re-check: we touch originals (*.bat) and their shadows, nothing else.
        if not raw.lower().endswith(".bat") and not is_shadow(path):
            return 0

        tool = payload.get("tool_name", "")
        if phase == "pre":
            return handle_pre(tool, path, tool_input)
        return handle_post(tool, path)
    except Exception as exc:  # stay out of the way rather than break the tool call
        print(f"bat_cp932_guard: 想定外のエラー（{exc!r}）", file=sys.stderr)
        return 0


# --- CLI modes ---------------------------------------------------------------


def mode_new(target: str) -> int:
    src = pathlib.Path(target)
    if src.suffix.lower() != ".bat":
        print(f"'{target}' は .bat ではない。", file=sys.stderr)
        return 1
    if src.exists():
        print(f"'{target}' は既に存在する。Read してから作業コピーを編集すること。", file=sys.stderr)
        return 1
    src.parent.mkdir(parents=True, exist_ok=True)
    src.write_bytes("@echo off\r\n".encode("cp932"))
    shadow = refresh(src)
    print(f"作成した: {src}（CP932 + CRLF・空の .bat）")
    print(f"以降はこの作業コピーを Edit すること: {shadow}")
    return 0


def ignored(paths: list) -> set:
    """Paths git would ignore. Empty set when git is unavailable -- sync is best-effort."""
    if not paths:
        return set()
    root = project_root()
    # check-ignore only accepts repo-relative, forward-slash paths: a Windows absolute
    # path is read as C-style escapes ("\b" -> backspace) and git rejects it.
    rel = {}
    for p in paths:
        try:
            rel[p.relative_to(root).as_posix()] = p
        except ValueError:
            continue
    if not rel:
        return set()
    try:
        # -z, and bytes rather than text=True: on Windows text mode rewrites the "\n"
        # separators to "\r\n", so git sees paths ending in CR and echoes them back
        # quoted -- every lookup then misses and nothing gets filtered.
        proc = subprocess.run(
            ["git", "-C", str(root), "check-ignore", "--stdin", "-z"],
            input="\0".join(rel).encode("utf-8"),
            capture_output=True,
        )
    except OSError:
        return set()
    out = proc.stdout.decode("utf-8", "replace")
    return {rel[token] for token in out.split("\0") if token in rel}


def mode_sync() -> int:
    root = project_root()
    candidates = [
        p
        for p in root.rglob("*.bat")
        if p.is_file() and not is_shadow(p) and ".git" not in p.parts
    ]
    skip = ignored(candidates)  # build artefacts and session work dirs are not interesting
    count, skipped = 0, []
    for src in candidates:
        if src in skip:
            continue
        try:
            refresh(src)
            count += 1
        except (UnicodeDecodeError, OSError) as exc:
            skipped.append(f"{src}: {exc}")
    print(f"作業コピーを更新: {count} 件 -> {shadow_root()}")
    if skipped:
        print("読めずスキップ（CP932 でない・権限がない等）:", file=sys.stderr)
        for s in skipped:
            print(f"  {s}", file=sys.stderr)
    print("Grep で .bat の中身を検索するときは .claude/.bat-shadow/ を対象にすること。")
    return 0


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "pre"
    if mode in ("pre", "post"):
        return run_hook(mode)
    if mode == "new":
        if len(sys.argv) < 3:
            print("使い方: bat_cp932_guard.py new <作成する .bat のパス>", file=sys.stderr)
            return 1
        return mode_new(sys.argv[2])
    if mode == "sync":
        return mode_sync()
    print(f"不明なモード: {mode}（pre / post / new / sync）", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
