# Make Resources: CLI Scaffolding Utilities

A collection of lightweight, zero-dependency PowerShell scaffolding utilities for Spring Boot and Flutter. They allow you to instantly generate clean architecture boilerplate components directly from your terminal.

---

## Utilities Included

1. [Spring Boot Resource Scaffolder](#1-spring-boot-resource-scaffolder) (`make-resource-spring-boot.ps1`)
2. [Flutter Feature Scaffolder](#2-flutter-feature-scaffolder) (`make-resource-flutter-bloc.ps1`)

---

## 1. Spring Boot Resource Scaffolder

Generates standard Spring Boot CRUD resource components: Entity, DTO, Response, Repository, Service, Service Implementation, and REST Controller.

### Features
- **Smart Package Resolution**: Auto-detects base package from `src/main/java/**/*Application.java`, accepts `-BasePackage`, or prompts interactively.
- **Project Cache**: Remembers your project package in `.scaffold-config.json` so you only configure it once per project.
- **Pluralization**: Infers plural REST endpoints and table names (e.g. `Appointment` &rarr; `appointments`, `Category` &rarr; `categories`).
- **Conflict Safe**: Skips existing files to prevent overwriting your implemented code.

### Usage

```powershell
powershell -ExecutionPolicy Bypass -File path/to/make-resource-spring-boot.ps1 -ResourceName Appointment
```

Or specify the base package explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File path/to/make-resource-spring-boot.ps1 -ResourceName Appointment -BasePackage com.petcare.api
```

---

## 2. Flutter Feature Scaffolder

Generates a complete, modular Flutter feature folder containing the BLoC triad, screen, widget directory, and repository skeleton.

### Generated Directory Structure

For `-FeatureName Profile`:

```
lib/features/profile/
├── bloc/
│   ├── profile_bloc.dart
│   ├── profile_event.dart
│   └── profile_state.dart
├── model/
│   └── profile_model.dart
├── repository/
│   └── profile_repository.dart
└── screen/
    ├── profile_screen.dart
    └── widget/
```

### Features
- **Clean Class Skeletons**: Outputs pure class declarations without boilerplate method clutter.
- **Dart 3 Sealed Classes**: Event and State use modern `sealed class` hierarchies with `Equatable`.
- **Barrel Exports in BLoC**: `profile_bloc.dart` exports event and state so UI widgets only need to import the BLoC.
- **Configurable Directory Pattern**: Defaults to `lib/features/{name}` and remembers your custom setting in `.scaffold-config.json`.

### Usage

Basic feature generation:

```powershell
powershell -ExecutionPolicy Bypass -File path/to/make-resource-flutter-bloc.ps1 -FeatureName Profile
```

With custom feature directory pattern:

```powershell
powershell -ExecutionPolicy Bypass -File path/to/make-resource-flutter-bloc.ps1 -FeatureName Profile -DirectoryPattern "lib/features/{name}"
```

---

## Setup Global Aliases (Optional)

Add convenient aliases to your PowerShell profile so you can run them from anywhere in any project terminal:

1. Open profile:
   ```powershell
   notepad $PROFILE
   ```
2. Add function aliases:
   ```powershell
   function New-SpringBootResource {
       param(
           [Parameter(Mandatory = $true, Position = 0)]
           [string]$ResourceName,
           [Parameter(Mandatory = $false, Position = 1)]
           [string]$BasePackage
       )
       & "C:\Users\PC\Documents\make-resources\make-resource-spring-boot.ps1" -ResourceName $ResourceName -BasePackage $BasePackage
   }
   Set-Alias make-resource New-SpringBootResource

   function New-FlutterFeature {
       param(
           [Parameter(Mandatory = $true, Position = 0)]
           [string]$FeatureName,
           [Parameter(Mandatory = $false, Position = 1)]
           [string]$DirectoryPattern
       )
       & "C:\Users\PC\Documents\make-resources\make-resource-flutter-bloc.ps1" -FeatureName $FeatureName -DirectoryPattern $DirectoryPattern
   }
   Set-Alias make-feature New-FlutterFeature
   ```
3. Reload your terminal:
   ```powershell
   make-resource Appointment
   make-feature Profile
   ```

---

## Pushing to GitHub

```bash
git add .
git commit -m "feat: update flutter scaffolder to generate complete feature structure with bloc, screen, widget, and repository"
git branch -M main
git remote add origin https://github.com/<your-username>/make-resources.git
git push -u origin main
```
