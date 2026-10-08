# bonYe! shared customer app

The user requires every feature change to apply to both Android and the web companion in hpeikanian/bonye-webapp. This repository is the canonical Flutter source for both. Preserve the separate companion repository and folder. After feature edits, run analysis and tests here, synchronize the companion using its tool/sync_source.py, and compile both Android and web. Explicitly document platform limitations and unverified live behavior. Do not independently diverge web screens or translations. Use existing checkouts; no worktrees unless the user requests them.
