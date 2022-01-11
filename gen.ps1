function Assert-True
{
    [CmdletBinding()]
    param(
        $Message,
        $Condition
    )
    if ( -not $Condition )
    {
        throw $Message
    }
}

if ( $args.Count -eq 0 )
{
    Write-Host "Hey. This script generates .net library template."
    Write-Host "First argument is your library's name, and all other arguments are names"
    Write-Host "of your modules."
    return
}

Assert-True "Argument count ${$args.Count} to be at least 2" ($args.Count -gt 1)

$LibraryName = $args[0]
Assert-True "The library's name should be string!" ($LibraryName -is [String])

for ($i = 1; $i -lt $args.Count; $i++)
{
    Assert-True "The argument ${$args[$i]} was expected to be string" ($LibraryName -is [String])
}

dotnet new sln -n $LibraryName

New-Item -Name "Sources"     -ItemType "directory"
New-Item -Name "Tests"       -ItemType "directory"
New-Item -Name "Benchmarks"  -ItemType "directory"
New-Item -Name "Samples"     -ItemType "directory"
New-Item -Name "Playground"  -ItemType "directory" 

$folders = "Sources", "Tests", "Benchmarks", "Samples", "Playground"

for ($i = 0; $i -lt $folders.Count; $i++)
{
    New-Item -Path $folders[i] -Name "Directory.Build.props"
    New-Item -Path $folders[i] -Name "Directory.Build.targets"
}

for ($i = 1; $i -lt $args.Count; $i++)
{
    $module     = $LibraryName + "." + $args[$i]
    $test       = $module + ".Tests"
    $benchmark  = $module + ".Benchmarks"
    $sample     = $module + ".Sample"
    $playground = $module + ".Playground"
    $lang       = "C#"
    $libTarget  = "netstandard2.0"
    $exeTarget  = "net6.0"
    
    Set-Location Sources
    dotnet new classlib -n $module -f $libTarget -lang $lang
    Set-Location ..
    
    Set-Location Tests
    dotnet new xunit -n $test -f $exeTarget -lang $lang
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
    
    dotnet add reference Tests/$test/$test.csproj                  Sources/$module/$module.csproj
    dotnet add reference Benchmarks/$benchmark/$benchmark.csproj   Sources/$module/$module.csproj
    dotnet add reference Samples/$sample/$sample.csproj            Sources/$module/$module.csproj
    dotnet add reference Playground/$playground/$playground.csproj Sources/$module/$module.csproj
    
    dotnet sln add Sources/$module
    dotnet sln add Tests/$test
    dotnet sln add Benchmarks/$benchmark
    dotnet sln add Samples/$sample
    dotnet sln add Playground/$Playground
}