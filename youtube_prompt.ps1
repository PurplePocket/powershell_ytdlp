Import-Module ".\variables.ps1"

if (-not (Test-Path $ytdl_path)) {
    Write-Host "File not found: $filePath" -ForegroundColor Red
    Write-Host "Please visit <https://github.com/ytdl-org/youtube-dl/releases>"
} 

if ((-not (Test-Path $magik_path)) -or (-not (Test-Path $ffmpeg_path))) {
    Write-Host "File not found: $magik_path" -ForegroundColor Red
    Write-Host "File not found: $ffmpeg_path" -ForegroundColor Red
    Write-Host "Please visit <https://imagemagick.org/script/download.php>"
    Write-Host "Take the <Portable Win64 static at 16 bits-per-pixel component>"
} 

while ($true) 
{
	$Url = Read-Host -Prompt 'Quel est la url?' 
	$Choice = Read-Host -Prompt '[1] video [2] video playlist [3] musique [4] playlist musique' 

	switch ($Choice)
	{
		1 { yt_video $Url $youtube_folder }
		2 { yt_playlist $Url $youtube_folder }
		3 { yt_zic $Url $music_folder }
		4 { yt_zicplaylist $Url $music_folder }
		Default {
			"No matches"
		}
	}
}