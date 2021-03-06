[Reflection.Assembly]::LoadFrom( (Resolve-Path "taglib.dll"))

#Setup these folders
$StagingFolder = "E:\DJ\DJ Full Songs"
$DuplicateFolder = "E:\DJ\NewDupes"
$CompleteFolder = "E:\DJ\Parsed"

$global:SongDS = @()
$DSFile = "$(Get-Location)\song_datastore.xml"

##>>>>>>>>>>>>>>>>>>>>>>>>>>>PRE-CHECK AND ADJUSTMENTS<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#Example.... Remove illegal characters from the name of songs such as '_'

foreach($song in (Get-ChildItem -LiteralPath $StagingFolder)) { 
    #$song | Rename-Item -NewName ($song.Name -replace "_", "") --COMMENTED OUT FOR EXAMPLE PURPOSES
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>END OF PRE-CHECK<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#Load the datastore, if one.
if ((Test-Path -Path $DSFile) -ne $true) {
    Write-Host "No DS file found."
} else {
    $global:SongDS = Import-Clixml -Path $DSFile
}


foreach($song in Get-ChildItem -LiteralPath $StagingFolder) {
    $song.Fullname
    $MediaMeta = [TagLib.File]::Create((resolve-path -LiteralPath $song.Fullname))
    
    #(1) --- Song hashing algorithm.... "Song title:Artist"
    $SongPreHash = $MediaMeta.Tag.Title + ":" + $MediaMeta.Tag.Artists
    #Hack to create a memory stream to load the string as a file
    $MemStream = [IO.MemoryStream]::new([byte[]][char[]]$SongPreHash)
    $SongHash = Get-FileHash -InputStream $MemStream -Algorithm SHA256

    #Check for duplicate song based off hash
    if ($null -eq ($SongDS | Where-Object {$_.hash -eq $songHash.Hash})) {
        #Song is not a duplicate based off algo (1)

        #Create the meta for the song
        $SongDS += @{title=$MediaMeta.Tag.Title
                    hash=$SongHash.Hash}

    } else {
        #Song is duplicate. Move to duplicate folder.
        Move-Item -LiteralPath $song.Fullname -Destination $DuplicateFolder
        continue
    }
    
    #Set and save hash to the metadata "Grouping" tag
    $MediaMeta.Tag.Grouping = $SongHash.Hash
    $MediaMeta.Save()

    #Title with no illegal characters.
    $FilteredTitle = $MediaMeta.Tag.Title
    $FilteredTitle = $FilteredTitle.replace("`"", "").replace("*", "_").replace("/", "_").replace(":", " ").replace("?", "")
    $newName = ($FilteredTitle + $song.Extension)

    #Check if exact song title exists in completed folder
    if ((Test-Path -LiteralPath "$CompleteFolder\$newName") -eq $true) {
        Write-Host "{{File exists for [$newName] Checking if song is a duplicate."
        $SongInQuestion = [TagLib.File]::Create((resolve-path -LiteralPath "$CompleteFolder\$newName"))
        if ($SongInQuestion.Tag.Artists -eq $MediaMeta.Tag.Artists) {
            Write-Host "Song is duplicate. Moving it to duplicate folder.}}"
            Move-Item -LiteralPath $song.Fullname -Destination $DuplicateFolder
            continue
        } else {
            $newName = ($FilteredTitle + " ($($MediaMeta.Tag.Artists))" + $song.Extension)
        }
    }

    #Transfer item to the complete folder and rename file to metadata title.
    Move-Item -LiteralPath $song.Fullname -Destination "$CompleteFolder\$newName"

}

#Save datastore.
$SongDS | Export-Clixml -Path $DSFile

