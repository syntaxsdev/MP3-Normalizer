#This is for testing purposes. This should return the amount of items (songs) that were successfully parsed and put into your completed folder.

$global:SongDS = @()
$DSFile = "$(Get-Location)\song_datastore.xml"

if ((Test-Path -Path $DSFile) -ne $true) {
    Write-Host "No DS file found."
    return
} else {
    $global:SongDS = Import-Clixml -Path $DSFile
    Write-Host "Loaded. There are $($SongDS.Count) items stored." }