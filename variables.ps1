#yt-dlp variables
$youtube_folder="D:\Youtube"
$music_folder="D:\Musique\Youtube"
$ytdl_path="D:\Synch\Soft\yt-dlp.exe"
$magik_path="D:\Synch\Soft\ImageMagick\magick.exe"
$ffmpeg_path="D:\Synch\Soft\ImageMagick\ffmpeg.exe"

Function  prepare_folder($Path){

	$Path = $Path -replace " ", "_"

	if (-not (Test-Path -Path $Path -PathType Container)) {

		New-Item -Path $Path -ItemType Directory -Force
		Write-Host "Folder created: $Path"
	}
}

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

# https://www.rickgouin.com/use-powershell-to-edit-mp3-tags/
# https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=468
Function add_mp3_metadata($Path){

	# Load the assembly that will handle the MP3 tagging.
	[Reflection.Assembly]::LoadFrom("D:\Synch\Soft\taglib.dll")
	
	$files = Get-ChildItem -Path $Path -Filter ".mp3"
	
	foreach ($filename in $files){
		
		# Load up the MP3 file.
		$media = [TagLib.File]::Create(($Path+$filename))
		# Load up the tags we know
		$albumartists = [string]$media.Tag.AlbumArtists
		$title = $media.Tag.Title
		$artists = [string]$media.Tag.Artists
		$extension = $filename.Extension
		
		# Mettre youtube en album 
			Write-Host "Ajout de l'album Youtube" -ForegroundColor Green
				$media.Tag.Album = "Youtube"
		# Mettre le premier mot du filename dans l'artiste
			Write-Host "Ajout de l'artiste $filename.Split("-")[0]" -ForegroundColor Green
				$media.Tag.Artists = $filename.Split("-")[0]
		
		# Mettre le reste dans titre 
			Write-Host "Ajout du titre $filename.Split("-")[1]" -ForegroundColor Green
				$media.Tag.Title = $filename.Split("-")[1]

		# Save the tag changes back
		$media.Save()
		
		
		
		
	}
	
}

Function  convert_thumbnail($Path){
    $webpFiles = Get-ChildItem $Path -Filter *.webp
    $metadata_folder = Join-Path -Path $Path -ChildPath "metadata"

# if metadata folder existe pas, fait de path la destination
	if (-not (Test-Path -Path $metadata_folder -PathType Container)) {
		$metadata_folder = $Path
	}

    foreach ($file in $webpFiles) {
        # $metadata_jpg_path = Join-Path -Path $metadata_folder -ChildPath $file.Name
		$metadata_jpg_path = $metadata_jpg_path -replace 'webp', 'jpg'
		
		$jpgfile = $file.Name -replace 'webp', 'jpg'
        $metadata_jpg_path = Join-Path -Path $metadata_folder -ChildPath $jpgfile

		
	Write-Host "Effacage de $metadata_jpg_path" -ForegroundColor Yellow		
        Remove-Item -Path "$metadata_jpg_path" -Force -ErrorAction SilentlyContinue

        # jellyfin creates a thumbnail with underscores!
   		$destpathwithunderscore = $metadata_jpg_path -replace ' ', '_'		
        Remove-Item -Path "$destpathwithunderscore" -Force -ErrorAction SilentlyContinue

    Write-Host "Conversion de $($file.FullName) vers $metadata_jpg_path" -ForegroundColor Green	
    #$magick_arguments = '"' + "$($file.FullName)" + '" "' + "$metadata_jpg_path" +'"'
    #Write-Host "$magik_path $magick_arguments"
    # Start-Process $magik_path -ArgumentList $magick_arguments -Wait -NoNewWindow 
	& $magik_path "$($file.FullName)" "$metadata_jpg_path"
				
	Write-Host "Effacage de $($file.FullName)" -ForegroundColor Yellow
		Remove-Item -Path $file.FullName -Force
	}
}

Function  convert_m4a_to_mp3($Path){

    $m4a_list = Get-ChildItem $Path -Filter *.m4a
	foreach ($m4a_file in $m4a_list) {
	$mp3file = $m4a_file.FullName -replace 'm4a', 'mp3'
Write-Host "Conversion de $Path\$m4a_file vers $mp3file" -ForegroundColor Green
	$ffmpeg_arguments = '-i "' + "$Path\$m4a_file" + '" -c:v copy -c:a libmp3lame -q:a 4 "' + "$mp3file" +'" -y'
	# Write-Host "$ffmpeg_path $ffmpeg_arguments"
	Start-Process $ffmpeg_path -ArgumentList $ffmpeg_arguments -Wait -NoNewWindow 
Write-Host "Effacage de $($m4a_file.FullName)" -ForegroundColor Yellow
	Remove-Item -Path "$($m4a_file.FullName)"
	}
}

Function  convert_video_to_mp3($Path){
# sert a rien mdr 
    $mp4_list = Get-ChildItem $Path -Filter *.mp4
	foreach ($mp4_file in $mp4_list) {
	$mp3file = $mp4_file.FullName -replace 'mp4', 'mp3'
Write-Host "Conversion de $Path\$mp4_file vers $mp3file" -ForegroundColor Green
	#  .\ImageMagick\ffmpeg.exe -i "Flor d'Luna (Moonflower) [lRWEDKaSLp0].webm"  "flor.mp3"
	$ffmpeg_arguments = '-i "' + "$Path\$mp4_file" + '" -vn -ar 44100 -ac 2 -b:a 320k "' + "$mp3file" +'" -y'
	# Write-Host "$ffmpeg_path $ffmpeg_arguments"
	Start-Process $ffmpeg_path -ArgumentList $ffmpeg_arguments -Wait -NoNewWindow 
Write-Host "Effacage de $($mp4_file.FullName)" -ForegroundColor Yellow
	Remove-Item -Path "$($mp4_file.FullName)"
	}

    $webm_list = Get-ChildItem $Path -Filter *.webm
	foreach ($webm_file in $webm_list) {
	$mp3file = $webm_file.FullName -replace 'webm', 'mp3'
Write-Host "Conversion de $Path\$webm_file vers $mp3file" -ForegroundColor Green
	#  .\ImageMagick\ffmpeg.exe -i "Flor d'Luna (Moonflower) [lRWEDKaSLp0].webm"  "flor.mp3"
	$ffmpeg_arguments = '-i "' + "$Path\$webm_file" + '" -vn -ar 44100 -ac 2 -b:a 320k "' + "$mp3file" +'" -y'
	# Write-Host "$ffmpeg_path $ffmpeg_arguments"
	Start-Process $ffmpeg_path -ArgumentList $ffmpeg_arguments -Wait -NoNewWindow 
Write-Host "Effacage de $($webm_file.FullName)" -ForegroundColor Yellow
	Remove-Item -Path "$($webm_file.FullName)"
	}
}

Function get_playlist_name($Url,$ParentFolder){

	# todo: essayer simplement avec 
	# $test = & .\yt-dlp.exe https://youtu.be/JF8HmRFrpzI --print "%(title)s"
	# $test.Replace("'","")
	# $test = "'"+$test+"'"

	# Simulate to get playlist name  
	$output = & $ytdl_path $Url --playlist-start 1 --playlist-end 1 -s

	#Write-Host $output
	$output_grep = $output | Select-String -Pattern "[download] Downloading playlist: " -SimpleMatch 
	$output_grep = $output_grep.ToString()
	Write-Host $output_grep
	$playlist_name = Read-Host -Prompt 'Enter playlist name (Above value as default)' 
	
	if ($playlist_name){
		Write-Host "Given playlist name: $playlist_name" -ForegroundColor Green
	}
	else {
		Write-Host "Default Choice"
		$playlist_name = $output_grep.replace('[download] Downloading playlist: ','')
		# Write-Host $playlist_name
		$playlist_name = $playlist_name.replace("'","")
		$playlist_name = $playlist_name.replace("(","")
		$playlist_name = $playlist_name.replace(")","")
		$playlist_name = $playlist_name.replace(":","")
		# $playlist_name = $playlist_name.replace(" ","_")
		Write-Host "Defined playlist name: $playlist_name" -ForegroundColor Green
	}
	
	return $playlist_name
	
}

# https://github.com/yt-dlp/yt-dlp#output-template

Function yt_zic($Url,$Path){

	prepare_folder $Path

	# # https://www.reddit.com/r/youtubedl/comments/snttr8/ytdlp_cannot_download_mp3/
    # Write-Host "Telechargement de la video en m4a" -ForegroundColor Green
	# Start-Process $ytdl_path -ArgumentList "-f 140 $Url --output %(channel)s_%(title)s.%(ext)s --paths $Path --write-thumbnail" -Wait -NoNewWindow
    # rename_all $Path
	# convert_m4a_to_mp3 $Path

    # Write-Host "Telechargement de la video en meilleure qualite possible" -ForegroundColor Green
	# Start-Process $ytdl_path -ArgumentList "$Url --output %(channel)s_%(title)s.%(ext)s --paths $Path --write-thumbnail" -Wait -NoNewWindow
    # rename_all $Path
	# convert_video_to_mp3 $Path

    Write-Host "Telechargement de la video convertie en audio" -ForegroundColor Green
	#Start-Process $ytdl_path -ArgumentList "$Url --output %(channel)s_%(title)s.%(ext)s --paths $Path --write-thumbnail -x --audio-format mp3 --audio-quality 320 --no-playlist" -Wait -NoNewWindow
	& $ytdl_path $Url --output "%(title)s.%(ext)s" --paths $Path --write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --no-playlist --embed-metadata --postprocessor-args "-metadata album='Youtube'" 
	# --embed-metadata 
	# crée tite, interpretes de l'album
	# --postprocessor-args "-metadata album='Youtube'"
	# crée album
    rename_all $Path

	convert_thumbnail $Path
}

Function yt_video($Url,$Path){

	prepare_folder $Path

	# Start-Process $ytdl_path -ArgumentList "$Url --output %(channel)s_%(title)s.%(ext)s --write-thumbnail --paths $Path --write-subs --restrict-filenames --no-playlist" -Wait -NoNewWindow
	& $ytdl_path $Url --output '%(channel)s_%(title)s.%(ext)s' --write-thumbnail --paths $Path --write-subs  --no-playlist  

	rename_all $Path
	convert_thumbnail $Path
	
	start $Path
}

Function yt_playlist($Url,$Path){

	$playlist_name = get_playlist_name $Url $Path
	$playlist_metadata = "'"+"$playlist_name"+"'"
	# $playlist_folder = "'"+"$Path" + "\" + "$playlist_name" + "'"
	$playlist_folder = "$Path" + "\" + "$playlist_name"

		if (-not (Test-Path -Path $playlist_folder -PathType Container)) {

		New-Item -Path $playlist_folder -ItemType Directory -Force
		Write-Host "Folder created: $playlist_folder" -ForegroundColor Green
	}	
		
	Write-Host "DEBUG Playlist name: $playlist_name" -ForegroundColor Green
	Write-Host "DEBUG Playlist folder: $playlist_folder" -ForegroundColor Green
	$playlist_name = Read-Host -Prompt 'debug ok?'

	# Start-Process $ytdl_path -ArgumentList "$Url --write-thumbnail --playlist-end 4 --paths $playlist_folder --verbose --write-subs --restrict-filenames --yes-playlist" -Wait -NoNewWindow
	# & $ytdl_path $Url --write-thumbnail --paths $playlist_folder --verbose --write-subs --restrict-filenames --yes-playlist
	#& $ytdl_path $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --write-thumbnail --no-overwrites --yes-playlist --paths $playlist_folder
	& $ytdl_path $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --write-thumbnail --no-overwrites --yes-playlist --paths $playlist_folder


# $myVariable = "World"
# Write-Host "Hello $('This is a single-quoted string with a variable: $myVariable')"

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder

	start $playlist_folder

}

Function yt_zicplaylist($Url,$Path){

	$playlist_name = get_playlist_name $Url $Path
	$playlist_metadata = "'"+"$playlist_name"+"'"
	# $playlist_folder = "'"+"$Path" + "\" + "$playlist_name" + "'"
	$playlist_folder = "$Path" + "\" + "$playlist_name"

		if (-not (Test-Path -Path $playlist_folder -PathType Container)) {

		New-Item -Path $playlist_folder -ItemType Directory -Force
		Write-Host "Folder created: $playlist_folder" -ForegroundColor Green
	}	
		
	Write-Host "DEBUG Playlist name: $playlist_name" -ForegroundColor Green
	Write-Host "DEBUG Playlist folder: $playlist_folder" -ForegroundColor Green
	$playlist_name = Read-Host -Prompt 'debug ok?' 
	
	# https://askubuntu.com/a/1074699
	# Start-Process $ytdl_path -ArgumentList "$Url --write-thumbnail --paths $playlist_folder --restrict-filenames --yes-playlist -x --audio-format mp3 --audio-quality 320" -Wait -NoNewWindow
	# & $ytdl_path $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --write-thumbnail  --yes-playlist -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder
	& $ytdl_path --add-metadata $Url --yes-playlist --output '%(playlist_index)s - %(title)s.%(ext)s' --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --embed-metadata --postprocessor-args "-metadata album=$playlist_metadata"
	# # l'écriture de thumbnail perturbe les metadata? wtf
	# # chopper les vidéos sans les thumbnails
	# & $ytdl_path --add-metadata $Url --output '%(playlist_index)s - %(title)s.%(ext)s' --no-write-thumbnail --yes-playlist --paths $playlist_folder 
	# # chopper les thumbnail sans les vidéos
	# & $ytdl_path $Url --skip-download --no-overwrites --yes-playlist --paths $playlist_folder --write-all-thumbnails

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder
}

Function yt_zicfromchapters($Url,$Path){

	$video_name = & $ytdl_path $Url -s --print "%(title)s"
	$artist_name = & $ytdl_path $Url -s --print "%(channel)s"

	$video_name_metadata = "'"+$video_name.Replace("'","")+"'"
	$playlist_folder = "$Path" + "\" + "$artist_name - $video_name"

	if (-not (Test-Path -Path $playlist_folder -PathType Container)) {

	New-Item -Path $playlist_folder -ItemType Directory -Force
	Write-Host "Folder created: $playlist_folder" -ForegroundColor Green
	}	
		
	Write-Host "DEBUG Album name: $video_name" -ForegroundColor Green
	Write-Host "DEBUG Album name metadata: $video_name_metadata" -ForegroundColor Green
	# $playlist_name = Read-Host -Prompt 'debug ok?' 
	
	& $ytdl_path --add-metadata $Url --no-playlist --output "chapter:%(section_title)s.%(ext)s" --no-write-thumbnail --ffmpeg-location "$ffmpeg_path" -x --audio-format mp3 --audio-quality 320 --paths $playlist_folder --split-chapters --embed-metadata --postprocessor-args "-metadata album=$video_name_metadata -metadata title=''"

	rename_all $playlist_folder
	convert_thumbnail $playlist_folder
	
	start $playlist_folder
}