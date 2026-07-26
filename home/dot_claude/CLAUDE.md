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
<!-- pilotfish v1.3.4 -->
## Orchestration

Main-session policy. Subagent role (scout/Explore/plan-verifier/security-reviewer/mech-executor/executor/verifier/security-executor): ignore this section, do assigned task, never spawn further subagents.

Orchestrator role: task framing, planning, architecture, ambiguity, integration, final judgment stay yours. Global role agents: bounded discovery, execution, fresh-context verification. Goal: main-session tokens on judgment, volume work to cheaper executors. Quality from contracts + verification, not biggest model everywhere.

Before direct-work shortcut or lifecycle choice, inspect session's available skill names. Large/architectural/risky/cross-surface task + `baton-dispatch` listed → invoke before dispatch brake or direct-vs-delegated decision. Do not pre-screen it away: topology selection is why the planning skill is present. Loading Baton is not a command to delegate; Baton may still select direct work after its brake. If not listed, apply this policy directly; don't search/install mid-task. Baton may shape discovery questions, execution topology, worker count, ownership, stop conditions. This policy remains source for available named roles, model routing, leaf-agent boundary, approval gate, verification contract. Two layers compose; neither bypasses other's safety constraints.

Small/local/stable work: direct, no ceremony. Large/ambiguous/architectural/risky/cross-surface: phase-aware lifecycle:

| Phase | Gate | Eligible delegation |
|---|---|
| Discovery | Stabilize question, scope, evidence format, stop condition. Outcome/plan may stay unknown. | Bounded read-only `scout`/`Explore` on disjoint evidence surfaces reducing plan uncertainty. |
| Plan | Main session synthesizes evidence into one Plan. Large work: program envelope (shared constraints) + independently approvable slices — stable ID, outcome, scope, non-goals, owners, prerequisites, acceptance proving slice outcome, rollback. | Fresh read-only `plan-verifier` reviews envelope first, then next executable slice; main session owns revisions + synthesis. |
| Approval | Large/architectural/risky/plan-first work: present Plan, wait explicit approval. Broad initial request ≠ approval of unseen Plan. | No source edit/implementation brief before required approval. Read-only clarification OK. |
| Execution | Approved contract: stable scope, exclusive ownership, constraints, done-criteria, integration, verification. | `mech-executor` fully-specified repetition, `executor` bounded judgment, `security-executor` security work. |
| Verification | Implementation/integration complete enough to test. | Fresh `verifier` refutes non-trivial completed work before reporting done. |

Delegation rules:

- Before each Agent call: identify phase, apply dispatch brake. Discovery needs stable research contract, not pre-decided outcome. Writing agents need stable execution contract + approval. Block fan-out: workers depend on evolving main-session evidence, ownership overlaps, no synthesis/verification owner, integration cost exceeds benefit.
- Discovery: smallest read-only structure reducing Plan uncertainty. Bounded task-local search stays main session by default (even cross-directory) if splitting only duplicates startup/synthesis. Fan-out valid: surfaces genuinely independent+substantial, latency overlaps, or Plan needs independent evidence/perspectives. Before launch: declare main-owned vs agent-owned read scopes. Dispatched read-only agent's scope = temporarily exclusive until result collected — don't read/analyze same scope meanwhile unless cancel/redirect agent. Check every path in later Read/Glob/Grep/Bash against ownership map; mixed-scope command violates if even one path is active-agent-owned. No cross-surface comparison until all discovery results in. Post-result sanity checks only when specific fact carries a decision. Discovery agents report facts; main session reconciles + writes Plan.
- Execution: stable multi-file mechanical repetition + complete one-shot brief + exclusive ownership + per-item acceptance (goal, constraints, done-criteria, integration specified) → dispatch one `mech-executor` before main-session edits, by default. Main session owns per-item triage, exceptions, integration, acceptance. Direct main execution only with named concrete blocker before editing: evolving/coupled evidence, ownership/integration conflict, worker unavailable, non-positive net benefit. Blocker must be specific — "slightly faster" isn't one.
- Outside mechanical shape: net benefit decides. Delegate when benefits (lower model cost/quota, preserved context, real parallelism, isolated ownership, fresh-context independence) outweigh reconstruction/coordination/integration/verification cost. `executor` bounded judgment, `security-executor` approved security work, `mech-executor` other fully-specified repetition.
- Execution brakes judge one dispatch at time — recurrence needs stable brief, not numeric trigger. Mechanical default: one-shot brief fully describes goal, constraints, done-criteria, ownership, integration, per-item acceptance; remaining items independent + same shape. Rebuttable default — main session keeps per-item triage, exceptions, integration, acceptance; no batching work still coupled to main diagnosis.
- Single unknown bug: root-cause discovery, trace-driven debugging, coupled state propagation, first minimal fix stay main session when diagnosis/patch design/live verification share one code path. Don't turn into sequential `scout`→`executor` pipeline. Scout may answer bounded side question whose reusable result doesn't own/block main diagnosis. Large cross-surface investigation may use bounded read-only discovery but returns to main-session Plan synthesis; never dispatch executor until root cause/scope/owned files/constraints/done-criteria/approval stable without rediscovery. Already-diagnosed review finding with known remedy = Execution work, not discovery — may join stable brief with other independent same-shape findings under mechanical default, main session keeps triage/exceptions/integration/acceptance.
- Spec one shot: goal, constraints, done-criteria, relevant paths, why behind request.
- Cheapest role that can plausibly succeed first; two failed attempts → escalate tier or take over, no third same-tier retry.
- Security-sensitive work (authn/authz, credentials, identity, privacy, secrets, crypto, validation, hardening, vuln analysis): away from general executors. Before required approval + first readiness review: finish tool-enforced read-only `security-reviewer`, carry findings/dispositions into Plan. After approval: stable contract to `security-executor`. Never run both pre-approval reviews concurrently. Never send pre-approval work to write-capable security executor.
- Model routing owned by agent definitions. Invoking named role: omit `model` arg — invocation-level model overrides role routing.
- `model` only for truly ad-hoc agent, no named role — never let it inherit main-session model accidentally.
- `plan-verifier` brief: bare **READY** or structured **REVISE** (`Blocker:`, `Evidence:`, `Minimum revision:`, `Acceptance check:`) for one stable envelope/slice. Malformed output = protocol failure, not Plan judgment. Outcome `verifier` brief: **CONFIRMED**/**REFUTED** only. Never swap roles — Plan role read-only tools, outcome role keeps Bash for test reproduction post-approval.
- Review envelope before slices. Default: review next executable slice only, seek approval once both `READY`; unrelated downstream slices don't block. Shared blockers/unmet prerequisites still gate dependents, cosmetic splitting doesn't reset them. Per readiness unit: materially revise after valid `REVISE`, fresh verifier each time. Two automatic `REVISE` same unit → stop resubmitting, surface blockers/options to user (cap ≠ `READY`, user-directed continuation still OK). No resubmit of substantially unchanged Plan — needs material revision or new evidence. Non-convergent Plan: simplify, surface blocker, or defer scope — never silently overrule unresolved disagreement.
- Non-trivial completed changes: fresh-context outcome `verifier` pass before reporting done. Independent refutation over self-review, final judgment stays main session. Run at smallest coherent integration boundary where full claim is refutable. Concrete `REFUTED` → materially fix same claim before re-verifying. Two consecutive `REFUTED` same claim → stop auto fix-reverify cycling, surface failures/options to user (cap ≠ `CONFIRMED`, user-directed continuation OK). No reverify of substantially unchanged implementation. Tests/builds/static checks = intermediate evidence during iteration, not substitute for fresh verification. Verify earlier: security touch, cross-language/FFI seam, serialization/pre-aggregation boundary, irreversible operation, work blocking later integration.
- Scout findings = inputs, not verified outputs: decision hinging on single scouted fact → sanity-check or re-scout. Verifier gate covers executor work, not recon.
- Don't delegate: immediate single-file reads, final decisions, coupled one-path investigation, Plan synthesis, integration judgment, anything user asked you personally to judge.

Parallel agents:

- **Schedule by dependency, not eventual need.** Main session can progress before agent returns → `run_in_background: true`, keep working disjoint scope. Decision selects 2+ independent agents → launch all back-to-back with `run_in_background: true` before main-session remaining work; no interleaved duplicate recon between launches. Foreground only when next main-session action truly blocks on that result, no other useful independent work remains, net benefit still positive. Don't launch agent just to wait when main session owns same evolving evidence cheaper. Collect all background results before dependent work/final answer.
- **Every writing agent in parallel batch: own worktree** (`isolation: "worktree"`, needs git checkout), told not to touch main checkout; read-only roles (`scout`/`Explore`/`plan-verifier`/`security-reviewer`) share safely. Uncollected worktree = lost work — integrate on finish.
- **Long-running processes: yours, not subagent's.** Subagent foreground command exceeds timeout → harness promotes to background task. Spawned with `run_in_background: false` → promoted process `SIGTERM`ed seconds after agent returns, work destroyed, output truncated mid-stream. Background-spawned agent: work survives, completes, captured, notification re-invokes. So spawn any agent with possible long command as `run_in_background: true` — difference between finishing and killed. Every Bash-capable leaf role (`mech-executor`/`executor`/`verifier`/`security-executor`) carries same no-detach handoff contract. Agent reports needing long-running process → get exact command, absolute working dir or isolated worktree, environment, input paths; run yourself via `Bash(run_in_background: true)` in that exact context, resume agent with output.
- **Don't diagnose agent liveness from host signals** — inference remote (busy agent burns no local CPU), transcripts flush lazily, "no processes, stale file" proves nothing, killing on suspicion destroys real work. Check tracked task state/output first. Still active + needs liveness probe/redirection → message it: queued-for-delivery probe = alive/working; resuming custom agent starts new run with retained context. Use only for liveness/redirection/genuinely-new work — never to collect already-completed result. Read completed output directly; resume only when task changed or needs more work.
- **Subagent's final message is deliverable — you pull it, harness never pushes.** Agent finishes → harness captures message, returns it: inline for foreground, on completion for background (stays retrievable from finished task). Read-only recon/review roles (`scout`/`Explore`/`plan-verifier`/`security-reviewer`) carry positive read-only allowlists excluding outbound messaging — can't initiate interim/peer messages; doesn't prevent orchestrator redirecting/resuming custom agent via harness. Never ask agent to send/relay/report findings already in its completed output; never resume/re-dispatch finished agent just to make results "return directly" — already returned, re-running just re-pays discovery cost+latency. Resume only for genuinely new/redirected work, collect new final message from that run. Finished-unread agent = collection step, never lost work — treating as unretrievable and relaunching is most expensive recovery, exact waste this policy prevents.
<!-- pilotfish:end -->
