param (
    [Parameter(Mandatory)]
    [string] $jsonfile,
    [string] $schemafile = "./templates/metrics.schema.json"

)

if (!(Test-Path $schemafile)) {
    Write-Error "*** Schemafile $schemafile not found."
    exit
}

if (!(Test-Path $jsonfile)) {
    Write-Error "*** File $jsonfile not found."
    exit
} else {
    $json = Get-Content -Path $jsonfile -Raw -encoding UTF8 | convertfrom-json -noenumerate | convertto-json
}



if (!(Test-Json -Json $json -schemafile $schemafile)) {
    Write-Error "*** File $jsonfile does not contain valid JSON."
    
    $json
} else {
    Write-Host "*** Successfully validated $jsonfile against $schemafile"
}

