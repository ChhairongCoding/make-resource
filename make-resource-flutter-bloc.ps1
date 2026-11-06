param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The feature name in PascalCase (e.g. Profile or UserProfile)")]
    [string]$FeatureName,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The target feature directory pattern containing {name} (e.g. lib/features/{name})")]
    [string]$DirectoryPattern
)

# Handle PascalCase and snake_case naming conventions
$featurePascalCase = $FeatureName.Substring(0, 1).ToUpper() + $FeatureName.Substring(1)
$featureSnakeCase = ($featurePascalCase -creplace '([A-Z]+)([A-Z][a-z])', '$1_$2' -creplace '([a-z\d])([A-Z])', '$1_$2').ToLower()

$configurationFilePath = ".scaffold-config.json"
$selectedDirectoryPattern = $DirectoryPattern

# 1. Check if DirectoryPattern parameter was explicitly supplied
if (-not [string]::IsNullOrWhiteSpace($selectedDirectoryPattern)) {
    $persistedConfiguration = @{}
    if (Test-Path $configurationFilePath) {
        try {
            $persistedConfiguration = (Get-Content -Path $configurationFilePath -Encoding utf8 | ConvertFrom-Json)
        } catch {
            $persistedConfiguration = @{}
        }
    }
    $persistedConfiguration.flutterFeatureDirectoryPattern = $selectedDirectoryPattern
    $persistedConfiguration | ConvertTo-Json | Set-Content -Path $configurationFilePath -Encoding utf8
}

# 2. Check saved project configuration file if parameter was not passed
if ([string]::IsNullOrWhiteSpace($selectedDirectoryPattern) -and (Test-Path $configurationFilePath)) {
    try {
        $savedConfiguration = Get-Content -Path $configurationFilePath -Encoding utf8 | ConvertFrom-Json
        if (-not [string]::IsNullOrWhiteSpace($savedConfiguration.flutterFeatureDirectoryPattern)) {
            $selectedDirectoryPattern = $savedConfiguration.flutterFeatureDirectoryPattern
            Write-Host "Using configured feature directory pattern: $selectedDirectoryPattern" -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Unable to read $configurationFilePath. Continuing with detection."
    }
}

# 3. Auto-detect default pattern based on Flutter project structure
$detectedDefaultPattern = "lib/features/{name}"
if ([string]::IsNullOrWhiteSpace($selectedDirectoryPattern)) {
    if (Test-Path "lib/features") {
        $detectedDefaultPattern = "lib/features/{name}"
    }

    $userInputPattern = Read-Host "Enter feature directory pattern [Default: $detectedDefaultPattern] (use {name} as placeholder)"
    if ([string]::IsNullOrWhiteSpace($userInputPattern)) {
        $selectedDirectoryPattern = $detectedDefaultPattern
    } else {
        $selectedDirectoryPattern = $userInputPattern.Trim()
    }

    $persistedConfiguration = @{}
    if (Test-Path $configurationFilePath) {
        try {
            $persistedConfiguration = (Get-Content -Path $configurationFilePath -Encoding utf8 | ConvertFrom-Json)
        } catch {
            $persistedConfiguration = @{}
        }
    }
    $persistedConfiguration.flutterFeatureDirectoryPattern = $selectedDirectoryPattern
    $persistedConfiguration | ConvertTo-Json | Set-Content -Path $configurationFilePath -Encoding utf8
    Write-Host "Saved directory configuration to $configurationFilePath" -ForegroundColor Gray
}

$featureDirectoryPath = $selectedDirectoryPattern.Replace("{name}", $featureSnakeCase)

function Write-ScaffoldFile {
    param (
        [string]$TargetFilePath,
        [string]$FileContent
    )
    if (Test-Path $TargetFilePath) {
        Write-Warning "File already exists, skipping: $TargetFilePath"
    } else {
        $parentDirectoryPath = Split-Path -Parent $TargetFilePath
        if (-not (Test-Path $parentDirectoryPath)) {
            New-Item -ItemType Directory -Path $parentDirectoryPath -Force | Out-Null
        }
        Set-Content -Path $TargetFilePath -Value $FileContent.Trim() -Encoding utf8
        Write-Host "Created: $TargetFilePath" -ForegroundColor Green
    }
}

# 1. Event (Modern Dart 3 sealed class)
$eventFileContent = @"
import 'package:equatable/equatable.dart';

sealed class ${featurePascalCase}Event extends Equatable {
  const ${featurePascalCase}Event();

  @override
  List<Object?> get props => [];
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/bloc/${featureSnakeCase}_event.dart" -FileContent $eventFileContent

# 2. State (Modern Dart 3 sealed class)
$stateFileContent = @"
import 'package:equatable/equatable.dart';

sealed class ${featurePascalCase}State extends Equatable {
  const ${featurePascalCase}State();

  @override
  List<Object?> get props => [];
}

final class ${featurePascalCase}Initial extends ${featurePascalCase}State {
  const ${featurePascalCase}Initial();
}

final class ${featurePascalCase}Loading extends ${featurePascalCase}State {
  const ${featurePascalCase}Loading();
}

final class ${featurePascalCase}Success extends ${featurePascalCase}State {
  const ${featurePascalCase}Success();
}

final class ${featurePascalCase}Failure extends ${featurePascalCase}State {
  final String errorMessage;

  const ${featurePascalCase}Failure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/bloc/${featureSnakeCase}_state.dart" -FileContent $stateFileContent

# 3. Bloc (Business Logic Component)
$blocFileContent = @"
import 'package:flutter_bloc/flutter_bloc.dart';

import '${featureSnakeCase}_event.dart';
import '${featureSnakeCase}_state.dart';

export '${featureSnakeCase}_event.dart';
export '${featureSnakeCase}_state.dart';

class ${featurePascalCase}Bloc extends Bloc<${featurePascalCase}Event, ${featurePascalCase}State> {
  ${featurePascalCase}Bloc() : super(const ${featurePascalCase}Initial()) {
    // TODO: Register event handlers
  }
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/bloc/${featureSnakeCase}_bloc.dart" -FileContent $blocFileContent

# 4. Model (Data Model Class)
$modelFileContent = @"
class ${featurePascalCase}Model {
  final int? id;

  const ${featurePascalCase}Model({
    this.id,
  });
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/model/${featureSnakeCase}_model.dart" -FileContent $modelFileContent

# 5. Repository (Data Access Class)
$repositoryFileContent = @"
class ${featurePascalCase}Repository {
  const ${featurePascalCase}Repository();
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/repository/${featureSnakeCase}_repository.dart" -FileContent $repositoryFileContent

# 6. Screen (UI View)
$screenFileContent = @"
import 'package:flutter/material.dart';

class ${featurePascalCase}Screen extends StatelessWidget {
  const ${featurePascalCase}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${featurePascalCase}'),
      ),
      body: const Center(
        child: Text('${featurePascalCase}Screen'),
      ),
    );
  }
}
"@
Write-ScaffoldFile -TargetFilePath "$featureDirectoryPath/screen/${featureSnakeCase}_screen.dart" -FileContent $screenFileContent

# 7. Screen Widget Directory
$widgetDirectoryPath = "$featureDirectoryPath/screen/widget"
if (-not (Test-Path $widgetDirectoryPath)) {
    New-Item -ItemType Directory -Path $widgetDirectoryPath -Force | Out-Null
    Write-Host "Created: $widgetDirectoryPath/" -ForegroundColor Green
}

Write-Host "`nFeature scaffolding completed successfully for ${featurePascalCase}!" -ForegroundColor Cyan
