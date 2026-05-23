# build.ps1 - Build and package the bb module

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..");
$SrcPath = Join-Path $ProjectRoot "src\Bb.Core\Bb.Core.csproj"
$OutputPath = Join-Path $ProjectRoot "bin"

# 1. Clean Output
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force

# 2. Build C# Core
Write-Host "Building Bb.Core..." -ForegroundColor Cyan
dotnet publish $SrcPath -c Release -f netstandard2.0 -o $OutputPath

# 3. Clean up unnecessary files from publish
Get-ChildItem $OutputPath -Include *.pdb, *.deps.json -Recurse | Remove-Item -Force

# 4. NetStandard.dll resolution hook (for PS 5.1)
$NetStandardDll = Join-Path $OutputPath "netstandard.dll"
if (-not (Test-Path $NetStandardDll)) {
    Write-Warning "netstandard.dll not found in output. Manually copying from SDK for PS 5.1 compatibility."
    # Attempt to find a standard netstandard.dll from the dotnet SDK
    $SdkPath = "C:\Program Files\dotnet\sdk"
    if (Test-Path $SdkPath) {
        $FoundDll = Get-ChildItem -Path $SdkPath -Filter netstandard.dll -Recurse | 
                     Where-Object { $_.FullName -match 'net461|netstandard2.0' } | 
                     Select-Object -First 1 -ExpandProperty FullName
        if ($FoundDll) {
            Copy-Item $FoundDll -Destination $OutputPath
            Write-Host "Copied netstandard.dll from $FoundDll" -ForegroundColor Gray
        }
    }
}

Write-Host "Build complete. Output located in $OutputPath" -ForegroundColor Green
