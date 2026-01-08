$youtube_folder="C:\Youtube"
$video_folder="$youtube_folder\Videos"
$music_folder="$youtube_folder\Musique"
$soft_path="$youtube_folder\Software"
$ytdl_path="$soft_path\yt-dlp.exe"
$magik_path="$soft_path\magick.exe"
$ffmpeg_path="$soft_path\ffmpeg.exe"

# Les checks 
function check_folder {
    param (
        [string]$dossier
    )
	$dossier = $dossier -replace " ", "_"
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
        write-host "Telechargement dans $magik_path"
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
        write-host "Telechargement dans $ffmpeg_path"
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
Function  rename_all($Path){
	
    Write-Host "Renommage des underscores" -ForegroundColor Green
	Get-ChildItem $Path -Filter *_*
    Get-ChildItem $Path -Filter *_* | Rename-Item -NewName { $_.Name -replace '_',' ' } -ErrorAction SilentlyContinue
    Get-ChildItem $Path -Filter *_* | Remove-Item -ErrorAction SilentlyContinue

    Write-Host "Renommage des crochets" -ForegroundColor Green
	Get-ChildItem $Path -Filter *[*]*
	Get-ChildItem $Path -Filter *[*]* | Rename-Item -NewName { $_.Name -replace '\-\[.*?\]', '' } -ErrorAction SilentlyContinue
	Get-ChildItem $Path -Filter *[*]* | Remove-Item -ErrorAction SilentlyContinue

    Write-Host "Renommage des Single quotes" -ForegroundColor Green
	Get-ChildItem $Path -Filter "*'*"
	Get-ChildItem $Path -Filter "*'*" | Rename-Item -NewName { $_.Name -replace "'", "" } -ErrorAction SilentlyContinue
	Get-ChildItem $Path -Filter "*'*" | Remove-Item -ErrorAction SilentlyContinue

}

Function  convert_thumbnail($Path){
    $webpFiles = Get-ChildItem $Path -Filter *.webp

    foreach ($file in $webpFiles) {
		
		# $nospacefile = $file.FullName -replace ' ', '_'	
		$jpgfile = $file.FullName -replace 'webp', 'jpg'

	    Write-Host "Conversion de $($file.FullName) vers $jpgfile" 	-ForegroundColor Yellow	
		& $magik_path "$($file.FullName)" "$jpgfile"

		Write-Host "Effacage de $($file.FullName)" -ForegroundColor Yellow
			Remove-Item -Path $file.FullName -Force
		}
}

Function get_playlist_name($Url){

	$output_title = & $ytdl_path $Url --print "%(title)s"
	$playlist_name = $output_title.replace("'","")
	$playlist_name = $playlist_name.replace("(","")
	$playlist_name = $playlist_name.replace(")","")
	$playlist_name = $playlist_name.replace(":","")
	
	return $playlist_name
	
}

Function yt_video($Url,$Path){

	& $ytdl_path $Url --output '%(channel)s_%(title)s.%(ext)s' --write-thumbnail --paths $Path --no-playlist  

	rename_all $Path
	convert_thumbnail $Path
	
	Start-Process $Path
}

Function yt_playlist($Url,$Path){

	$playlist_name = get_playlist_name $Url
	$playlist_folder = "$Path" + "\" + "$playlist_name"
	check_folder $playlist_folder

	& $ytdl_path $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --write-thumbnail --no-overwrites --yes-playlist --paths $playlist_folder

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder

	start-process $playlist_folder

}


Function yt_zic($Url,$Path){

    Write-Host "Telechargement de la video convertie en audio" -ForegroundColor Green
	& $ytdl_path $Url --output "%(title)s.%(ext)s" --paths $Path --write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --no-playlist --embed-metadata --postprocessor-args "-metadata album='Youtube'" 

	rename_all $Path
	convert_thumbnail $Path
}

Function yt_zicplaylist($Url,$Path){

	$playlist_name = get_playlist_name $Url $Path
	$playlist_folder = "$Path" + "\" + "$playlist_name"
	check_folder $playlist_folder
	$playlist_metadata = "'"+"$playlist_name"+"'"

	& $ytdl_path --add-metadata $Url --yes-playlist --output '%(playlist_index)s - %(title)s.%(ext)s' --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --embed-metadata --postprocessor-args "-metadata album=$playlist_metadata"

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder
}

Function yt_zicfromchapters($Url,$Path){

	$video_name = & $ytdl_path $Url -s --print "%(title)s"
	$artist_name = & $ytdl_path $Url -s --print "%(channel)s"

	$video_name_metadata = "'"+$video_name.Replace("'","")+"'"
	$playlist_folder = "$Path" + "\" + "$artist_name - $video_name"
	check_folder $playlist_folder

	& $ytdl_path --add-metadata $Url --no-playlist --output "chapter:%(section_title)s.%(ext)s" --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --split-chapters --embed-metadata --postprocessor-args "-metadata album=$video_name_metadata -metadata title=''"

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
	$Url = Read-Host -Prompt 'Quel est la url?' 
	$Choice = Read-Host -Prompt '[1] video [2] video playlist [3] musique [4] playlist musique [5] chapters into music'

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