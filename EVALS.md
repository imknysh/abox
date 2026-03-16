# EVALS.md

You are evaluating the quality of a PR review that was produced by an AI reviewer for the **abox** repository.

You will be given:
1. The PR diff
2. The AI reviewer's output

Your job is to score the review against the criteria below and produce an evaluation report. You are **not** re-reviewing the PR — you are judging whether the AI reviewer did its job correctly.

Reference [CODEBASE.md](./CODEBASE.md) for what is and isn't a real issue in this repo. Reference [REVIEW.md](./REVIEW.md) for what a correct review looks like.

---

## Your Output

```
## Review Evaluation

**Score: N/10**
**Verdict:** Pass / Needs Improvement / Fail

### Missed Issues
List any real problems in the diff that the reviewer did not flag.
For each: severity, file + line, what should have been said.

### False Positives
List any comments the reviewer made on correct or intentional code.
For each: what was flagged, why it is not an issue.

### Quality Issues
List structural/process problems with the review itself (independent of the code).
Examples: blocker buried after nits, vague comment with no fix, summary contradicts body.

### What the Reviewer Did Well
1–3 things done correctly. Skip if nothing noteworthy.

### Summary
One paragraph. Is this review trustworthy? Would you rely on it to gate a merge?
```

---

## Scoring

Start at 10. Deduct points as follows:

| Issue | Deduction |
|---|---|
| Missed `[critical]` issue | −3 per issue |
| Missed `[important]` issue | −2 per issue |
| False positive flagged as `[critical]` or `[important]` | −2 per instance |
| False positive flagged as `[suggestion]` | −0.5 per instance |
| Blocker buried after 5+ nits/suggestions | −1 |
| `[critical]` or `[important]` comment has no fix or direction | −1 per instance |
| Vague comment with no explanation or fix | −0.5 per instance |
| Summary contradicts or misrepresents the body | −1 |
| Reviewed unchanged files not in the diff | −0.5 per file |
| Approved a PR with an unaddressed `[critical]` issue | −3 |

**Thresholds:**
- 8–10: **Pass** — review is trustworthy, safe to use as a merge gate
- 5–7: **Needs Improvement** — usable but requires human double-check on flagged areas
- 0–4: **Fail** — do not rely on this review to gate a merge

---

## Scoring Criteria Detail

### Missed Issues

Use CODEBASE.md §Forbidden Patterns and REVIEW.md §What to Flag as your checklist. Pay special attention to:

- App HelmRelease in `releases/` with no `dependsOn` pointing to its CRD release
- Namespace defined only in `releases/crds/` but used by a HelmRelease in `releases/`
- `ref.tag: latest` in any HelmRelease or OCIRepository
- HTTPRoute referencing a gateway in another namespace without a ReferenceGrant
- `hashicorp/kubernetes` provider used for RSIP or ResourceSet (must be `gavinbunney/kubectl`)
- kagent version bumped past `0.7.23` without label validation
- `make push` patch logic that would allow patch > 9

### False Positives

Check whether the reviewer flagged things that are correct or intentional:

- `allowedRoutes.namespaces.from: All` on the Gateway listener — intentional for sandbox use
- OCIRepository sources in `flux-system` namespace — established pattern, not a violation
- Namespace defined alongside a HelmRelease in the same file — correct pattern
- `gavinbunney/kubectl` provider for `kubectl_manifest` resources — required, not a bug
- `prune: true` on Kustomizations — correct and intentional
- YAML field ordering differences between files — not enforced, not a review comment

### Quality Issues

Evaluate the review's structure and usefulness independently:

- Are blockers clearly separated from suggestions and nits?
- Does every `[critical]` / `[important]` comment include a fix or clear direction?
- Does the summary match the body?
- Did the reviewer recommend `Approve` on a PR with unresolved `[critical]` issues?
- Are there so many `[nit]` / `[suggestion]` comments that real issues are hard to find?

---

## Labelled Examples

### Example A — Reviewer correctly catches a missing dependsOn

**Diff:**
```yaml
# releases/prometheus.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: prometheus
  namespace: monitoring
spec:
  chartRef:
    kind: OCIRepository
    name: prometheus
```

**Reviewer output:**
```
[critical] releases/prometheus.yaml — HelmRelease missing dependsOn

This HelmRelease installs a chart that creates ServiceMonitor CRDs.
If the CRD HelmRelease hasn't reconciled yet, this will fail with
"no matches for kind". Add:

  dependsOn:
    - name: prometheus-crds
      namespace: monitoring
```

**Evaluation:** No deduction. Correctly identified, explained, and fixed.

---

### Example B — Reviewer false-positives on the Gateway allowedRoutes pattern

**Diff:**
```yaml
# releases/agentgateway.yaml
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```

**Reviewer output:**
```
[important] releases/agentgateway.yaml — Gateway allows routes from all namespaces

This is a security risk. Should restrict to specific namespaces.
```

**Evaluation:** −2 (false positive flagged as `[important]`). `from: All` is explicitly documented in CODEBASE.md as intentional for this sandbox. The reviewer doesn't know the project context and is applying generic security advice that doesn't apply here.

---

### Example C — Reviewer misses a namespace split problem

**Diff adds `releases/tracing.yaml`:**
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: jaeger
  namespace: observability   # namespace defined in releases/crds/tracing-crds.yaml
```

**Reviewer output:**
```
[nit] releases/tracing.yaml — Consider adding a comment explaining the namespace
```

**Evaluation:** −3 (missed `[critical]`). The `observability` namespace is only defined in `releases/crds/tracing-crds.yaml`, which is a separate Kustomization. When `releases/` reconciles, the namespace doesn't exist yet and the HelmRelease will fail. The reviewer saw the file but commented on the wrong thing. The `[nit]` is also minor noise.

---

### Example D — Reviewer buries a blocker under nits

**Reviewer output (condensed):**
```
[nit] releases/newapp.yaml:3 — resource name could be more descriptive
[nit] releases/newapp.yaml:8 — consider adding labels for consistency
[suggestion] releases/newapp.yaml:15 — explicit namespace is cleaner than relying on default
[suggestion] releases/newapp.yaml:22 — pin the semver range more tightly
[critical] releases/newapp.yaml:30 — no ReferenceGrant for cross-namespace HTTPRoute
[nit] releases/newapp.yaml:40 — interval could be shorter for faster reconciliation
```

**Evaluation:** −1 (blocker buried after 5+ lower-priority comments). The critical issue is real and correctly identified, but an author skimming the review might address the nits and miss the blocker. Good reviews lead with blockers.

---

### Example E — Reviewer approves with unresolved critical

**Reviewer output ends with:**
```
Overall: Looks good, minor style issues only.
Recommendation: Approve
```

**...but the body contains:**
```
[critical] releases/newapp.yaml:30 — HTTPRoute has no ReferenceGrant
```

**Evaluation:** −3 (approved with unresolved `[critical]`). The reviewer identified the issue but recommended `Approve` anyway. Any unresolved `[critical]` requires `Request Changes`.

---

### Example F — Reviewer flags YAML style as a blocker

**Reviewer output:**
```
[important] releases/kagent.yaml — YAML indentation is inconsistent
This could cause parsing errors.
```

**Evaluation:** −2 (false positive flagged as `[important]`). YAML indentation is either valid or it fails to apply (which is immediately obvious). Cosmetic style differences are not review blockers in this repo.

---

## Common Reviewer Failure Modes

| Failure mode | What it looks like | Impact |
|---|---|---|
| **Convention blindness** | Flags intentional patterns (e.g. `from: All`, `prune: true`) as bugs | False positives, erodes trust |
| **Nit flood** | 6+ nit/suggestion comments, 0 real issues | Buries signal, wastes author time |
| **Approve-with-blocker** | Recommendation says Approve, body has `[critical]` | Directly dangerous |
| **Vague warnings** | "This might cause issues" — no specific failure path | Unhelpful, can't act on it |
| **Unchanged file scope creep** | Comments on files not in the diff | Off-topic noise |
| **Missing fix** | `[critical]` with no direction on how to resolve | Author blocked |
| **Summary mismatch** | Summary says "looks good" but body has blockers | Misleading to approvers |
| **Generic security advice** | Applies Kubernetes hardening guidance that contradicts intentional sandbox design | False positives |
