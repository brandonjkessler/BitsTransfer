param(
    [parameter(Mandatory)]
    [string]
    $Source,
    [parameter(Mandatory)]
    [string]
    $Destination,
    [parameter(Mandatory=$false)]
    [string]
    $LogPath = "$env:WINDIR\Logs"
)



Start-Transcript -Path "$LogPath\TransferFoldersAndFiles.log"

#-- Trim any excess \ from the destination address
if($Destination.Substring($Destination.Length - 1) -eq '\'){
    $Destination = $Destination.Substring(0,($Destination.Length - 1))
}
$StartTime = Get-Date
#-- Get the folders of the source directory and then replicate the file structure

Get-ChildItem -Path $Source -Recurse | ForEach-Object {
    #-- Test if the current item is a file or folder
    #-- BITS doesn't support transferring folders, only files.

    if($Source.Substring($Source.Length - 1) -eq '\'){
        $Folder = "$(($_.FullName).SubString(($Source.Length)))"
    } else {
        ##-- If the Source parameter is autocompleted it will have a '\' at the end
        ##-- but if not then it may not have the '\' at the end.
        ##-- This code adds the correct amount of digits forward to account for the lack of '\'
        ##-- in the $Source parameter so that when we build the $folder it doesn't include
        ##-- the '\' and bork up all the things.
        $Folder = "$(($_.FullName).SubString(($Source.Length + 1)))"
    }
    
    if(((Get-Item -Path $_).GetType()) -match 'System.IO.DirectoryInfo'){
        Write-Host "$_ detected as folder, actually is $($_.GetType())"
        Write-Host "Folder will be $Folder"
        ## Check for the Folder, If it doesn't exist, then make it
        if((Test-Path -Path "$Destination\$Folder") -ne $true){
            Write-Warning "$Destination\$Folder does not exist. Creating now."
            New-Item -Path "$Destination\$Folder" -ItemType Directory -Force -Verbose
        }
    } else {
        Write-Host "$_ detected as file, actually is $($_.GetType())"
        ##-- Create a BITS transfer file for Source/Destination
        <#
        $tempObj = [PSCustomObject]@{
            Source = "$($_.FullName)"
            Destination = "$Destination\$Folder"
        } | Export-Csv -Path "$BitsCSV" -NoTypeInformation -Encoding utf8NoBOM -Append
        #>
        ###-- Running the script this way cuts the transfer time in half if there are a bunch of small files
        Start-BitsTransfer -Source "$($_.FullName)" -Destination "$Destination\$Folder" -Description "Copying $_ to $Destination\$Folder" -DisplayName "Copying $($_.Name)"
        
    }


}

Write-Host "Transfer Started at $($StartTime.Hour):$($StartTime.Minute):$($StartTime.Millisecond)"
#Import-CSV -Path "$BitsCSV" | Start-BitsTransfer -Description "Copying $_ to $Destination\$Folder" -DisplayName "Copying $($_.Name)"


$EndTime = Get-Date
Write-Host "Transfer ended at $($EndTime.Hour):$($EndTime.Minute):$($EndTime.Millisecond)"
$TotalTime = $EndTime - $StartTime
Write-Host "Total Time was $TotalTime"

Stop-Transcript