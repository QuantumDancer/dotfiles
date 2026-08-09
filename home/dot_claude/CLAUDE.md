## Core Rules

1. Ask, don't assume. If intent, architecture, or requirements are unclear, ask before writing a line.
   Running unattended: pick the most reasonable reading, proceed, and record the assumption rather than blocking.
2. Implement the simplest solution that fits the problem's difficulty. No flexibility that isn't needed yet.
3. Don't touch unrelated code. Log incidental findings — bugs, smells, missing features, workflow oddities — in
   SESSION.md instead of fixing them, unless they block progress. Mention notable new entries in your summary.
4. Flag uncertainty explicitly. Ask, or run a small localized low-risk experiment and bring me the hypothesis
   and the result. Confidence without certainty does more damage than admitting a gap.
5. Suggest better approaches, especially lasting ones over tactical fixes.

SESSION.md is that deferred-work log and nothing else — never your accomplishments, never `git add`ed or committed.

## Working preferences

- Project-local `tmp/` for intermediate and comparison artifacts, not `/tmp` — discoverable, project-scoped, no permission prompts.
- Run shell scripts through shellcheck.
- `git mv` for files already tracked.
- Commit messages: semantic title, prose wrapped (title included), non-obvious design or implementation trade-offs explained.
  Backticks for types and short snippets; indented code blocks for a full line or more.
- Documentation examples use realistic type and variable names.
- Document code intentionally omitted that a reader would expect; TODO-comment nuances deliberately deferred.
- Literate style: comments explain the why — business logic, design decisions, trade-offs — placed immediately before
  the code they justify, with section headers for multi-phase algorithms. Prefer well-documented sequential inline code
  over decomposition that only organizes the file. Skip it for obvious wrappers and simple utilities.

## Claude Code sandbox

- Bash `!` negation is broken ([cc-24136]) — the command after `!` never runs, and a trailing `;` does not help.
  Use `cmd; rc=$?` instead of `if !`, and `until` instead of `while !`.
- Never sandboxable, so always `dangerouslyDisableSandbox: true` and never chained with `|`/`&&`/`||`
  (redirect output to a file, then process that file sandboxed): `git commit`, `gh`.
- Never bypass the sandbox preemptively — attempt sandboxed first, bypass only after an actual permission error,
  and name the error that triggered it. The commands above are the standing exceptions.
- Sub-agent CLI testing: Write the input to a file in `tmp/` with the Write tool and pass it by path;
  heredoc-and-pipe triggers interactive permission prompts.

[cc-24136]: https://github.com/anthropics/claude-code/issues/24136
