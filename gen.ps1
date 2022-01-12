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

Write-Host "Hey. This script generates .net library template! Answer a few questions and then the script will start."

$libraryName = Request "Your whole library name?"
$modules     = Request "List all modules"
$libTarget   = Request "Enter target for your library (default: netstandard2.0)"                      "netstandard2.0"
$exeTarget   = Request "Target framework for tests/samples/benchmarks/playground (default: net6.0):"  "net6.0"
$testFw      = Request "Test framework (default: xUnit):"                                             "xunit"

dotnet new sln -n $LibraryName

New-Item -Name "Sources"     -ItemType "directory"
New-Item -Name "Tests"       -ItemType "directory"
New-Item -Name "Benchmarks"  -ItemType "directory"
New-Item -Name "Samples"     -ItemType "directory"
New-Item -Name "Playground"  -ItemType "directory" 

$folders = "Sources", "Tests", "Benchmarks", "Samples", "Playground"

for ($i = 0; $i -lt $folders.Count; $i++)
{
    New-Item -Path $folders[$i] -Name "Directory.Build.props"
    New-Item -Path $folders[$i] -Name "Directory.Build.targets"
}

for ($i = 0; $i -lt $modules.Count; $i++)
{
    $module     = $LibraryName + "." + $modules[$i]
    $test       = $module + ".Tests"
    $benchmark  = $module + ".Benchmarks"
    $sample     = $module + ".Sample"
    $playground = $module + ".Playground"
    $lang       = "C#"
    $postfix    = ".csproj"
    
    Set-Location Sources
    dotnet new classlib -n $module -f $libTarget -lang $lang
    Set-Location ..
    
    Set-Location Tests
    dotnet new $testFw -n $test -f $exeTarget -lang $lang
    Set-Location ..
    
    Set-Location Benchmarks
    dotnet new console -n $benchmark -f $exeTarget -lang $lang
    Set-Location ..
    
    Set-Location Samples
    dotnet new console -n $sample -f $exeTarget -lang $lang
    Set-Location ..
    
    Set-Location Playground
    dotnet new console -n $Playground -f $exeTarget -lang $lang
    Set-Location ..
    
    dotnet add reference Tests/$test/$test.$postfix                  Sources/$module/$module.$postfix
    dotnet add reference Benchmarks/$benchmark/$benchmark.$postfix   Sources/$module/$module.$postfix
    dotnet add reference Samples/$sample/$sample.$postfix            Sources/$module/$module.$postfix
    dotnet add reference Playground/$playground/$playground.$postfix Sources/$module/$module.$postfix
    
    dotnet sln add Sources/$module
    dotnet sln add Tests/$test
    dotnet sln add Benchmarks/$benchmark
    dotnet sln add Samples/$sample
    dotnet sln add Playground/$Playground
}