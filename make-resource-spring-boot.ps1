param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The resource name in PascalCase (e.g. Appointment)")]
    [string]$ResourceName,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The base Java package name (e.g. com.company.api)")]
    [string]$BasePackage
)

$resourcePascal = $ResourceName.Substring(0, 1).ToUpper() + $ResourceName.Substring(1)
$resourceCamel = $ResourceName.Substring(0, 1).ToLower() + $ResourceName.Substring(1)

# Handle basic English pluralization for API endpoint routes and table names
if ($resourceCamel.EndsWith("y") -and -not $resourceCamel.EndsWith("ey") -and -not $resourceCamel.EndsWith("ay") -and -not $resourceCamel.EndsWith("oy")) {
    $endpointRoute = $resourceCamel.Substring(0, $resourceCamel.Length - 1) + "ies"
} elseif ($resourceCamel.EndsWith("s") -or $resourceCamel.EndsWith("ch") -or $resourceCamel.EndsWith("sh") -or $resourceCamel.EndsWith("x")) {
    $endpointRoute = $resourceCamel + "es"
} else {
    $endpointRoute = $resourceCamel + "s"
}

$configurationFilePath = ".scaffold-config.json"
$targetPackageName = $BasePackage

# Check if BasePackage parameter was supplied
if (-not [string]::IsNullOrWhiteSpace($targetPackageName)) {
    @{ basePackage = $targetPackageName } | ConvertTo-Json | Set-Content -Path $configurationFilePath -Encoding utf8
}

# Check saved project configuration file if BasePackage was not passed
if ([string]::IsNullOrWhiteSpace($targetPackageName) -and (Test-Path $configurationFilePath)) {
    try {
        $savedConfiguration = Get-Content -Path $configurationFilePath -Encoding utf8 | ConvertFrom-Json
        if (-not [string]::IsNullOrWhiteSpace($savedConfiguration.basePackage)) {
            $targetPackageName = $savedConfiguration.basePackage
            Write-Host "Using configured base package: $targetPackageName" -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Unable to read $configurationFilePath. Continuing with detection."
    }
}

# Auto-detect base package from Spring Boot application class under src/main/java
$detectedPackageName = ""
if ([string]::IsNullOrWhiteSpace($targetPackageName) -and (Test-Path "src/main/java")) {
    $applicationFile = Get-ChildItem -Path "src/main/java" -Filter "*Application.java" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($applicationFile) {
        $packageMatchingLine = Get-Content -Path $applicationFile.FullName | Where-Object { $_ -match "^\s*package\s+([a-zA-Z0-9_.]+)\s*;" } | Select-Object -First 1
        if ($packageMatchingLine -match "^\s*package\s+([a-zA-Z0-9_.]+)\s*;") {
            $detectedPackageName = $matches[1]
        }
    }
}

# Prompt user if base package is still undefined
if ([string]::IsNullOrWhiteSpace($targetPackageName)) {
    if (-not [string]::IsNullOrWhiteSpace($detectedPackageName)) {
        $userInputPackageName = Read-Host "Enter base package [Default: $detectedPackageName]"
        if ([string]::IsNullOrWhiteSpace($userInputPackageName)) {
            $targetPackageName = $detectedPackageName
        } else {
            $targetPackageName = $userInputPackageName.Trim()
        }
    } else {
        $userInputPackageName = Read-Host "Enter base package (e.g. com.company.project)"
        if (-not [string]::IsNullOrWhiteSpace($userInputPackageName)) {
            $targetPackageName = $userInputPackageName.Trim()
        }
    }

    if ([string]::IsNullOrWhiteSpace($targetPackageName)) {
        Write-Error "Base package cannot be empty. Aborting scaffolding."
        exit 1
    }

    @{ basePackage = $targetPackageName } | ConvertTo-Json | Set-Content -Path $configurationFilePath -Encoding utf8
    Write-Host "Saved package configuration to $configurationFilePath" -ForegroundColor Gray
}

$packagePathSegment = $targetPackageName.Replace('.', '/')
$baseDirectory = "src/main/java/$packagePathSegment"

function Write-ScaffoldFile {
    param (
        [string]$TargetFilePath,
        [string]$FileContent
    )
    if (Test-Path $TargetFilePath) {
        Write-Warning "File already exists, skipping: $TargetFilePath"
    } else {
        $parentDirectory = Split-Path -Parent $TargetFilePath
        if (-not (Test-Path $parentDirectory)) {
            New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
        }
        Set-Content -Path $TargetFilePath -Value $FileContent.Trim() -Encoding utf8
        Write-Host "Created: $TargetFilePath" -ForegroundColor Green
    }
}

# 1. Entity (Skeleton)
$entityContent = @"
package ${targetPackageName}.model.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "${endpointRoute}")
@Getter
@Setter
@NoArgsConstructor
public class ${resourcePascal} {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/model/entity/${resourcePascal}.java" -FileContent $entityContent

# 2. DTO (Skeleton)
$dtoContent = @"
package ${targetPackageName}.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ${resourcePascal}DTO {
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/model/dto/${resourcePascal}DTO.java" -FileContent $dtoContent

# 3. Response (Skeleton)
$responseContent = @"
package ${targetPackageName}.model.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ${resourcePascal}Response {
    private Long id;
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/model/response/${resourcePascal}Response.java" -FileContent $responseContent

# 4. Repository (Skeleton)
$repositoryContent = @"
package ${targetPackageName}.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import ${targetPackageName}.model.entity.${resourcePascal};

@Repository
public interface ${resourcePascal}Repository extends JpaRepository<${resourcePascal}, Long> {
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/repository/${resourcePascal}Repository.java" -FileContent $repositoryContent

# 5. Service Interface (Function Signatures Only)
$serviceContent = @"
package ${targetPackageName}.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import ${targetPackageName}.model.dto.${resourcePascal}DTO;
import ${targetPackageName}.model.response.${resourcePascal}Response;

public interface ${resourcePascal}Service {
    Page<${resourcePascal}Response> getAll(Pageable pageable);

    ${resourcePascal}Response getById(Long id);

    ${resourcePascal}Response create(${resourcePascal}DTO request);

    ${resourcePascal}Response update(Long id, ${resourcePascal}DTO request);

    void delete(Long id);
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/service/${resourcePascal}Service.java" -FileContent $serviceContent

# 6. Service Implementation (Unimplemented Methods)
$serviceImplContent = @"
package ${targetPackageName}.service.serviceImp;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import ${targetPackageName}.model.dto.${resourcePascal}DTO;
import ${targetPackageName}.model.response.${resourcePascal}Response;
import ${targetPackageName}.repository.${resourcePascal}Repository;
import ${targetPackageName}.service.${resourcePascal}Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ${resourcePascal}ServiceImpl implements ${resourcePascal}Service {
    private final ${resourcePascal}Repository ${resourceCamel}Repository;

    @Override
    public Page<${resourcePascal}Response> getAll(Pageable pageable) {
        // TODO: Implement getAll
        return null;
    }

    @Override
    public ${resourcePascal}Response getById(Long id) {
        // TODO: Implement getById
        return null;
    }

    @Override
    public ${resourcePascal}Response create(${resourcePascal}DTO request) {
        // TODO: Implement create
        return null;
    }

    @Override
    public ${resourcePascal}Response update(Long id, ${resourcePascal}DTO request) {
        // TODO: Implement update
        return null;
    }

    @Override
    public void delete(Long id) {
        // TODO: Implement delete
    }
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/service/serviceImp/${resourcePascal}ServiceImpl.java" -FileContent $serviceImplContent

# 7. Controller (Unimplemented Endpoints)
$controllerContent = @"
package ${targetPackageName}.controller;

import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import ${targetPackageName}.model.dto.${resourcePascal}DTO;
import ${targetPackageName}.service.${resourcePascal}Service;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/${endpointRoute}")
public class ${resourcePascal}Controller {
    private final ${resourcePascal}Service ${resourceCamel}Service;

    @GetMapping
    public ResponseEntity<?> getAll(Pageable pageable) {
        // TODO: Implement getAll
        return null;
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        // TODO: Implement getById
        return null;
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody ${resourcePascal}DTO request) {
        // TODO: Implement create
        return null;
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(
            @PathVariable Long id,
            @Valid @RequestBody ${resourcePascal}DTO request) {
        // TODO: Implement update
        return null;
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        // TODO: Implement delete
        return null;
    }
}
"@
Write-ScaffoldFile -TargetFilePath "$baseDirectory/controller/${resourcePascal}Controller.java" -FileContent $controllerContent

Write-Host "`nScaffolding skeleton completed successfully for ${resourcePascal}!" -ForegroundColor Cyan
