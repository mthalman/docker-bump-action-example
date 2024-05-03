[cmdletbinding()]
param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [string]$Payload,

    [Parameter(Mandatory = $True)]
    [ValidateScript({Test-Path $_})]
    [string]$ExpectedPayloadPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

function GetUpdates($payload) {
    $output = @()
    foreach ($update in $payload.updates) {
        $fields = @()
    
        foreach ($field in $update.PSObject.Properties) {
            $fields += $field.Name + " " + $field.Value + "`n"
        }
    
        $sorted = $fields | Sort-Object | Out-String
        $output += $sorted + "`n"
    }

    return $output
}

$shaRegex = "sha256:[a-fA-F0-9]{64}"

$actualJson = $Payload | ConvertFrom-Json

if ($null -ne $actualJson) {
    foreach ($update in $actualJson.updates) {
        $update.baseImageDigest = $update.baseImageDigest -replace $shaRegex, "<BASE-SHA>"
        $update.targetImageDigest = $update.targetImageDigest -replace $shaRegex, "<TARGET-SHA>"
    }
}

$actual = $actualJson | ConvertTo-Json

$expected = Get-Content $ExpectedPayloadPath
$expectedJson = $expected | ConvertFrom-Json

if ($null -eq $actualJson -and $null -ne $expectedJson) {
    throw "Payload comparison failed.`nExpected: $expected`nActual: $actual"
}

if ($null -ne $actualJson -and $null -eq $expectedJson) {
    throw "Payload comparison failed.`nExpected: $expected`nActual: $actual"
}

if ($null -eq $actualJson -and $null -eq $expectedJson) {
    return
}

if ($actualJson.updates.Count -ne $expectedJson.updates.Count) {
    throw "Payload comparison failed.`nExpected: $expected`nActual: $actual"
}

$expectedUpdates = GetUpdates $expectedJson
$actualUpdates = GetUpdates $actualJson

if ($expectedUpdates -ne $actualUpdates) {
    throw "Payload comparison failed.`nExpected: $expected`nActual: $actual"
}
