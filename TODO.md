# TODO: Fix PSScriptAnalyzer CI Errors

- [x] Rename `bb-config` to `Set-BbConfig` in `bb/bb.psm1`
- [x] Rename `bb-use` to `Set-BbContext` in `bb/bb.psm1`
- [x] Rename `Execute-BbCommand` to `Invoke-BbCommand` in `bb/bb.psm1`
- [x] Update internal call to `Execute-BbCommand` in `Show-BbActionBar`
- [x] Add `Set-Alias` for `bb-config` and `bb-use` in `bb/bb.psm1`
- [x] Update `Export-ModuleMember` in `bb/bb.psm1`
- [x] Update `FunctionsToExport` and `AliasesToExport` in `bb/bb.psd1`
- [x] Verify fix with `Invoke-ScriptAnalyzer` locally
- [x] Import module and verify aliases work
- [x] Commit and push changes to GitHub
