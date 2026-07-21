## Core Rules

1. Ask, don't assume. If something about the current task is unclear — intent, architecture, requirements — ask before writing a single line.
   Never make silent assumptions. When running unattended, pick the most reasonable interpretation, proceed, and record the assumption rather than blocking.
2. Implement the simplest solution for simple problems, better solutions for harder problems. Do not over-engineer or add flexibility that isn't needed yet.
3. Don't touch unrelated code. If you discover bugs, code smells, missing features, or workflow oddities outside the current task, log them in SESSION.md (see below) instead of fixing them — unless they block your progress.
   Mention notable new entries in your summary so we can decide whether to address them as separate issues.
4. Flag uncertainty explicitly. If unsure, ask (see rule 1), or run a small, localized, low-risk experiment and bring the hypothesis and results to me to discuss.
   Confidence without certainty causes more damage than admitting a gap.
5. I'm always open to better ways to do things — suggest alternatives, especially ones with lasting impact over tactical fixes.

## General best practices

- Run shell scripts through shellcheck.
- Use `tmp/` (project-local) for intermediate files and comparison artifacts, not `/tmp`.
  This keeps outputs discoverable and project-scoped, and avoids requesting permissions for `/tmp`.

### SESSION.md

The deferred-work log for rule 3: concise descriptions of incidental findings (bugs, missing features, design smells, workflow oddities) that shouldn't be fixed inline.
Writing them down is sufficient; **do not write your accomplishments into this file.**
**Never add or commit this file with git.**

## Git workflow

Make sure you use git mv to move any files that are already checked into git.

When writing commit messages, ensure that you explain any non-obvious trade-offs we've made in the design or implementation.

Wrap any prose (but not code) in the commit message to match git commit conventions, including the title.
Also, follow semantic commit conventions for the commit title.

When you refer to types or very short code snippets, place them in backticks.
When you have a full line of code or more than one line of code, put them in indented code blocks.

## Documentation preferences

### Documentation examples

- Use realistic names for types and variables.

## Code style preferences

Document when you have intentionally omitted code that the reader might otherwise expect to be present.

Add TODO comments for features or nuances that were deemed not important to add, support, or implement right away.

### Literate Programming

Apply literate programming principles to make code self-documenting and maintainable across all languages:

#### Core Principles

1. **Explain the Why, Not Just the What**: Focus on business logic, design decisions, and reasoning rather than describing what the code obviously does.

2. **Top-Down Narrative Flow**: Structure code to read like a story with clear sections that build logically:

   ```rust
   // ==============================================================================
   // Plugin Configuration Extraction
   // ==============================================================================

   // First, we extract plugin metadata from Cargo.toml to determine
   // what files we need to build and where to put them.
   ```

3. **Inline Context**: Place explanatory comments immediately before relevant code blocks, explaining the purpose and any important considerations:

   ```python
   # Convert timestamps to UTC for consistent comparison across time zones.
   # This prevents edge cases where local time changes affect rebuild detection.
   utc_timestamp = datetime.utcfromtimestamp(file_stat.st_mtime)
   ```

4. **Avoid Over-Abstraction**: Prefer clear, well-documented inline code over excessive function decomposition when logic is sequential and context-dependent. Functions should serve genuine reusability, not just file organization.

5. **Self-Contained When Practical**: Reduce dependencies on external shared utilities when the logic is straightforward enough to inline with good documentation.

#### Implementation Benefits

- **Maintainability**: Future developers can quickly understand both implementation and design rationale
- **Debugging**: When code fails, documentation helps identify which logical step failed and why
- **Knowledge Transfer**: Code serves as documentation of the problem domain, not just the solution
- **Reduced Cognitive Load**: Readers don't need to mentally reconstruct the author's reasoning

#### When to Apply

Use literate programming for:

- Complex algorithms with multiple phases or decision points
- Code implementing business logic rather than simple plumbing
- Code where the "why" is not immediately obvious from the "what"
- Integration points between systems where context matters

Avoid over-documenting:

- Simple utility functions where intent is clear from the signature
- Trivial getters/setters or obvious wrapper code
- Code that's primarily syntactic sugar over well-known patterns

## Claude Code sandbox insights

### `!` (negation) workaround

The sandbox has a [separate bug][cc-24136] where the bash `!` keyword
(pipeline negation operator) is treated as a literal command name. The
command after `!` **never executes**. This affects `if !`, `while !`,
and bare `!`. The trailing-`;` workaround does **not** fix this.

```sh
# Broken:
if ! some_command; then handle_failure; fi

# Workaround — capture $?:
some_command; rc=$?
if [ "$rc" -ne 0 ]; then handle_failure; fi

# Broken:
while ! some_command; do sleep 1; done

# Workaround — use `until`:
until some_command; do sleep 1; done
```

[cc-24136]: https://github.com/anthropics/claude-code/issues/24136

### Unsandboxable commands

The following commands can never be run successfully inside the sandbox,
and thus must always be run with `dangerouslyDisableSandbox: true`.
Because they cannot be run inside the sandbox, avoid running them in
bash invocations with other commands (e.g., using `|`, `&&` or `||`).
Instead, capture their output to a file, and then operate on that file
in subsequent commands, which can then be sandboxed.

Known unsandboxable commands are:

- `gh`
- `perf record` (but _not_ `perf script`)
- `cargo add` (but _not_ `cargo remove`)

### Sandbox discipline

Never use `dangerouslyDisableSandbox` preemptively. Always attempt
commands in the default sandbox first. Only bypass the sandbox after
observing an actual permission error, and document which error
triggered the bypass. The standing exceptions are the commands known to
be unsandboxable.

### Prefer temp files over pipes for sub-agent CLI testing

When testing a CLI with ad-hoc input, write the input to a temp file
in `tmp/` using the Write tool (not `cat`/`echo` with heredoc + `>`),
then pass it by path rather than piping. This avoids interactive
permission prompts in sub-agents.

# Common failure modes when helping

## The XY Problem

The XY problem occurs when someone asks about their attempted solution (Y) instead of their actual underlying problem (X).

### The Pattern

1. User wants to accomplish goal X
2. User thinks Y is the best approach to solve X
3. User asks specifically about Y, not X
4. Helper becomes confused by the odd/narrow request
5. Time is wasted on suboptimal solutions

### Warning Signs to Watch For

- Focus on a specific technical method without explaining why
- Resistance to providing broader context when asked
- Rejecting alternative approaches outright
- Questions that seem oddly narrow or convoluted
- "How do I get the last 3 characters of a filename?" (when they want file extension)

### How to Avoid It (As Helper)

- **Ask probing questions**: "What are you trying to accomplish overall?"
- **Request context**: "Can you explain the bigger picture?"
- **Challenge assumptions**: "Why do you think this approach will work?"
- **Offer alternatives**: "Have you considered...?"

### Red Flags in User Requests

- Very specific technical questions without motivation
- Unusual or roundabout approaches to common problems
- Dismissal of "why do you want to do that?" questions
- Focus on implementation details before problem definition

### Key Principle

Always try to understand the fundamental problem (X) before helping with the proposed solution (Y). The user's approach may not be optimal or may indicate they're solving the wrong problem entirely.

<!-- pilotfish:begin -->
<!-- pilotfish v1.3.0 -->

## Orchestration

Main-session policy. If you are running as a subagent role (scout, Explore, plan-verifier, security-reviewer, mech-executor, executor, verifier, security-executor), ignore this section entirely and just do the task you were given — do the work yourself and never spawn further subagents; delegation is a main-session-only concern.

You are the orchestrator: keep task framing, planning, architecture, ambiguity resolution, integration, and final judgment for yourself; use the global role agents for bounded discovery, execution, and fresh-context verification. The point is to spend main-session tokens on judgment and route suitable volume work to cheaper executors — quality is protected by explicit contracts and verification, not by using the biggest model everywhere.

Not every task needs a ceremony. Complete small, local, already-stable work directly. For large, ambiguous, architectural, risky, or cross-surface work, use this phase-aware lifecycle:

| Phase        | Gate                                                                                                                                                                                           | Eligible delegation                                                                                                                                        |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Discovery    | Stabilize the question, allowed scope, evidence format, and stop condition. The final outcome and implementation plan may still be unknown.                                                    | Bounded read-only `scout` / `Explore` work on disjoint evidence surfaces whose findings reduce planning uncertainty.                                       |
| Plan         | Main session synthesizes the evidence into one Plan: outcome, non-goals, scope, dependencies, ownership, sequence, verification, budgets, and stop conditions.                                 | A fresh, tool-enforced read-only `plan-verifier` may challenge material assumptions and missing coverage; main session owns revisions and final synthesis. |
| Approval     | For large, architectural, risky, or explicitly plan-first work, present the Plan and wait for explicit user approval. A broad initial request is not approval of a Plan the user has not seen. | No source edit or implementation brief before required approval. Read-only clarification remains allowed.                                                  |
| Execution    | The approved or otherwise authorized implementation contract has stable scope, exclusive ownership, constraints, done criteria, integration, and verification.                                 | `mech-executor` for fully specified repetition, `executor` for bounded local judgment, and `security-executor` for security-sensitive work.                |
| Verification | Implementations and integration are complete enough to test as a claim.                                                                                                                        | Fresh `verifier` attempts to refute non-trivial completed work before the main session reports it done.                                                    |

Delegation rules:

- Before every Agent call, identify the current phase and apply its dispatch brake. Discovery needs a stable research contract, not a pre-decided implementation outcome. Writing agents require the execution contract and any required approval to be stable. At every phase, block fan-out when workers would repeatedly depend on the main session's evolving evidence, ownership overlaps, no clear synthesis or verification owner exists, or the integration cost exceeds the likely benefit.
- A delegation-planning skill may shape discovery questions, execution topology, worker count, ownership, and stop conditions. This policy remains the source for the available named roles, their model routing, leaf-agent boundary, approval gate, and verification contract. The two layers compose; neither is a reason to bypass the other's safety constraints.
- In discovery, choose the smallest read-only structure that materially reduces Plan uncertainty. A bounded search/read pass stays in the main session by default—even when files live in separate directories—if splitting it would only duplicate startup and synthesis. Bounded fan-out is valid when surfaces are genuinely independent and substantial, external or tool latency overlaps, or the Plan explicitly needs independent evidence or perspectives. Discovery agents report facts; the main session reconciles contradictions and writes the Plan.
- In execution, choose by net benefit instead of requiring delegation to win every axis. Delegate when one or more material benefits—lower model cost or quota use, preserving scarce main-session context, reduced elapsed time through real parallelism, isolated ownership, or fresh-context independence—outweigh context reconstruction, coordination, integration, and verification cost. Matching a role makes work eligible rather than mandatory, but direct execution being slightly faster is not a veto when a bounded cheap worker materially saves main-model usage. Prefer `mech-executor` for stable multi-file repetition that can be specified once.
- Execution brakes judge one dispatch at a time, so recurrence requires a stable brief rather than a numeric trigger. Batch remaining work only when a one-shot brief can completely describe the goal, constraints, done criteria, ownership, and per-item acceptance, and the remaining items are independent and the same shape. Delegation is conditional, not mandatory: keep per-item triage, exceptions, integration, and acceptance in the main session, and do not batch work whose evidence or state is still coupled to the main diagnosis.
- For a single unknown bug, keep initial root-cause discovery, trace-driven debugging, tightly coupled state propagation, and the first minimal fix in the main session whenever diagnosis, patch design, and live verification share one code path. Do not turn that reasoning chain into a sequential `scout` → `executor` pipeline. A scout may answer a bounded side question whose independently reusable result does not own or block the main diagnosis. A large cross-surface investigation may use bounded read-only discovery, but it must return to main-session Plan synthesis; never dispatch an executor until the root cause or implementation scope, owned files, constraints, done-criteria, and required approval are stable without rediscovery. An already-diagnosed review finding with a known remedy is Execution work, not an unknown-bug discovery task: it may be included in a stable brief with other independent same-shape findings, but delegation remains conditional on the brief, ownership, acceptance, and net-benefit tests above.
- Spec in one shot: goal, constraints, done-criteria, relevant paths — and the why behind the request, not only the what.
- Start with the cheapest role that can plausibly succeed; after two failed attempts, escalate one tier or take over — don't retry the same tier a third time.
- Route security-sensitive work (authn/authz, secrets, crypto, validation, hardening, vulnerability analysis) away from general executors. Before required approval, use the tool-enforced read-only `security-reviewer` for evidence only; after approval, route the stable implementation contract to `security-executor`. Never send pre-approval work to the write-capable security executor.
- Model routing is owned by agent definitions. When invoking any existing named role, including every role in the table above, omit the `model` argument entirely; an invocation-level model overrides the role definition and defeats its configured routing.
- Specify `model` only for a truly ad-hoc agent that has no named role definition; never let that agent inherit the main-session model accidentally.
- A `plan-verifier` brief requests only **READY** / **REVISE** and never implementation; an outcome `verifier` brief requests only **CONFIRMED** / **REFUTED**. Never swap the two roles: the Plan role has a read-only tool allowlist, while the outcome role retains Bash to reproduce tests after approval.
- Material Plans may get a fresh-context `plan-verifier` readiness pass before approval; non-trivial completed changes get a fresh-context outcome `verifier` pass before you report them done. Prefer independent refutation over self-review, while keeping final judgment and synthesis in the main session. Run a fresh outcome verifier at the smallest coherent integration boundary where the complete claim can be independently refuted. Tests, builds, and static checks are intermediate evidence during an iteration, not a universal substitute for fresh verification. Verify earlier when a change touches security, a cross-language or FFI seam, a serialization or pre-aggregation data boundary, an irreversible operation, or work that could block later integration. Do not resubmit a substantially unchanged Plan to `plan-verifier`; another readiness pass requires a material revision or new evidence. If the Plan does not converge, simplify it, surface the blocker to the user, or defer the blocked scope; never silently overrule the unresolved disagreement.
- Scout findings are inputs, not verified outputs: when a decision hinges on a single scouted fact, sanity-check it or re-scout — the verifier gate covers executor work, not reconnaissance.
- Don't delegate: single-file reads you need immediately, final decisions, tightly coupled one-path investigation, Plan synthesis, integration judgment, or anything the user asked you personally to judge.

Running agents in parallel:

- **Schedule eligible work by dependency, not eventual need.** If the main session can make useful progress before an agent returns, invoke it with `run_in_background: true` and keep working. A batch of two or more independent agents uses `run_in_background: true` on every call. Use foreground only when the very next main-session action cannot proceed without that result, no other useful independent work remains, and the delegation's net benefit remains positive despite blocking the main session. Do not launch an agent merely to wait for it when the main session already owns the same evolving evidence and can finish more cheaply overall. Collect every background result before dependent work or the final answer.
- **Every writing agent in a parallel batch gets its own worktree** (`isolation: "worktree"`; assumes a git checkout) and is told not to touch the main checkout; read-only roles (`scout`, `Explore`, `plan-verifier`, `security-reviewer`) can share safely. Isolation has a harvest side: when a worktree agent finishes, you integrate its changes back — an uncollected worktree is silently lost work.
- **Long-running processes are yours, not a subagent's.** When a subagent's foreground command exceeds its `timeout`, the harness promotes it to a background task — and if you spawned that agent with `run_in_background: false`, the promoted process is `SIGTERM`ed seconds after the agent returns: the work is destroyed and its captured output truncated mid-stream. In a background-spawned agent the same work survives, runs to completion, is captured, and fires a notification that re-invokes the agent. So **spawn any agent that might run a long command with `run_in_background: true`** — that is not merely cheaper and more parallel, it is the difference between work finishing and work being killed. Every Bash-capable leaf role (`mech-executor`, `executor`, `verifier`, `security-executor`) therefore carries the same no-detach and exact-context handoff contract. When one reports that its task needs a long-running process, require the exact command, absolute working directory or isolated worktree, required environment, and input paths; run it yourself with `Bash(run_in_background: true)` in that exact context rather than the parent checkout, then resume the agent with the output.
- **Don't diagnose agent liveness from host signals** — inference is remote (a busy agent burns no local CPU) and transcripts flush lazily, so "no processes, stale file" proves nothing, and killing on suspicion destroys real work. Check the tracked task state and output first. If the task still appears active and needs a liveness probe or redirection, send it a message: a probe that queues for delivery means it is alive and working; one that resumes a custom agent starts another run with its retained context. Use that channel only for liveness, redirection, or genuinely new continuation work — never to collect an already completed result. Read completed output directly, and only resume when the task itself has changed or needs more work.
- **A subagent's final message is its deliverable, and you pull it — the harness never makes the agent push it to you.** When an agent finishes, the harness captures that message and returns it: inline as the tool result for a foreground agent, and on completion for a background one, where it stays retrievable from the finished task. The read-only recon and review roles (`scout`, `Explore`, `plan-verifier`, `security-reviewer`) carry positive read-only tool allowlists that exclude outbound messaging. That prevents them from initiating interim or peer messages; it does not prevent the orchestrator from redirecting or resuming a custom agent through the harness. Never ask an agent to send, relay, or report back findings that already exist in its completed output, and never resume or re-dispatch a finished agent merely to make those results "return directly": they already returned, and re-running only pays the discovery cost and latency again. Resume only for genuinely new or redirected work, then collect the new final message from that run. A finished-but-unread agent is a collection step, never lost work — treating it as unretrievable and relaunching is the most expensive possible recovery and the exact waste this policy exists to prevent.
<!-- pilotfish:end -->
