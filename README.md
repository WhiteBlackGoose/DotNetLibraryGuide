**WARNING**: it's not finished yet!!! Do **not** use it right now!

Feel free to PR though.

# .NET Library Generator

[**Download**](https://raw.githubusercontent.com/WhiteBlackGoose/DotNetLibraryGuide/main/gen.ps1) powershell library generator. Run it and follow the instructions.

```
./gen.ps1
```

# .NET Library Guide

This is a cheat-sheet about all key points of creating a github repo for your nuget library.

For simplicity I take library's name as `MyLibrary`, so one shall substitute their lib's actual name.

This all is my recommendation, feel free to do what works for you at any point.

#### Navigation 
- [The overall Github repo structure](#The-overall-Github-repo-structure)
  - [Sources folder](#sources-folder)
  - [Tests folder](#tests-folder)
  - [Benchmarks folder](#benchmarks-folder)
  - [Samples folder](#samples-folder)
  - [Playground folder](#samples-folder)
- [CI and Github Actions](#CI-and-Github-Actions)
- [Readme and license](#readme-license)
- [Adding experimental packages](#Adding-experimental-packages)
- [How to do it fast](#how-to-do-it-fast)
- [VS Code support](#vs-code-support)

## The overall Github repo structure

We will have four main folders: `Sources`, `Tests`, `Benchmarks`, and `Samples`. I name them Pascal-case and full name to be aligned with .NET BCL's naming convention, even though one can of course have `src`/`tests`/etc. if they want.

Each of this folder has `Directory.Build.props` and `Directory.Build.targets` files, that we [will speak about later](). There's also `Playground` that I explain [here](#playground).

`README.md` and `LICENSE` are must haves for a public library. The former works very well as a "marketing" factor and describes superficially what the project is about. The latter is needed if you want to let people use your library.

Here's a possible structure of your github repo:

```
.git
README.md
LICENSE
YourLibrary.sln
.github/workflows/
    BuildAndTest.yml
    PublishNightly.yml
Sources/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.Core/ (also, .Shared or .Common, whatever you prefer)
        YourLibrary.Core.csproj
    YourLibrary.ModuleA/
        YourLibrary.ModuleA.csproj (fsproj, vbproj, ilproj, etc. whatever your language is)
    YourLibrary.ModuleB/
        YourLibrary.ModuleB.csproj
Tests/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.Tests/
        YourLibrary.ModuleA.Tests.csproj
    YourLibrary.ModuleB.Tests/
        YourLibrary.ModuleB.Tests.csproj
Benchmarks/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.Benchmarks/
        YourLibrary.ModuleA.Benchmarks.csproj
    YourLibrary.ModuleB.Benchmarks/
        YourLibrary.ModuleA.Benchmarks.csproj
Samples
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.Sample/
        YourLibrary.ModuleA.Sample.csproj
    YourLibrary.ModuleB.Sample/
        YourLibrary.ModuleB.Sample.csproj
Playground
    YourLibrary.ModuleA.Playground/
      YourLibrary.ModuleA.Playground.csproj
    YourLibrary.ModuleB.Playground/
      YourLibrary.ModuleB.Playground.csproj
```

### Sources folder

This is the core of our repo, the place where our multiple nuget packages reside. I recommend them naming as your library's name, then dot, then the module's name:

```
Sources/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.Core/
        YourLibrary.Core.csproj
        icon.png
        README.md
    YourLibrary.ModuleA/
        YourLibrary.ModuleA.csproj
        icon.png
        README.md
    YourLibrary.ModuleB/
        YourLibrary.ModuleB.csproj
        icon.png
        README.md
```

`YourLibrary.Core` (or `.Common` or `.Shared`) may be needed if you have some code shared between your modules, so other modules should be dependent on it.

Now, your `.csproj` files must define only those properties which are unique to each module, whereas all common/shared properties are defined in `Directory.Build.*` files.

#### Directory.Build.props

This file gets included before anything else. Here I include package information. For example, here what it may look like:
```xml
<?xml version="1.0" encoding="utf-8"?>
<Project>
  <PropertyGroup>
    <Version>1.0.0</Version>
    
    <TargetFrameworks>netstandard2.0;net6.0</TargetFrameworks>   <!-- this may be wrong if your modules don't target the same frameworks! -->
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    
    <Authors>WhiteBlackGoose</Authors>
    <Copyright>© WhiteBlackGoose 2022</Copyright>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <PackageRequireLicenseAcceptance>false</PackageRequireLicenseAcceptance>
    
    <PackageTags>someTag, anotherTag</PackageTags>
                 
    <RepositoryType>git</RepositoryType>
    <PackageProjectUrl>yourWebsite</PackageProjectUrl>
    <RepositoryUrl>https://github.com/WhiteBlackGoose/Repo</RepositoryUrl>
  </PropertyGroup>
  
  
  <!-- this assumes you put your logo in every (!) project's folder 
       as well as README.md -->
  <PropertyGroup>
    <PackageIcon>icon.png</PackageIcon>
    <PackageReadmeFile>PackageReadme.md</PackageReadmeFile>
  </PropertyGroup>
  
  <ItemGroup>
    <None Include="icon.png" Pack="True" PackagePath="" />
    <None Include="README.md" Pack="True" PackagePath="" />
  </ItemGroup>
</Project>
```

#### Directory.Build.targets

This file is included the last, so it can override properties. Here one can include `PackageReference` `Update` attributes. The reason is to make sure that the dependencies' versions are set in just one place. For example,

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project>
  <ItemGroup>
    <PackageReference Update="Microsoft.NET.Test.Sdk" Version="17.0.0" />
    <PackageReference Update="Microsoft.SourceLink.GitHub" Version="1.1.1" />
    <PackageReference Update="NUnit" Version="3.13.2" />
    <PackageReference Update="NUnit3TestAdapter" Version="4.0.0" />
  </ItemGroup>
</Project>
```

Now, whenever you need a dependency in your module, you do `PackageReference Include="YourDependency"` but do not specify the version (unless you need a particular one of course).

#### Proj file

It doesn't matter if it's `csproj` (C#) or `fsproj` (F#) or `vbproj` (VB.NET) or `ilproj` (IL) or other. However, there is old project style and new [*SDK-style*](https://docs.microsoft.com/en-us/dotnet/core/project-sdk/overview), and I'm only considering the latter.

This time we want to specify things unique to a module. Its name, possibly its version.

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <PackageId>YourLibrary.ModuleA</PackageId>
    <Product>YourLibrary.ModuleA</Product>
    
    <Description>Provides something</Description>
    <PackageTags>$(PackageTags), moduleA, somethingUniqueHere</PackageTags>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="YourLibrary.Core" />
    <ProjectReference Include="SomeDependency" />    <!-- no version specified! -->
  </ItemGroup>
</Project>
```

> **TODO**: can we include `YourLibrary.Core` in `Directory.Build.props` and conditionally exclude it for `YourLibrary.Core` (to avoid circular dep)?

### Tests folder

Similarly to Sources' we have a structure

```
Tests/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.Tests/
        YourLibrary.ModuleA.Tests.csproj
    YourLibrary.ModuleB.Tests/
        YourLibrary.ModuleB.Tests.csproj
```
So every project (and its containing folder) as `.Tests` suffix.

The idea here is similar to `Sources`, so we just include common things in `Directory.Build.props` and `Directory.Build.targets`, such as test runners (you can even do `Include` instead of `Update` since you likely want the same test library & runner).

> **TODO**: can we specify the dependeny for each test project in `Directory.Build.props` since we know that each `project.Tests` corresponds to `../Sources/project/project.csproj`?

#### Different types of tests

What if you want `FunctionalTests`, `UnitTests`, `IntegrationTests`, `RegressionTests`, `CodegenTests`, and not just `Tests`?

I'd keep them all in `Tests` folder but with corresponding suffixes, for example,
```
Tests/
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.RegressionTests/
        YourLibrary.ModuleA.RegressionTests.csproj
    YourLibrary.ModuleB.FunctionalTests/
        YourLibrary.ModuleB.FunctionalTests.csproj
    YourLibrary.ModuleB.UnitTests/
        YourLibrary.ModuleB.UnitTests.csproj
```

On the other hand, it may also make sense to either replace `Tests` with first-level folders for each type of tests, or instead add multiple types of tests to `Tests` folder and make corresponding projects in them.

### Samples folder

I personally recommend not loading a single project with all your modules, but split into its own samples. So the structure and the logic of it all follows that of the previous two things.

```
Samples
    Directory.Build.props
    Directory.Build.targets
    YourLibrary.ModuleA.Sample/
        YourLibrary.ModuleA.Sample.csproj
    YourLibrary.ModuleB.Sample/
        YourLibrary.ModuleB.Sample.csproj
```

### Playground

This set of projects helps contributors. It takes very little of anything, and simply reproduces what a contributor would have to do manually. Each `*.Playground` project depends on the corresponding module, and a contributor can simply write any code there playing with the module. Otherwise contributors have to create their own project/solution, so by doing that we just make our lives a bit more convenient.

```
Playground
    YourLibrary.ModuleA.Playground/
      YourLibrary.ModuleA.Playground.csproj
    YourLibrary.ModuleB.Playground/
      YourLibrary.ModuleB.Playground.csproj
```

## CI and Github Actions

Now that you set it all up, we are going to build and test it automatically, as well as produce a preview version for myget/nuget! Github Actions is an awesome platform for CI/CD (continuous integration/deployment).

### Build and test

Create `.github/workflows/BuildAndTest.yml` file:

```yml
name: 'Build and test everything'

# this is needed so that your tests aren't duplicated when you, maintainer, PR against your main
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - '*'

jobs:
  Build:
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]

    # you can replace it with, for example, windows-latest if you only need one OS
    runs-on: ${{ matrix.os }}
    
    steps:
    - name: 'Clone repo with all its submodules'
      uses: actions/checkout@v2
      with:
        submodules: 'recursive'
    
    - name: Setup .NET 6
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: '6.0.100'
        # include-prerelease: true  if you need prerelease, uncomment this and replace the version with `7.0.x` if you need any
    
    - name: 'Build YourLibrary'
      run: dotnet build   # just that! it will build your whole solution

  Test:
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
    - name: 'Clone repo with all its submodules'
      uses: actions/checkout@v2
      with:
        submodules: 'recursive'
    - name: Setup .NET 6
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: '6.0.100'
    - name: 'Test YourLibrary'
      run: dotnet test
```

> **TODO**: avoid duplication

One can make a job for each of their package instead, so that it'd be easier seen which exactly test failed.

### Publish preview

Now we can pack our package and publish on MyGet (you can choose something else, of course, like NuGet, GH Packages, or even your own server).

As a version I will use `0.0.0-main-$currtime-$commithash` to make sure that
1) They're unique
2) They're sorted in the correct way
3) One can easily track the exact commit by the version

To create `NuGet.Config` run
```
dotnet new nugetconfig
```

Here's source:
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="myget" value="https://www.myget.org/F/angourimath/api/v3/index.json" />
  </packageSources>
</configuration>
```

(you can of course do it all dynamically, with dotnet CLI, see [dotnet nuget add source](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source))

> **TODO**: add example of how to do it without having Nuget.Config in the repo

```yml
name: 'Upload last-main versions to MyGet'

on:
  push:
    branches:
      - main

jobs:
  main:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-dotnet@v1
        with:
          dotnet-version: '6.0.100'
      
      - uses: actions/checkout@v2

      - name: 'Pack and publish'
        run: |
          cd Sources
          
          # versioning
          commithash=$(git rev-parse --short HEAD)
          currtime=$(date +%s)
          echo "commit hash is $commithash"
          echo "time is $currtime"
          name=0.0.0-main-$currtime-$commithash
          echo "version is $name"
          
          # Module A
          cd ModuleA
          dotnet restore
          dotnet pack -c release -p:PackageVersion=$name
          cd bin/release
          dotnet nuget push YourLibrary.ModuleA.$name.nupkg --api-key ${{ secrets.MYGET_KEY }} --source "myget"
          cd /../../..
          
          # same way all modules
```

> **TODO**: add somewhat automatic script to push all versions.

## README and license

That is a much more important part of a repo than many people think. This is what can block your users from using your library. Indeed, readme should not disguise the newcomers but instead tell briefly about the project. 

> **TODO**: how do we choose license? [GH's guide](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)

## Adding experimental package

It is about so-called `preview` features. Assume you want to add a version of your package which would use them.

I add `Experimental` suffix to my package, for example,
```
YourLibrary.ModuleA/
  YourLibrary.ModuleA.csproj
YourLibrary.ModuleA.Experimental/
  YourLibrary.ModuleA.Experimental.csproj
```

Now the sources are stored in the non-experimental one, but they're removed in compile time, e. g.

Fragment from YourLibrary.ModuleA.csproj:
```xml
<ItemGroup>
  <Compile Remove="Core/Entity/GenericMath/**" />
  <Compile Remove="RequiresPreviewFeaturesAttribute.cs" />
</ItemGroup>
```

Fragment from YourLibrary.ModuleA.Experimental.csproj:
```xml
  <ItemGroup>
    <Compile Include="../YourLibrary.ModuleA/**/*.cs" />
    
    <Compile          Remove="../YourLibrary.ModuleA/obj/**" />
    <EmbeddedResource Remove="../YourLibrary.ModuleA/obj/**" />
    <None             Remove="../YourLibrary.ModuleA/obj/**" />
    
    <Compile          Remove="../YourLibrary.ModuleA/bin/**" />
    <EmbeddedResource Remove="../YourLibrary.ModuleA/bin/**" />
    <None             Remove="../YourLibrary.ModuleA/bin/**" />
  </ItemGroup>

  <PropertyGroup>
    <EnablePreviewFeatures>True</EnablePreviewFeatures>
  </PropertyGroup>

  <ItemGroup>
    <!--.NET 6 generic math-->
    <PackageReference Include="System.Runtime.Experimental" Version="6.0.0-preview.7.21377.19" />
  </ItemGroup>
```

## How to do it fast

Doing it all from VS or Rider GUI is absolutely awful. So, our saviour is dotnet CLI!

Clone your newly created repo:
```
git clone https://github.com/You/YourLibrary
cd YourLibrary
```

Create solution file:
```
dotnet new sln -n YourLibrary
```

Create folders:
```
mkdir Sources
mkdir Tests
mkdir Benchmarks
mkdir Samples
mkdir Playground
```

Create modules:
```
cd Sources
dotnet new classlib --name YourLibrary.ModuleA -f netstandard2.0 -lang C#
dotnet new classlib --name YourLibrary.ModuleB -f netstandard2.0 -lang C#

cd ../
cd Tests

dotnet new xunit --name YourLibrary.ModuleA.Tests -f net6.0 -lang C#
dotnet new xunit --name YourLibrary.ModuleB.Tests -f net6.0 -lang C#

cd ../
cd Benchmarks

dotnet new console --name YourLibrary.ModuleA.Benchmarks -f net6.0 -lang C#
dotnet new console --name YourLibrary.ModuleB.Benchmarks -f net6.0 -lang C#

# etc
```

> **TODO**: what's the convenient and *cross-platform* way to make `Directory.Build.props`? Can we do it with CLI?

Add references:
```
dotnet add Tests/YourLibrary.ModuleA.Tests/YourLibrary.ModuleA.Tests.csproj reference Sources/YourLibrary.ModuleA/YourLibrary.ModuleA.csproj
```

> **TODO**: okay, this can definitely be done in powershell much easier.

## VS Code Support

This awesome text editor works great for "pure" libraries, that is, those which don't involve some frameworks, like GUI ones. So it'd be very convenient for contributors on VSC if two files were created for them:

```
.vscode/
  tasks.json
  launch.json
```

> **TODO**: finish this section