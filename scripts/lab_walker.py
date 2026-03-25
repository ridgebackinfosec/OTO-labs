#!/usr/bin/env python3
"""lab_walker.py — OTO Labs step-by-step terminal walker.

Parses bash command blocks from each lab's index.md and walks students
through them one at a time. Each command runs with full terminal control
via App.suspend() so interactive prompts (sudo, nano, etc.) work correctly.

Launch via:  lab-walker
"""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

import yaml
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal
from textual.screen import Screen
from textual.widgets import Footer, Header, ListItem, ListView, Label, RichLog, Static

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class Step:
    command: str
    explanation: list[str] = field(default_factory=list)
    run_count: int = 0


@dataclass
class Lab:
    name: str
    path: Path


@dataclass
class DayGroup:
    name: str
    labs: list[Lab]


# ── Markdown parser ───────────────────────────────────────────────────────────

def parse_steps(filepath: Path) -> list[Step]:
    """Extract bash command steps and optional explanations from a lab index.md.

    Rules:
    - Collects every ```bash ... ``` block (indented or not).
    - Skips content inside HTML comments (<!-- ... -->).
    - Attaches the following ???- note "Command Options/Arguments Explained"
      block (if present) as the step's explanation lines.
    """
    lines = filepath.read_text(encoding="utf-8").splitlines()
    steps: list[Step] = []
    i = 0
    in_html_comment = False

    while i < len(lines):
        line = lines[i]

        # ── HTML comment tracking ──────────────────────────────────────────
        if not in_html_comment:
            if "<!--" in line:
                # Same-line comment (<!-- ... -->) or block-open (<!--)
                if "-->" not in line:
                    in_html_comment = True
                i += 1
                continue
        else:
            if "-->" in line:
                in_html_comment = False
            i += 1
            continue

        # ── Bash fence detection ───────────────────────────────────────────
        bash_match = re.match(r'^(\s*)```bash\s*$', line)
        if not bash_match:
            i += 1
            continue

        indent = bash_match.group(1)
        i += 1

        # Collect command lines until the closing fence
        cmd_lines: list[str] = []
        while i < len(lines):
            raw = lines[i]
            # Closing fence: same indent (or less) + ```
            if re.match(r'^\s*```\s*$', raw):
                i += 1
                break
            # Strip block indent from content lines
            if indent and raw.startswith(indent):
                raw = raw[len(indent):]
            cmd_lines.append(raw)
            i += 1

        command = "\n".join(cmd_lines).strip()
        if not command:
            continue

        # ── Look ahead for explanation block ──────────────────────────────
        j = i
        # Skip blank lines between the fence and a potential explanation
        while j < len(lines) and lines[j].strip() == "":
            j += 1

        explanation: list[str] = []
        if j < len(lines) and re.match(
            r'^\s*\?\?\?-\s+note\s+"Command Options/Arguments Explained"\s*$',
            lines[j],
            re.IGNORECASE,
        ):
            j += 1
            # Collect 4-space-indented lines; blank lines inside block are skipped
            while j < len(lines):
                expl_line = lines[j]
                if expl_line.strip() == "":
                    j += 1
                    continue
                # Non-blank, non-indented line signals end of admonition block
                if not expl_line.startswith("    "):
                    break
                explanation.append(expl_line[4:].rstrip())
                j += 1

        steps.append(Step(command=command, explanation=explanation))

    return steps


# ── Nav loader ────────────────────────────────────────────────────────────────

def load_labs() -> list[DayGroup]:
    """Parse mkdocs.yml nav to get ordered labs grouped by day section."""
    mkdocs_path = REPO_ROOT / "mkdocs.yml"
    raw = mkdocs_path.read_text(encoding="utf-8")
    # Strip !!python/name:... tags that require mkdocs modules to be loaded
    raw = re.sub(r"!!python/\S+", "", raw)
    config = yaml.safe_load(raw)

    nav = config.get("nav", [])
    groups: list[DayGroup] = []

    for entry in nav:
        if not isinstance(entry, dict):
            continue
        for section_name, section_items in entry.items():
            # Skip top-level page entries (e.g. "Home: index.md")
            if not isinstance(section_items, list):
                continue
            labs: list[Lab] = []
            for item in section_items:
                if not isinstance(item, dict):
                    continue
                for lab_name, lab_path in item.items():
                    full_path = REPO_ROOT / "docs" / lab_path
                    if full_path.exists():
                        labs.append(Lab(name=lab_name, path=full_path))
            if labs:
                groups.append(DayGroup(name=section_name, labs=labs))

    return groups


# ── Screens ───────────────────────────────────────────────────────────────────

class LabMenuScreen(Screen):
    """Lab selection screen — lists all labs grouped by day."""

    BINDINGS = [Binding("q", "quit_app", "Quit")]

    def __init__(self, groups: list[DayGroup]) -> None:
        super().__init__()
        self.groups = groups
        # Parallel list: Lab for selectable items, None for day-header items
        self._item_labs: list[Lab | None] = []

    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        items: list[ListItem] = []
        for group in self.groups:
            items.append(
                ListItem(Label(f" {group.name} ", classes="day-label"), classes="day-item")
            )
            self._item_labs.append(None)
            for lab in group.labs:
                items.append(ListItem(Label(f"  {lab.name}")))
                self._item_labs.append(lab)
        yield ListView(*items, id="lab-list")
        yield Footer()

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        idx = event.list_view.index
        if idx is None:
            return
        lab = self._item_labs[idx]
        if lab is None:
            return  # Day header — not selectable
        steps = parse_steps(lab.path)
        if not steps:
            self.notify(f"No bash steps found in '{lab.name}'.", severity="warning")
            return
        self.app.push_screen(LabWalkerScreen(lab=lab, steps=steps))

    def action_quit_app(self) -> None:
        self.app.exit()


class LabWalkerScreen(Screen):
    """Step-by-step command walker for a single lab."""

    BINDINGS = [
        Binding("enter", "run_step", "Run", show=True),
        Binding("n", "next_step", "Next", show=True),
        Binding("p", "prev_step", "Prev", show=True),
        Binding("b", "back_to_menu", "Menu", show=True),
        Binding("q", "quit_app", "Quit", show=True),
    ]

    def __init__(self, lab: Lab, steps: list[Step]) -> None:
        super().__init__()
        self.lab = lab
        self.steps = steps
        self.current_index = 0

    # ── Layout ────────────────────────────────────────────────────────────────

    def compose(self) -> ComposeResult:
        with Horizontal(id="step-header"):
            yield Static("", id="lab-title")
            yield Static("", id="step-counter")
        yield Static("", id="command-panel")
        yield Static("", id="explanation-panel")
        yield RichLog(id="output-panel", highlight=False, markup=False, wrap=True)
        yield Footer()

    def on_mount(self) -> None:
        self._render_step()

    # ── Rendering ─────────────────────────────────────────────────────────────

    def _render_step(self) -> None:
        step = self.steps[self.current_index]

        # Header bar
        self.query_one("#lab-title", Static).update(
            Text(self.lab.name, style="bold")
        )
        done_mark = " ✓" if step.run_count > 0 else ""
        self.query_one("#step-counter", Static).update(
            f"Step {self.current_index + 1} of {len(self.steps)}{done_mark}"
        )

        # Command pane: prefix each line with "$ "
        cmd_lines = step.command.splitlines()
        cmd_text = Text()
        for cmd_line in cmd_lines:
            cmd_text.append("$ ", style="bold green")
            cmd_text.append(cmd_line + "\n")
        self.query_one("#command-panel", Static).update(cmd_text)

        # Explanation pane
        expl_widget = self.query_one("#explanation-panel", Static)
        bullet_lines = [l for l in step.explanation if l.strip()]
        if bullet_lines:
            expl_text = Text()
            for bline in bullet_lines:
                # Render leading "- " or "* " as a bullet, rest as plain text
                clean = re.sub(r'^[-*]\s*', "", bline)
                expl_text.append("  • ", style="dim")
                expl_text.append(clean + "\n")
            expl_widget.update(expl_text)
            expl_widget.display = True
        else:
            expl_widget.update("")
            expl_widget.display = False

        # Clear output pane
        self.query_one("#output-panel", RichLog).clear()

    # ── Actions ───────────────────────────────────────────────────────────────

    def action_run_step(self) -> None:
        step = self.steps[self.current_index]
        output_log = self.query_one("#output-panel", RichLog)
        step_counter = self.query_one("#step-counter", Static)

        output_log.clear()
        output_log.write(Text("Running…", style="dim"))

        # suspend() restores the terminal to normal mode so sudo password
        # prompts, nano, and all other interactive commands work correctly.
        with self.app.suspend():
            result = subprocess.run(["bash", "-c", step.command])

        step.run_count += 1
        step_counter.update(
            f"Step {self.current_index + 1} of {len(self.steps)} ✓"
        )
        output_log.clear()
        rc = result.returncode
        output_log.write(Text(
            f"[exit {rc}]",
            style="dim" if rc == 0 else "bold red",
        ))

    def action_next_step(self) -> None:
        if self.current_index < len(self.steps) - 1:
            self.current_index += 1
            self._render_step()

    def action_prev_step(self) -> None:
        if self.current_index > 0:
            self.current_index -= 1
            self._render_step()

    def action_back_to_menu(self) -> None:
        self.app.pop_screen()

    def action_quit_app(self) -> None:
        self.app.exit()


# ── App ───────────────────────────────────────────────────────────────────────

class LabWalkerApp(App):
    TITLE = "Offensive Tooling for Operators — Lab Walker"

    CSS = """
    /* ── Menu screen ─────────────────────────────────────────────────────── */

    ListView {
        border: none;
    }

    .day-item {
        background: $primary-darken-2;
        height: 2;
        padding: 0 1;
    }

    .day-label {
        text-style: bold;
        color: $text;
    }

    /* ── Walker screen ───────────────────────────────────────────────────── */

    #step-header {
        height: 2;
        background: $primary-darken-1;
        padding: 0 1;
    }

    #lab-title {
        width: 1fr;
        content-align: left middle;
        color: $text;
    }

    #step-counter {
        width: auto;
        content-align: right middle;
        color: $text-muted;
    }

    #command-panel {
        height: auto;
        min-height: 3;
        max-height: 10;
        background: $surface-darken-1;
        border: solid $primary;
        padding: 1 2;
        margin: 0 0 1 0;
    }

    #explanation-panel {
        height: auto;
        max-height: 10;
        background: $surface-darken-2;
        border: solid $secondary;
        padding: 1 2;
        margin: 0 0 1 0;
        color: $text-muted;
    }

    #output-panel {
        border: solid $accent;
        height: 1fr;
    }
    """

    def on_mount(self) -> None:
        try:
            groups = load_labs()
        except Exception as exc:
            self.exit(message=f"Failed to load labs from mkdocs.yml: {exc}")
            return
        if not groups:
            self.exit(message="No labs found in mkdocs.yml nav.")
            return
        self.push_screen(LabMenuScreen(groups))


def main() -> None:
    LabWalkerApp().run()


if __name__ == "__main__":
    main()
