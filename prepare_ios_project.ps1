# Path to project
$projectPath = ".\ios\Runner.xcodeproj\project.pbxproj"
$infoPlistPath = ".\ios\Runner/Info.plist"

Write-Host "Preparing iOS project for AltStore..."

# 1️⃣ Remove DEVELOPMENT_TEAM from project.pbxproj
(Get-Content $projectPath) | ForEach-Object {
    $_ -replace 'DEVELOPMENT_TEAM = [^;]*;', 'DEVELOPMENT_TEAM = ;'
} | Set-Content $projectPath

Write-Host "DEVELOPMENT_TEAM cleared."

# 2️⃣ Set unique Bundle Identifier in Info.plist
$bundleID = "com.ledcontroller.app"

# Load plist as text
$plistContent = Get-Content $infoPlistPath -Raw

# Replace CFBundleIdentifier
if ($plistContent -match '<key>CFBundleIdentifier</key>\s*<string>[^<]*</string>') {
    $plistContent = $plistContent -replace '<key>CFBundleIdentifier</key>\s*<string>[^<]*</string>', "<key>CFBundleIdentifier</key>`n<string>$bundleID</string>"
    Set-Content $infoPlistPath $plistContent
    Write-Host "Bundle Identifier set to $bundleID"
} else {
    Write-Host "CFBundleIdentifier not found in Info.plist"
}

Write-Host "iOS project ready for Codemagic AltStore build!"
