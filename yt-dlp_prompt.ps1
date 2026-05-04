[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$youtube_folder="C:\Youtube"
$video_folder="$youtube_folder\Videos"
$music_folder="$youtube_folder\Musique"
$soft_path="$youtube_folder\Software"
$ytdl_path="$soft_path\yt-dlp.exe"
$magik_path="$soft_path\magick.exe"
$ffmpeg_path="$soft_path\ffmpeg.exe"

# Les verifications et installations
function check_folder {
    param (
        [string]$dossier
    )
	# $dossier = $dossier -replace " ", "_"
    if (-not (Test-Path -Path $dossier -ErrorAction SilentlyContinue)) {
            New-Item -Path $dossier -ItemType Directory -Force -ErrorAction Stop | Out-Null
	Write-Host "Folder created: $dossier" -ForegroundColor Yellow
}}

function check_ytdlp {

    check_folder $youtube_folder
    check_folder $video_folder
    check_folder $music_folder
    check_folder $soft_path
	if (Test-Path $ytdl_path) {
		$datefichier = (Get-Item $ytdl_path).LastWriteTime
		$agefichier = ((Get-Date) - $datefichier).Days

		if ($agefichier -ge 7) {
			Write-Host "$ytdl_path is $agefichier days old. Updating..." -ForegroundColor Yellow
			$achopper = $true
		} else {
			Write-Host "$ytdl_path OK" -ForegroundColor Green
			$achopper = $false
		}
	} else {
		Write-Host "$ytdl_path not found. Starting install..." -ForegroundColor Cyan
		$achopper = $true
	}

	if ($achopper) {
		Write-Host "Downloading latest version..." -ForegroundColor Cyan
		Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $ytdl_path -ErrorAction Stop
	}
}

function check_magic {
    if (-not (Test-Path $magik_path -ErrorAction SilentlyContinue)) {
        write-host "Downloading in $magik_path"
		Invoke-WebRequest -Uri "https://imagemagick.org/archive/binaries/ImageMagick-7.1.2-12-portable-Q8-x86.7z" -OutFile "$($magik_path)_download.7z" -ErrorAction Stop
	    check_folder "$($magik_path)_dossier"
        & tar.exe -xf "$($magik_path)_download.7z" -C "$($magik_path)_dossier"
        Remove-Item "$($magik_path)_download.7z" -Force -Recurse
		Move-item -Path "$($magik_path)_dossier\magick.exe" -Destination $magik_path
        Remove-Item "$($magik_path)_dossier" -Force -Recurse
	} else {
		Write-Host "$magik_path OK" -ForegroundColor Green
	}
}

function check_ffmpeg {
    if (-not (Test-Path $ffmpeg_path -ErrorAction SilentlyContinue)) {
        write-host "Downloading in $ffmpeg_path"
		Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile "$($ffmpeg_path)_download.zip" -ErrorAction Stop
        Expand-Archive -Path "$($ffmpeg_path)_download.zip" -DestinationPath "$($ffmpeg_path)_dossier"-Force
        Remove-Item "$($ffmpeg_path)_download.zip" -Force -Recurse
		Move-item -Path "$($ffmpeg_path)_dossier\ffmpeg-8.0.1-essentials_build\bin\ffmpeg.exe" -Destination $ffmpeg_path
        Remove-Item "$($ffmpeg_path)_dossier" -Force -Recurse
	} else {
		Write-Host "$ffmpeg_path OK" -ForegroundColor Green
	}
}

# Les actions

Function Invoke-WithSpinner {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Action
    )

    $job = Start-Job -ScriptBlock $Action
	$kaomoji = @(
		"($([char]0xFF89)$([char]0x25D5)$([char]0x30EE)$([char]0x25D5))$([char]0xFF89)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)",
		"($([char]0xFF89)$([char]0x25D5)$([char]0x30EE)$([char]0x25D5))$([char]0xFF89)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)",
		"($([char]0xFF89)$([char]0x25D5)$([char]0x30EE)$([char]0x25D5))$([char]0xFF89)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)",
		"($([char]0xFF89)$([char]0x25D5)$([char]0x30EE)$([char]0x25D5))$([char]0xFF89)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)$([char]0x002A)$([char]0x003A)$([char]0xFF65)$([char]0xFF9F)$([char]0x2727)"
	)
    $i = 0

    while ($job.State -eq 'Running') {
        Write-Host "`r$($kaomoji[$i++ % 4])" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 200
    }

    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    
    return $result
}


function cleanup_name ($dirty_name){

    $clean_name = $dirty_name -replace '_', ' '
    $clean_name = $clean_name -replace '[^\w\s\.]', ''
    $clean_name = ($clean_name -replace '\s+', ' ').Trim()
	$clean_name = $clean_name -replace '\s+(?=\.)', ''
	
	return $clean_name
}

Function  rename_all($Path){
	
    Get-ChildItem -Path $Path -File | ForEach-Object {
        $oldName = $_.Name
	
		$newName = cleanup_name $oldName

        # On renomme uniquement si le nom a changé
        if ($oldName -ne $newName) {
            Write-Host "Renaming   : $oldName -> $newName" -ForegroundColor White
            Rename-Item -Path $_.FullName -NewName $newName -ErrorAction SilentlyContinue
        }
    }
}

Function  convert_thumbnail($Path){
    $webpFiles = Get-ChildItem $Path -Filter *.webp

    foreach ($file in $webpFiles) {
		
		$jpgfile = $file.FullName -replace 'webp', 'jpg'
		$jpgfilname = $file.name -replace 'webp', 'jpg'

	    Write-Host "Converting : $($file.name) -> $jpgfilname" -ForegroundColor White	
		& $magik_path "$($file.FullName)" "$jpgfile"

		Write-Host "Deleting   : $($file.name)" -ForegroundColor White
			Remove-Item -Path $file.FullName -Force
		}
}

Function get_video_name($Url){

	$output_title = & $ytdl_path --quiet --no-warnings $Url --print '%(title)s' --playlist-items 1

	# Invoke-WithSpinner -Action {
	# 	& $using:ytdl_path --quiet --no-warnings $using:Url --print '%(title)s' --playlist-items 1
	# }

	$video_name = cleanup_name $output_title
	
	return $video_name
}

Function get_playlist_name($Url){

	$output_title = & $ytdl_path --quiet --no-warnings $Url --print "%(playlist_title)s" --playlist-items 1

	$playlist_name = cleanup_name $output_title
	
	return $playlist_name
	
}

Function yt_video($Url,$Path){

	# & $ytdl_path --quiet --no-warnings $Url --output '%(channel)s_%(title)s.%(ext)s' --write-thumbnail --paths $Path --no-playlist

	$vid_name = get_video_name $Url
	write-host "Downloading <$vid_name> as video to $Path" -ForegroundColor Yellow

	Invoke-WithSpinner -Action {
		& $ytdl_path --quiet --no-warnings $Url --output '%(title)s.%(ext)s' --write-thumbnail --paths $Path --no-playlist
	# 	& $using:ytdl_path --quiet --no-warnings --cookies-from-browser chrome $using:Url --output '%(title)s.%(ext)s' --write-thumbnail --paths $using:Path --no-playlist
	}

	write-host "`rVideo <$vid_name.webm> Downloaded, cleanup" -ForegroundColor Yellow

	rename_all $Path
	convert_thumbnail $Path
	
	Start-Process $Path
}

Function yt_playlist($Url,$Path){

	$playlist_name = get_playlist_name $Url
	write-host "Playlist name : $playlist_name" -ForegroundColor Green

	# $playlist_folder = "$Path" + "\" + "$playlist_name"
	$playlist_folder = Join-Path $Path $playlist_name

	write-host "Downloading playlist to $playlist_folder" -ForegroundColor Green
	check_folder $playlist_folder

	# write-host "Downloading Url as playlist to $playlist_folder" -ForegroundColor Yellow
	& $ytdl_path --quiet --no-warnings $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --write-thumbnail --no-overwrites --yes-playlist --paths $playlist_folder

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder

	start-process $playlist_folder

}


Function yt_zic($Url,$Path){

	$vid_name = get_video_name $Url
    Write-Host "Downloading <$vid_name> and converting it to audio" -ForegroundColor Yellow
	& $ytdl_path --quiet --no-warnings $Url --output "%(title)s.%(ext)s" --paths $Path --write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --no-playlist --embed-metadata --postprocessor-args "-metadata album='Youtube'" 

	write-host "Music <$vid_name.mp3> Downloaded, cleanup" -ForegroundColor Yellow
	rename_all $Path
	convert_thumbnail $Path
}

Function yt_zicplaylist($Url,$Path){

	$playlist_name = get_playlist_name $Url
	$playlist_folder = "$Path" + "\" + "$playlist_name"
	check_folder $playlist_folder
	$playlist_metadata = "'"+"$playlist_name"+"'"
	write-host "Playlist name : $playlist_name" -ForegroundColor Green

	write-host "Downloading playlist and converting it to audio in $playlist_folder" -ForegroundColor Green
	& $ytdl_path --quiet --no-warnings --add-metadata $Url --yes-playlist --output '%(playlist_index)s - %(title)s.%(ext)s' --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --embed-metadata --postprocessor-args "-metadata album=$playlist_metadata"

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder
}

Function yt_zicfromchapters($Url,$Path){

	$video_name = & $ytdl_path --quiet --no-warnings $Url -s --print "%(title)s"
	$artist_name = & $ytdl_path --quiet --no-warnings $Url -s --print "%(channel)s"

	$video_name_metadata = "'"+$video_name.Replace("'","")+"'"
	$playlist_folder = "$Path" + "\" + "$artist_name - $video_name"
	check_folder $playlist_folder

	write-host "Downloading chapters of <$video_name> and converting them to audio in $playlist_folder" -ForegroundColor Yellow
	& $ytdl_path --quiet --no-warnings --add-metadata $Url --no-playlist --output "chapter:%(section_title)s.%(ext)s" --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --split-chapters --embed-metadata --postprocessor-args "-metadata album=$video_name_metadata -metadata title=''"

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder
	
	start-process $playlist_folder
}

# Le scénar
check_ytdlp
check_magic
check_ffmpeg

while ($true) 
{
	write-host "Url of the youtube thing you want to download? " -ForegroundColor Cyan -NoNewLine
	$Url = Read-Host 
	write-host "<[1] video [2] video playlist [3] musique [4] playlist musique [5] chapters into music>" -ForegroundColor Cyan
	write-host "Choice: " -ForegroundColor Cyan -NoNewLine
	$Choice = Read-Host 

	switch ($Choice)
	{
		1 { yt_video $Url $video_folder }
		2 { yt_playlist $Url $video_folder }
		3 { yt_zic $Url $music_folder }
		4 { yt_zicplaylist $Url $music_folder }
		5 { yt_zicfromchapters $Url $music_folder }
		Default {
			"No matches"
		}
	}
}