# TODO: Fix PSScriptAnalyzer CI Errors

- [ ] Rename `bb-config` to `Set-BbConfig` in `bb/bb.psm1`
- [ ] Rename `bb-use` to `Set-BbContext` in `bb/bb.psm1`
- [ ] Rename `Execute-BbCommand` to `Invoke-BbCommand` in `bb/bb.psm1`
- [ ] Update internal call to `Execute-BbCommand` in `Show-BbActionBar`
- [ ] Add `Set-Alias` for `bb-config` and `bb-use` in `bb/bb.psm1`
- [ ] Update `Export-ModuleMember` in `bb/bb.psm1`
- [ ] Update `FunctionsToExport` and `AliasesToExport` in `bb/bb.psd1`
- [ ] Verify fix with `Invoke-ScriptAnalyzer` locally
- [ ] Import module and verify aliases work
- [ ] Commit and push changes to GitHub
