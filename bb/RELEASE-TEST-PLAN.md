# bb CLI v1.0.0 - Pre-Publish Test Plan

This document outlines the comprehensive testing checklist required before officially publishing the `bb` CLI tool. Ensure all items pass in both **Windows PowerShell 5.1** and **PowerShell 7+**.

## Phase 1: Installation & Setup
- [ ] **Clean Build:** Run `bb/scripts/build.ps1` in a fresh environment. Verify `Bb.Core.dll` and `netstandard.dll` (if PS 5.1) are generated in `bb/bin/`.
- [ ] **Module Import:** Run `Import-Module ./bb/bb.psd1 -Force`. Verify no red text or syntax errors appear.
- [ ] **Command Discovery:** Run `Get-Command -Module bb`. Verify `bb`, `bb-config`, `bb-use`, and `Invoke-BbAiQuery` are present.

## Phase 2: Configuration & Auth (DPAPI)
- [ ] **First-Time Config:** Run `bb-config -Provider openai -ApiKey "fake-key"`. Verify `.bb-config.json` is created in `$HOME`.
- [ ] **DPAPI Encryption:** Check `$env:APPDATA\bb\openai.secret`. Verify the file exists and is encrypted (binary, not plain text).
- [ ] **Switch Providers:** Run `bb-use anthropic`. Verify the default provider updates in `.bb-config.json`.

## Phase 3: Core AI & Context Gathering
- [ ] **Basic Query:** Run `bb "list items in this folder"`. Verify it returns a valid PowerShell command (e.g., `Get-ChildItem`).
- [ ] **Context - CWD:** Navigate to a deeply nested folder and ask `bb "what folder am I in?"`. Verify the AI knows the path.
- [ ] **Context - Last Error:** Purposely run a failing command (e.g., `dir nonexistent_folder`), then immediately run `bb "fix that"`. Verify the AI reads the `LastError` and provides a relevant solution.

## Phase 4: Execution & State Mutation (Dot-Sourcing)
- [ ] **Directory Navigation:** Ask `bb "go up one directory"`. Press `[E]` to execute. Verify your actual PowerShell prompt changes directories.
- [ ] **Variable Persistence:** Ask `bb "set a variable named testvar to 'hello'"`. Press `[E]`. Then manually type `$testvar`. Verify it outputs `hello`.
- [ ] **Environment Variables:** Ask `bb "set an environment variable TEST_ENV to 1"`. Press `[E]`. Manually type `$env:TEST_ENV`. Verify it outputs `1`.

## Phase 5: Safety & Security Heuristics
- [ ] **Regex Blacklist (Remove):** Ask `bb "delete all txt files"`. Verify the Action Bar flags the risk as **Red/High**.
- [ ] **Regex Blacklist (Stop):** Ask `bb "kill the explorer process"`. Verify the Action Bar flags the risk as **Red/High**.
- [ ] **Admin Requirement:** Ask `bb "restart the windows update service"`. Verify the TUI displays `[Requires Admin]` in Red.

## Phase 6: Error Handling & Resilience
- [ ] **Authentication Failure:** Use an invalid API key. Run a query. Verify `Show-BbError` displays a yellow/gray user-friendly message about "Authentication failed" instead of a raw C# stack trace.
- [ ] **Timeout (10s):** Simulate a slow network or use a dummy endpoint. Verify the C# `HttpClient` times out after 10 seconds and displays a graceful "Request timed out" message.
- [ ] **Offline Mode:** Disconnect from Wi-Fi. Run a query. Verify the tool catches the DNS/network error gracefully.

## Phase 7: TUI (Action Bar) Responsiveness
- [ ] **Execute [E]:** Verifies the command runs and the TUI exits cleanly.
- [ ] **Copy [C]:** Press `C`. Paste into notepad. Verify the exact command was copied to the clipboard.
- [ ] **Regenerate [R]:** Press `R`. Verify the tool re-queries the AI and provides a *different* or updated suggestion.
- [ ] **Quit [Q] / Escape:** Press `Q` or `Esc`. Verify the prompt returns to the user without executing anything.

## Phase 8: Environment Compatibility
- [ ] **PowerShell 5.1:** Open `powershell.exe`. Run the module. Verify `Add-Type` loads the C# core successfully without type collision errors.
- [ ] **PowerShell 7.x:** Open `pwsh.exe`. Run the module. Verify `AssemblyLoadContext` loads the core without locking the DLL indefinitely.
