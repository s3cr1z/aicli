@{
    # Version number of this module.
    ModuleVersion = '0.0.1'

    # ID used to uniquely identify this module
    GUID = 'b1b1b1b1-b1b1-b1b1-b1b1-b1b1b1b1b1b1' # Generate a unique one in a real scenario

    # Script module or binary module file associated with this module.
    RootModule = 'bb.psm1'

    # Author of this module
    Author = 'Gemini CLI'

    # Description of the functionality provided by this module
    Description = 'AI-powered, context-aware command line for PowerShell. Stop Googling, start shipping.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.7.2'

    # Modules to import as nested modules
    NestedModules = @('bin\Bb.Core.dll')

    # Functions to export
    FunctionsToExport = @('bb', 'Set-BbConfig', 'Set-BbContext', 'Invoke-BbCommand')

    # Cmdlets to export (from the binary)
    CmdletsToExport = @('Invoke-BbAiQuery')

    # Variables to export
    VariablesToExport = @()

    # Aliases to export
    AliasesToExport = @('bb-config', 'bb-use')

    # Compatible PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'CLI', 'PowerShell', 'Automation')
            ProjectUri = 'https://github.com/user/bb'
        }
    }
}
