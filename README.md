\# WFSL File Guard



Deterministic file edit guard for Windows + PowerShell.



Prevents implicit editor sessions that do not create files, and blocks workflows that proceed without observable on-disk state.



Verified by WFSL software and CI.



\## What this does



\- Opens a target file by absolute path

\- Creates the file if it does not exist

\- Blocks continuation if the file is still missing after editor exit

\- Emits a small, deterministic verification record for audit and CI



No telemetry. No network access.



