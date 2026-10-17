---
id: tic-bijy
status: closed
deps: []
links: []
created: 2026-10-17T22:20:03Z
type: bug
priority: 1
assignee: Chris Vaillancourt
tags: [cli, links]
---
# Show exactly which pairs tk link creates

tk link with three or more IDs links every pair (a clique). The output only reports a directed-edge count ("Added 6 link(s) between 3 tickets"), so an unintended pair goes unnoticed. Seen in practice when linking one ticket to two others that were already parent and child.

## Design

Keep clique semantics for upstream compatibility. Report each newly added undirected pair as 'Added link: A <-> B' (mirroring unlink output) and say in help that every listed pair is linked.

## Acceptance Criteria

Two-ID and three-ID links print one line per new pair in argument order. Re-linking existing pairs prints 'All links already exist'. A partially existing set prints only the new pairs. Help and README describe pairwise semantics.

## Notes

**2026-10-17T22:27:51Z**

Implemented in 186bef8 (per-pair report, pairwise semantics in help and README); duplicate IDs rejected in 88c69a3. Clique semantics kept for upstream compatibility; a star mode was not added. Verification: make test 206 scenarios pass; bash 3.2 smoke test; review findings fixed in 88c69a3.
