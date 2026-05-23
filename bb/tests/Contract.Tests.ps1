$ModulePath = Resolve-Path (Join-Path $PSScriptRoot "..\bb.psd1")

Describe "bb CLI Contract Tests" {
    BeforeAll {
        Remove-Module bb -ErrorAction SilentlyContinue
        Import-Module $ModulePath -Force
    }

    It "Should change the current directory in the parent session" {
        $TempDir = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        
        try {
            # Mocking the internal execution logic for testing the contract
            # Since we can't easily mock the AI response without a lot of setup,
            # we directly test the Execute-BbCommand function which is the core of the contract.
            
            $OldDir = Get-Location
            Execute-BbCommand -Command "Set-Location '$TempDir'"
            
            (Get-Location).Path | Should Be $TempDir
            
            Set-Location $OldDir
        } finally {
            Remove-Item $TempDir -Recurse -Force
        }
    }

    It "Should persist variables in the parent session" {
        $VarName = "bb_test_var_" + ([Guid]::NewGuid().ToString().Replace("-", ""))
        $Value = "Hello from bb"
        
        Execute-BbCommand -Command "`$$VarName = '$Value'"
        
        Get-Variable $VarName -ValueOnly | Should Be $Value
        Remove-Variable $VarName -ErrorAction SilentlyContinue
    }
}
