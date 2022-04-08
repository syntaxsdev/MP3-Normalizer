$global:SongDS = @()
$DSFile = "$(Get-Location)\song_datastore.xml"

if ((Test-Path -Path $DSFile) -ne $true) {
    Write-Host "No DS file found."
    return
} else {
    $global:SongDS = Import-Clixml -Path $DSFile
    Write-Host "Loaded. There are $($SongDS.Count) items stored."
}
$FolderToUnbind = "E:\DJ\DJ Full Songs"

foreach($song in (Get-ChildItem -LiteralPath $FolderToUnbind)) { 
    $MediaMeta = [TagLib.File]::Create((resolve-path -LiteralPath $song.Fullname))
        
    if ($MediaMeta.Tag.Grouping -ne "") {
        $SongDS = $SongDS | Where-Object {$_.hash -ne $MediaMeta.Tag.Grouping}
    }
}


Write-Host "Done. There are $($SongDS.Count) items remaining."

#Save datastore back.
$SongDS | Export-Clixml -Path $DSFile
