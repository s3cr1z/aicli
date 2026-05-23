# bb - The AI-Powered PowerShell CLI

`bb` (Big Brother) is a context-aware, state-preserving AI CLI for PowerShell. It stops you from context-switching between your terminal and a browser by bringing AI intelligence directly into your session.

## Key Features

- **Context-Aware:** Sends your current working directory, OS details, and last error to the AI for smarter command generation.
- **State-Preserving:** Executes commands directly in your parent PowerShell session. `cd` actually changes your directory; `$var = 1` actually persists.
- **Secure:** Stores API keys safely using Windows DPAPI (ProtectedData).
- **Safe:** Features a built-in regex-based safety backstop to flag destructive commands before execution.
- **TUI Action Bar:** Review, copy, or execute commands with single keystrokes.
- **Hybrid Core:** Combines the speed of C# with the flexibility of PowerShell.

## Installation

1. Clone the repository.
2. Run the build script:
   ```powershell
   ./bb/scripts/build.ps1
   ```
3. Import the module:
   ```powershell
   Import-Module ./bb/bb.psd1
   ```

## Configuration

Set up your AI provider (OpenAI compatible):
```powershell
bb-config -Provider openai -ApiKey "your-key"
```

Switch providers:
```powershell
bb-use anthropic
```

## Usage

Just type `bb` followed by your request in natural language:

```powershell
bb "find all log files larger than 10MB and zip them"
```

The action bar will appear:
- **[E]xecute:** Runs the command in your current session.
- **[C]opy:** Copies the command to your clipboard.
- **[R]egenerate:** Asks the AI for a different approach.
- **[Q]uit:** Cancels the operation.

## Architecture

- **Bb.Core.dll:** A C# assembly (netstandard2.0) handling API communication, encryption, and safety heuristics.
- **bb.psm1:** A PowerShell script module providing the TUI and session integration.
- **bb.psd1:** The module manifest ensuring compatibility across PS 5.1 and 7.x.

## Safety Heuristics

`bb` includes a hardcoded blacklist that overrides AI risk assessments. Destructive verbs like `Remove-*`, `Stop-*`, and `Format-*` are automatically flagged as **High Risk**, requiring explicit user confirmation before execution.

---
*Built with Gemini CLI.*
