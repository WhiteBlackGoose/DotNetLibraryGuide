function Assert-True
{
    [CmdletBinding()]
    param(
        [string] $Message,
        [bool] $Condition
    )
    if ( -not $Condition )
    {
        throw $Message
    }
}

function Request
{
    [CmdletBinding()]
    param(
        [string] $Message,
        [string] $Default = ""
    )
    Write-Host $Message
    $res = Read-Host
    if ($res -eq "")
    {
        return $Default
    }
    else
    {
        return $res
    }
}
function RequestArray
{
    [CmdletBinding()]
    param(
        [string] $Message
    )
    Write-Host $Message
    $res = Read-Host
    if ($res -eq "")
    {
        return $Default
    }
    else
    {
        return $res.Split()
    }
}

function Log
{
    [CmdletBinding()]
    param(
        [string] $Message
    )
    Write-Host "!!>> $Message"
}

Write-Host "Hey. This script generates .net library template! Answer a few questions and then the script will start."

$libraryName = Request      "Your whole library name?"
$authorName  = Request      "Author name (default: no name specified)"
$modules     = RequestArray "List all modules"
$libTarget   = Request      "Enter target for your library (default: netstandard2.0)"                      "netstandard2.0"
$exeTarget   = Request      "Target framework for tests/samples/benchmarks/playground (default: net6.0):"  "net6.0"
$testFw      = Request      "Test framework (default: xUnit):"                                             "xunit"
$license     = Request      "License (default: MIT):"                                                      "MIT"

dotnet new sln -n $LibraryName

Log "Solution created"

New-Item -Name "Sources"     -ItemType "directory"
New-Item -Name "Tests"       -ItemType "directory"
New-Item -Name "Benchmarks"  -ItemType "directory"
New-Item -Name "Samples"     -ItemType "directory"
New-Item -Name "Playground"  -ItemType "directory" 

Log "Folders created"

dotnet tool install dotnet-proj-cli --prerelease --tool-path "./__tmp_tool__/" --no-cache

Log "Tool temporarily installed"

# Directory.Build sector start

$dbp = "Directory.Build.props"
$dbt = "Directory.Build.targets"

Set-Location Sources
dotnet proj create -o $dbp
dotnet proj create -o $dbt

dotnet proj add -o $dbp -p TargetFrameworks -c $libTarget
if ($authorName -ne "")
{
    dotnet proj add -o $dbp -p Authors -c $authorName
}
dotnet proj add -o $dbp -p PackageLicenseExpression -c $license
Set-Location ..

Set-Location Tests
dotnet proj create -o $dbp
dotnet proj add -i PackageReference -a Include xunit Version 2.4.1
dotnet proj add -i PackageReference -a Include Microsoft.NET.Test.Sdk Version 17.0.0
dotnet proj add -p TargetFrameworks -c $exeTarget

dotnet proj create -o $dbt
Set-Location ..

Set-Location Benchmarks
dotnet proj create -o $dbp
dotnet proj add -p TargetFrameworks -c $exeTarget
dotnet proj add -p OutputType -c Exe
dotnet proj add -i PackageReference -a Include BenchmarkDotNet Version 0.13.1

dotnet proj create -o $dbt
Set-Location ..

Set-Location Samples
dotnet proj create -o $dbp
dotnet proj add -p OutputType -c Exe
dotnet proj add -p TargetFrameworks -c $exeTarget

dotnet proj create -o $dbt
Set-Location ..

Set-Location Playground
dotnet proj create -o $dbp
dotnet proj add -p OutputType -c Exe
dotnet proj add -p TargetFrameworks -c $exeTarget

dotnet proj create -o $dbt
Set-Location ..

Log "Directory.Build files created"

# Directory.Build sector end

for ($i = 0; $i -lt $modules.Count; $i++)
{
    $module     = $LibraryName + "." + $modules[$i]
    $test       = $module + ".Tests"
    $benchmark  = $module + ".Benchmarks"
    $sample     = $module + ".Sample"
    $playground = $module + ".Playground"
    $lang       = "C#"
    $postfix    = "csproj"
    $sourceProj = "Sources/$module/$module.$postfix"

    dotnet proj create -o "./Sources/$module/$module.$postfix"
    dotnet proj add    -o "./Sources/$module/$module.$postfix" -p PackageId -c $module
    dotnet proj add    -o "./Sources/$module/$module.$postfix" -p Product -c $module

    dotnet proj create -o "./Tests/$test/$test.$postfix"
    dotnet proj add    -o "./Tests/$test/$test.$postfix" -i ProjectReference -a Include "../../$sourceProj"

    dotnet proj create -o "./Benchmarks/$benchmark/$benchmark.$postfix"
    dotnet proj add    -o "./Benchmarks/$benchmark/$benchmark.$postfix" -i ProjectReference -a Include "../../$sourceProj"

    dotnet proj create -o "./Samples/$sample/$sample.$postfix"
    dotnet proj add    -o "./Samples/$sample/$sample.$postfix" -i ProjectReference -a Include "../../$sourceProj"

    dotnet proj create -o "./Playground/$playground/$playground.$postfix"
    dotnet proj add    -o "./Playground/$playground/$playground.$postfix" -i ProjectReference -a Include "../../$sourceProj"

    dotnet sln add "Sources/$module"
    dotnet sln add "Tests/$test"
    dotnet sln add "Benchmarks/$benchmark"
    dotnet sln add "Samples/$sample"
    dotnet sln add "Playground/$Playground"

    Log "Module $module created"
}

dotnet tool uninstall dotnet-proj-cli --tool-path "./__tmp_tool__/"