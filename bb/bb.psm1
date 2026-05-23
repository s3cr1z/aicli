# bb.psm1 - PowerShell Wrapper for bb CLI

$ModuleRoot = $PSScriptRoot
$BinaryPath = Join-Path $ModuleRoot "bin\Bb.Core.dll"

# --- Module Initialization ---

$script:HasSpectre = $false

function Initialize-BbModule {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # PowerShell 7+: Use AssemblyLoadContext to avoid collisions
        $ALC = [System.Runtime.Loader.AssemblyLoadContext]::new("BbContext")
        [void]$ALC.LoadFromAssemblyPath($BinaryPath)

        # Optional Spectre.Console loading (PS 7.2+)
        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 2) {
            if (Get-Module -ListAvailable PwshSpectreConsole) {
                Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
                $script:HasSpectre = (Get-Command Out-SpectreHost -ErrorAction SilentlyContinue) -ne $null
            }
        }
    } else {
        # Windows PowerShell 5.1: Add-Type
        Add-Type -Path $BinaryPath
    }
}

# Load the binary core
Initialize-BbModule

# --- Core Functions ---

$script:LastPrompt = ""

function bb {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$PromptParts
    )

    $Prompt = $PromptParts -join " "
    if (-not $Prompt) {
        Write-Host "Usage: bb <your natural language instruction>" -ForegroundColor Cyan
        return
    }

    $script:LastPrompt = $Prompt

    # 1. Gather Context
    $LastError = $null
    if ($Error.Count -gt 0) {
        $LastError = $Error[0].ToString()
    }

    $Context = @{
        CWD = $ExecutionContext.SessionState.Path.CurrentLocation.Path
        OS = $PSVersionTable.OS
        PSVersion = $PSVersionTable.PSVersion.ToString()
        LastError = $LastError
    }

    # 2. Query AI
    $Config = Get-BbConfig
    if (-not $Config.ApiKey) {
        Write-Error "API Key not found. Please run 'bb-config' to set your API key."
        return
    }

    # Build a context-aware prompt
    $ContextPrompt = "Current Directory: $($Context.CWD)`n"
    $ContextPrompt += "OS: $($Context.OS)`n"
    if ($Context.LastError) {
        $ContextPrompt += "Last Error: $($Context.LastError)`n"
    }
    $ContextPrompt += "User Prompt: $Prompt"

    Write-Host "Thinking..." -ForegroundColor Gray
    
    try {
        $Response = Invoke-BbAiQuery -Prompt $ContextPrompt `
                                    -Endpoint $Config.Endpoint `
                                    -ApiKey $Config.ApiKey `
                                    -Model $Config.Model
    } catch {
        Show-BbError -ErrorRecord $_ -Provider $Config.DefaultProvider
        return
    }

    # 3. Show Action Bar TUI
    Show-BbActionBar -AiResponse $Response
}

function Show-BbError {
    param($ErrorRecord, $Provider)

    $Message = $ErrorRecord.Exception.Message
    Write-Host "`n--- bb Failure ---" -ForegroundColor Red
    
    if ($Message -match "401|403") {
        Write-Host "Authentication failed for provider '$Provider'." -ForegroundColor Yellow
        Write-Host "Run 'bb-config' to update your API key." -ForegroundColor Gray
    } elseif ($Message -match "429") {
        Write-Host "Rate limit exceeded for '$Provider'." -ForegroundColor Yellow
        Write-Host "Try again in a few moments or use 'bb-use' to switch providers." -ForegroundColor Gray
    } elseif ($Message -match "timeout" -or $ErrorRecord.FullyQualifiedErrorId -match "OperationCanceled") {
        Write-Host "Request to '$Provider' timed out." -ForegroundColor Yellow
        Write-Host "Check your connection or try a different model." -ForegroundColor Gray
    } elseif ($Message -match "dns|network|unreachable") {
        Write-Host "bb is offline or cannot reach '$Provider'." -ForegroundColor Yellow
        Write-Host "Check your internet connection." -ForegroundColor Gray
    } else {
        Write-Host "An unexpected error occurred: $Message" -ForegroundColor Red
    }
    Write-Host "------------------`n"
}

function Set-BbConfig {
    param(
        [string]$Provider = "openai",
        [string]$ApiKey,
        [string]$Endpoint = "https://api.openai.com/v1/chat/completions",
        [string]$Model = "gpt-4o-mini"
    )

    if (-not $ApiKey) {
        $ApiKey = Read-Host "Enter API Key for $Provider" -AsSecureString
        # Convert SecureString to string for DPAPI
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey)
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

    [Bb.Core.Services.CredentialStore]::SetSecret($Provider, $ApiKey)
    
    $Config = @{
        DefaultProvider = $Provider
        Endpoint = $Endpoint
        Model = $Model
    }
    $Config | ConvertTo-Json | Out-File (Join-Path $HOME ".bb-config.json")
    Write-Host "Config saved successfully." -ForegroundColor Green
}

function Set-BbContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Provider
    )

    $ConfigFile = Join-Path $HOME ".bb-config.json"
    if (-not (Test-Path $ConfigFile)) {
        Write-Error "Configuration not found. Run 'bb-config' first."
        return
    }

    $Config = Get-Content $ConfigFile | ConvertFrom-Json
    $Config.DefaultProvider = $Provider
    $Config | ConvertTo-Json | Out-File $ConfigFile
    Write-Host "Switched to provider: $Provider" -ForegroundColor Cyan
}

function Get-BbConfig {
    $ConfigFile = Join-Path $HOME ".bb-config.json"
    if (Test-Path $ConfigFile) {
        $Config = Get-Content $ConfigFile | ConvertFrom-Json
        $ApiKey = [Bb.Core.Services.CredentialStore]::GetSecret($Config.DefaultProvider)
        return @{
            ApiKey = $ApiKey
            Endpoint = $Config.Endpoint
            Model = $Config.Model
        }
    }
    return @{}
}

# --- TUI and Execution ---

function Show-BbActionBar {
    param($AiResponse)

    try {
        if ($script:HasSpectre) {
            # Placeholder for Spectre.Console usage
            Write-Host "`n> $($AiResponse.Command)" -ForegroundColor Green
            Write-Host "# $($AiResponse.Explanation)" -ForegroundColor Gray
        } else {
            Write-Host "`n> $($AiResponse.Command)" -ForegroundColor Green
            Write-Host "# $($AiResponse.Explanation)" -ForegroundColor Gray
        }
        
        $Color = switch ($AiResponse.Risk) {
            "high" { "Red" }
            "medium" { "Yellow" }
            default { "Cyan" }
        }
        Write-Host "[Risk: $($AiResponse.Risk)]" -ForegroundColor $Color

        if ($AiResponse.RequiresAdmin) {
            Write-Host "[Requires Admin]" -ForegroundColor Red
        }

        Write-Host "`n[E]xecute  [C]opy  [R]egenerate  [Q]uit" -NoNewline
        
        $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $Key = $KeyInfo.Character.ToString().ToLower()
        Write-Host "`n"

        switch ($Key) {
            "e" {
                Invoke-BbCommand -Command $AiResponse.Command
            }
            "c" {
                Set-Clipboard -Value $AiResponse.Command
                Write-Host "Command copied to clipboard." -ForegroundColor Cyan
            }
            "r" {
                Write-Host "Regenerating..."
                bb $script:LastPrompt
            }
            default {
                Write-Host "Cancelled." -ForegroundColor Gray
            }
        }
    } finally {
        # Cleanup if needed
    }
}

function Invoke-BbCommand {
    param($Command)

    try {
        # Execute in the caller's session state via dot-sourcing
        $sb = [scriptblock]::Create($Command)
        . $sb
    } catch {
        Write-Error "Command failed: $_"
    }
}

Set-Alias -Name bb-config -Value Set-BbConfig
Set-Alias -Name bb-use -Value Set-BbContext

Export-ModuleMember -Function bb, Set-BbConfig, Set-BbContext, Invoke-BbCommand -Alias bb, bb-config, bb-use
