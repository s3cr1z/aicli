# GEMINI.md - bb CLI Project Context

This file provides instructional context for AI agents working on the `bb` (Big Brother) CLI project.

## Project Overview

`bb` is a state-preserving, context-aware AI assistant integrated directly into PowerShell. It enables users to perform complex tasks using natural language while maintaining the integrity and state of their current PowerShell session.

### Core Technologies
- **PowerShell (5.1 & 7.x):** User-facing scripts, session integration, and TUI.
- **C# (.NET Standard 2.0):** Binary core for API communication, security, and safety.
- **OpenAI API (Compatible):** Intelligence layer for command generation.
- **DPAPI:** Secure storage of API credentials on Windows.

### Architecture
- **`bb/bb.psd1`:** Hybrid module manifest.
- **`bb/bb.psm1`:** Script module containing the TUI, context gathering, and execution logic.
- **`bb/src/Bb.Core/`:** C# source code for cmdlets and services.
- **`bb/bin/`:** Compiled binaries and dependencies.

## Building and Running

### Build
To compile the C# core and prepare the module:
```powershell
powershell.exe -NoProfile -File bb/scripts/build.ps1
```

### Usage
1. **Import the module:**
   ```powershell
   Import-Module ./bb/bb.psd1
   ```
2. **Configure (First time):**
   ```powershell
   bb-config -Provider openai -ApiKey "your_key_here"
   ```
3. **Execute:**
   ```powershell
   bb "list all files modified in the last 24 hours"
   ```

### Testing
Run the Pester contract tests to verify session mutation and core logic:
```powershell
Invoke-Pester -Path bb/tests/Contract.Tests.ps1
```

## Development Conventions

### Session Mutation
All generated commands intended to change the session state (e.g., `cd`, variable assignment) **must** be executed via the `Execute-BbCommand` function in `bb.psm1`, which uses dot-sourcing:
```powershell
# In bb.psm1
function Execute-BbCommand {
    param($Command)
    $sb = [scriptblock]::Create($Command)
    . $sb
}
```

### Safety & Security
- **Safety Heuristics:** Every command must be checked against `Bb.Core.Services.SafetyHeuristics`. Destructive verbs (`Remove-*`, `Stop-*`, etc.) should be flagged as `high` risk.
- **Credential Storage:** Never store API keys in plain text. Use `Bb.Core.Services.CredentialStore`, which leverages Windows DPAPI.
- **Context Awareness:** The `bb` function gathers `CWD`, `OS`, `PSVersion`, and `LastError` to provide the AI with necessary environmental context.

### Compatibility
- Ensure the module remains compatible with **Windows PowerShell 5.1**.
- For PowerShell 7+, use `AssemblyLoadContext` to load `Bb.Core.dll` and avoid dependency collisions.
- The build script manually includes `netstandard.dll` to bridge the gap for PS 5.1.

## Key Files
- `bb/bb.psm1`: Primary logic for TUI and session integration.
- `bb/src/Bb.Core/Commands/InvokeBbAiQuery.cs`: Core cmdlet for AI interaction and prompt management.
- `bb/src/Bb.Core/Services/SafetyHeuristics.cs`: Regex-based destructive command detection.
- `bb/src/Bb.Core/Services/CredentialStore.cs`: DPAPI implementation for secrets.
- `bb/tests/Contract.Tests.ps1`: Pester tests for session state persistence.
