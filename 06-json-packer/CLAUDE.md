# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
zig build              # build the project
zig build run          # build and run
zig build test         # run all tests
zig build test -- --test-filter "name"  # run a single test by name
```

## Working Rules

### Before coding
1. **Always start in plan mode** — read, analyse, ask questions, DO NOT write code use skill /grill-me
2. **Ask clarifying questions** until 95% sure of what is expected
3. **Break down the task** into atomic steps and list them before executing propose to run skill /to-prd or /to-issue depending on the task

### During development
4. **Small, verifiable tasks** — never code more than one feature at a time use skill /tdd to write code
5. **Build checks into every task** — after each step: test, verify for errors
6. **Do not move to the next step** without being 95% confident the previous step is correct
7. **TDD mandatory** — see dedicated section below

### Quality
8. **Treat the user as the lead dev** — explain choices, ask for validation before structural decisions
9. **Never invent APIs or functions** — check the docs
10. **Update CLAUDE.md** after every important decision (architecture, chosen library, convention)

### After coding
11. **log** - Log every new information in `docs/adr/` or `docs/prd` like : A new major dependency is added ; An architecture choice is made ; An important bug is fixed (note the cause) ; A new key folder/file is created ; The project status changes ; A test convention is established or modified
12. **commit** - commit to git current work with skill /git-commit
