@ECHO OFF & CLS
SET DEBUG=False
SET VERSION=2020.11.13
SET USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36
TITLE YouTube-DL Suite [%VERSION%]

FOR /F %%a IN ('PowerShell -Command "Get-Date -format HHmmssffff"') DO SET TIMENOW=%%a
IF %DEBUG%==True SET VERBOSE=--verbose
IF "%~1"=="" (
	PowerShell -Command "Get-Clipboard" > "%TEMP%\%TIMENOW%_Link.txt"
	SET LINK="%TEMP%\%TIMENOW%_Link.txt"
) ELSE (
	IF EXIST "%~1" (
		IF "%~x1"==".txt" (
			SET LINK="%~1"
		) ELSE (
			CLS & ECHO ################################# & ECHO. & ECHO ONLY TEXT FILE ^(.txt^) ARE ALLOWED & ECHO. & ECHO ################################# & ECHO. & PAUSE
			GOTO :END
		)
	) ELSE (
		CLS & ECHO ############## & ECHO. & ECHO FILE NOT FOUND & ECHO. & ECHO ############## & ECHO. & PAUSE
		GOTO :END
	)
)
TASKLIST /FI "IMAGENAME EQ youtube-dl.exe" 2>NUL | FIND /I /N "youtube-dl.exe">NUL
IF NOT %ERRORLEVEL%==0 CALL :DAILY_CHECK_UPDATE

:MODE
CLS
ECHO [0] Download Video
ECHO [1] Download Video ^(Archival^)
ECHO [2] Download Audio Only
ECHO [3] Download Audio Only ^(Archival^)
ECHO [4] Download Live Streaming
ECHO [5] Watch Live Streaming
ECHO [6] Get Subtitle
ECHO [7] Get Thumbnail
ECHO [8] Listing Supported Websites
ECHO.
CHOICE /C 012345678 /N /M "Choose Mode:"
IF %ERRORLEVEL%==1 SET MODE=VIDEO
IF %ERRORLEVEL%==2 SET MODE=VIDEO_ARCHIVAL
IF %ERRORLEVEL%==3 SET MODE=AUDIO
IF %ERRORLEVEL%==4 SET MODE=AUDIO_ARCHIVAL
IF %ERRORLEVEL%==5 SET MODE=DOWNLOAD_LIVE
IF %ERRORLEVEL%==6 SET MODE=LIVE
IF %ERRORLEVEL%==7 SET MODE=SUBTITLE
IF %ERRORLEVEL%==8 SET MODE=THUMBNAIL
IF %ERRORLEVEL%==9 CALL :LIST

IF %MODE%==VIDEO (
	CALL :VIDEO_SELECTION
	CALL :PLAYLIST
)
IF %MODE%==VIDEO_ARCHIVAL (
	SET ARCHIVAL=True
	SET DATABASE=--write-annotations --download-archive "%~d0%~p0YouTube-DL Suite (Archive).txt"
	CALL :VIDEO_SELECTION
	CALL :PLAYLIST
)
IF %MODE%==AUDIO (
	CALL :AUDIO_SELECTION
	CALL :PLAYLIST
)
IF %MODE%==AUDIO_ARCHIVAL (
	SET ARCHIVAL=True
	SET DATABASE=--write-annotations --download-archive "%~d0%~p0YouTube-DL Suite (Archive).txt"
	CALL :AUDIO_SELECTION
	CALL :PLAYLIST
)
IF %MODE%==DOWNLOAD_LIVE (
	CALL :DOWNLOAD_LIVE_SELECTION
)
IF %MODE%==LIVE (
	CALL :LIVE_SELECTION
)
IF %MODE%==SUBTITLE (
	CALL :SUBTITLE
) ELSE (
	IF %MODE%==THUMBNAIL (
		SET THUMBNAIL=--skip-download --write-thumbnail
		SET SAVEPATH="%~d0%~p0%%(title)s.%%(ext)s"
	) ELSE (
		SET SUBTITLE=--all-subs --embed-subs --sub-format best --convert-subs srt
	)
)

:AUTH
CLS
ECHO Authorization is necessary when the link is not publicly available or age restriction.
ECHO.
CHOICE /C yn /M "Authorization Requirements"
IF %ERRORLEVEL%==1 CALL :AUTH_MODE

IF %MODE%==VIDEO CALL :VIDEO
IF %MODE%==VIDEO_ARCHIVAL CALL :VIDEO
IF %MODE%==AUDIO CALL :AUDIO
IF %MODE%==AUDIO_ARCHIVAL CALL :AUDIO
IF %MODE%==DOWNLOAD_LIVE CALL :DOWNLOAD_LIVE
IF %MODE%==LIVE CALL :LIVE
IF %MODE%==SUBTITLE CALL :VIDEO
IF %MODE%==THUMBNAIL CALL :VIDEO

GOTO :END

:VIDEO
CLS & "%~d0%~p0tools\youtube-dl.exe" %VERBOSE% %COOKIES_CMD% %LOGIN_CMD% %REFERER% %DELAY% --user-agent "%USER_AGENT%" --no-check-certificate --geo-bypass --ignore-errors --ignore-config --no-warnings --fragment-retries infinite --console-title --yes-playlist %PLAYLIST_REVERSE% --prefer-ffmpeg --ffmpeg-location "%~d0%~p0tools\ffmpeg.exe" %DATABASE% --add-metadata %SUBTITLE% %THUMBNAIL% %VIDEO_FORMAT% --batch-file %LINK% --output %SAVEPATH%	
EXIT /B

:AUDIO
CLS & "%~d0%~p0tools\youtube-dl.exe" %VERBOSE% %COOKIES_CMD% %LOGIN_CMD% %REFERER% %DELAY% --user-agent "%USER_AGENT%" --no-check-certificate --geo-bypass --ignore-errors --ignore-config --no-warnings --fragment-retries infinite --console-title --yes-playlist %PLAYLIST_REVERSE% --prefer-ffmpeg --ffmpeg-location "%~d0%~p0tools\ffmpeg.exe" %DATABASE% --add-metadata --extract-audio --audio-quality 0 --audio-format %AUDIO_FORMAT% -f "bestaudio[ext=webm]/bestaudio[ext=m4a]/bestaudio/best" --batch-file %LINK% --output %SAVEPATH%
EXIT /B

:DOWNLOAD_LIVE
CLS & TITLE youtube-dl - Live Stream Downloading ^(Please wait until the console closes automatically^) & "%~d0%~p0tools\youtube-dl.exe" %VERBOSE% %COOKIES_CMD% %LOGIN_CMD% %REFERER% --user-agent "%USER_AGENT%" --no-check-certificate --geo-bypass --ignore-errors --ignore-config --no-warnings --keep-video --no-part --no-post-overwrites --prefer-ffmpeg --ffmpeg-location "%~d0%~p0tools\ffmpeg.exe" %DOWNLOAD_LIVE_FORMAT% --batch-file %LINK% --output "%~d0%~p0%%(title)s.%%(ext)s"
EXIT /B

:LIVE
CLS & "%~d0%~p0tools\youtube-dl.exe" %COOKIES_CMD% %LOGIN_CMD% %REFERER% --user-agent "%USER_AGENT%" --no-check-certificate --geo-bypass --ignore-errors --ignore-config --no-warnings --no-playlist --simulate --get-filename --restrict-filenames --batch-file %LINK% --output "%%(uploader)s %%(title)s">"%TEMP%\%TIMENOW%_Title.txt"
SET /P TITLE=<"%TEMP%\%TIMENOW%_Title.txt"
START "%TITLE%" /HIGH CMD /Q /C ""%~d0%~p0tools\youtube-dl.exe" %VERBOSE% %COOKIES_CMD% %LOGIN_CMD% %REFERER% --user-agent "%USER_AGENT%" --no-check-certificate --geo-bypass --ignore-errors --ignore-config --no-warnings --skip-unavailable-fragments --no-playlist --prefer-ffmpeg --ffmpeg-location "%~d0%~p0tools\ffmpeg.exe" %LIVE_FORMAT% --output - --batch-file %LINK% | "%~d0%~p0tools\mpv\mpv.exe" - --title="%TITLE%" --cache-dir="%TEMP%" --no-border --ontop"
EXIT /B

:PLAYLIST
CLS
ECHO [0] Normal & ECHO. ^> Clip A.mkv & ECHO. ^> Clip B.mkv & ECHO.
ECHO [1] Music Playlist & ECHO. ^> Album Name\#01 - Track A.mp3 & ECHO. ^> Album Name\#02 - Track B.mp3 & ECHO.
ECHO [2] Series Playlist & ECHO. ^> Series Name\(01) Title A.mp4 & ECHO. ^> Series Name\(02) Title B.mp4 & ECHO.
ECHO [3] Channel Playlist & ECHO. ^> Channel Name\[20200712] Clip A (P8OjkcLzYCM).mkv & ECHO. ^> Channel Name\[20200730] Clip B (MvlgyKTSSEA).mkv & ECHO.
CHOICE /C 0123 /N /M "Choose Playlist Extraction Format:"
IF %ERRORLEVEL%==1 (
	SET PLAYLIST_REVERSE=--playlist-reverse
	IF "%ARCHIVAL%"=="True" (
		SET SAVEPATH="%~d0%~p0Archive\%%(uploader)s\%%(title)s.%%(ext)s"
	) ELSE (
		SET SAVEPATH="%~d0%~p0%%(title)s.%%(ext)s"
	)
)
IF %ERRORLEVEL%==2 (
	IF "%ARCHIVAL%"=="True" (
		SET SAVEPATH="%~d0%~p0Archive\%%(uploader)s\%%(playlist)s\#%%(playlist_index)s - %%(title)s.%%(ext)s"
	) ELSE (
		SET SAVEPATH="%~d0%~p0%%(playlist)s\#%%(playlist_index)s - %%(title)s.%%(ext)s"
	)
)
IF %ERRORLEVEL%==3 (
	IF "%ARCHIVAL%"=="True" (
		SET SAVEPATH="%~d0%~p0Archive\%%(uploader)s\%%(playlist)s\(%%(playlist_index)s) %%(title)s.%%(ext)s"
	) ELSE (
		SET SAVEPATH="%~d0%~p0%%(playlist)s\(%%(playlist_index)s) %%(title)s.%%(ext)s"
	)
)
IF %ERRORLEVEL%==4 (
	SET PLAYLIST_REVERSE=--playlist-reverse
	IF "%ARCHIVAL%"=="True" (
		SET SAVEPATH="%~d0%~p0Archive\%%(uploader)s\[%%(upload_date)s] %%(title)s (%%(id)s).%%(ext)s"
	) ELSE (
		SET SAVEPATH="%~d0%~p0%%(uploader)s\[%%(upload_date)s] %%(title)s (%%(id)s).%%(ext)s"
	)
)
EXIT /B

:AUTH_MODE
CLS
ECHO [0] Cookies (Recommended)
ECHO [1] Login
ECHO.
CHOICE /C 01 /N /M "Choose Authorization Mode:"
IF %ERRORLEVEL%==1 CALL :COOKIES_FORM
IF %ERRORLEVEL%==2 CALL :LOGIN_FORM
CLS & SET /P REFERER=Referer URL e.g. https://www.youtube.com (leave empty to skip): 
IF DEFINED REFERER SET REFERER=--referer %REFERER%
IF NOT %MODE%==DOWNLOAD_LIVE (
	IF NOT %MODE%==LIVE (
		CALL :DELAY
	)
)
EXIT /B

:DELAY
CLS & ECHO Delay 60s to 180s between each download for a playlist & ECHO.to prevent connection blockage or account inhabitation. & ECHO.Note: YouTube are not required & ECHO.
CHOICE /C yn /M "Delay"
IF %ERRORLEVEL%==1 SET DELAY=--min-sleep-interval 60 --max-sleep-interval 180
EXIT /B

:COOKIES_FORM
CLS & ECHO Install this extension to get cookies.txt of your account: & ECHO. & ECHO https://chrome.google.com/webstore/detail/get-cookiestxt/bgaddhkoddajcdgocldbbfleckgcbcid & ECHO.
SET /P COOKIES_PATH=Drag and Drop cookies.txt Here to Get Path: 
CALL :COOKIES_CHECK %COOKIES_PATH%
SET COOKIES_CMD=--cookies %COOKIES_PATH%
EXIT /B

:COOKIES_CHECK
IF NOT DEFINED COOKIES_PATH CLS & ECHO ################ & ECHO. & ECHO INPUT WAS EMPTY! & ECHO. & ECHO ################ & ECHO. & PAUSE & GOTO :AUTH
IF NOT "%~x1"==".txt" CLS & ECHO ################################# & ECHO. & ECHO ONLY TEXT FILE ^(.txt^) ARE ALLOWED & ECHO. & ECHO ################################# & ECHO. & PAUSE & GOTO :AUTH
IF NOT EXIST %COOKIES_PATH% CLS & ECHO ####################### & ECHO. & ECHO COOKIES FILE NOT FOUND! & ECHO. & ECHO ####################### & ECHO. & PAUSE & GOTO :AUTH
EXIT /B

:LOGIN_FORM
CLS & SET /P USER=Username: 
CLS & SET /P PASS=Password: 
CLS & SET /P TWOFACTOR=Two-factor Authentication Code (leave empty to skip): 
IF DEFINED TWOFACTOR SET TWOFACTOR=--twofactor %TWOFACTOR%
SET LOGIN_CMD=--username "%USER%" --password "%PASS%" %TWOFACTOR%
EXIT /B

:VIDEO_SELECTION
CLS
ECHO [0] Quality (Best Available)
ECHO [1] Quality (4K)
ECHO [2] Quality (1440p)
ECHO [3] Quality (1080p)
ECHO [4] Quality (720p)
ECHO [5] Compatibility (Best Available)
ECHO [6] Compatibility (4K)
ECHO [7] Compatibility (1440p)
ECHO [8] Compatibility (1080p)
ECHO [9] Compatibility (720p)
ECHO.
CHOICE /C 0123456789 /N /M "Choose Video Mode:"
IF %ERRORLEVEL%==1 SET VIDEO_FORMAT=--merge-output-format mkv -f "bestvideo[ext=webm]+bestaudio[ext=webm]/bestvideo+bestaudio/best"
IF %ERRORLEVEL%==2 SET VIDEO_FORMAT=--merge-output-format mkv -f "bestvideo[ext=webm,height<=?2160]+bestaudio[ext=webm]/bestvideo[height<=?2160]+bestaudio/best[height<=?2160]"
IF %ERRORLEVEL%==3 SET VIDEO_FORMAT=--merge-output-format mkv -f "bestvideo[ext=webm,height<=?1440]+bestaudio[ext=webm]/bestvideo[height<=?1440]+bestaudio/best[height<=?1440]"
IF %ERRORLEVEL%==4 SET VIDEO_FORMAT=--merge-output-format mkv -f "bestvideo[ext=webm,height<=?1080]+bestaudio[ext=webm]/bestvideo[height<=?1080]+bestaudio/best[height<=?1080]"
IF %ERRORLEVEL%==5 SET VIDEO_FORMAT=--merge-output-format mkv -f "bestvideo[ext=webm,height<=?720]+bestaudio[ext=webm]/bestvideo[height<=?720]+bestaudio/best[height<=?720]"
IF %ERRORLEVEL%==6 SET VIDEO_FORMAT=--merge-output-format mp4 -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"
IF %ERRORLEVEL%==7 SET VIDEO_FORMAT=--merge-output-format mp4 -f "bestvideo[ext=mp4,height<=?2160]+bestaudio[ext=m4a]/bestvideo[height<=?2160]+bestaudio/best[height<=?2160]"
IF %ERRORLEVEL%==8 SET VIDEO_FORMAT=--merge-output-format mp4 -f "bestvideo[ext=mp4,height<=?1440]+bestaudio[ext=m4a]/bestvideo[height<=?1440]+bestaudio/best[height<=?1440]"
IF %ERRORLEVEL%==9 SET VIDEO_FORMAT=--merge-output-format mp4 -f "bestvideo[ext=mp4,height<=?1080]+bestaudio[ext=m4a]/bestvideo[height<=?1080]+bestaudio/best[height<=?1080]"
IF %ERRORLEVEL%==10 SET VIDEO_FORMAT=--merge-output-format mp4 -f "bestvideo[ext=mp4,height<=?720]+bestaudio[ext=m4a]/bestvideo[height<=?720]+bestaudio/best[height<=?720]"
CLS & CHOICE /C yn /M "Download Thumbnail"
IF %ERRORLEVEL%==1 SET THUMBNAIL=--write-thumbnail
EXIT /B

:AUDIO_SELECTION
CLS
ECHO [0] Best Available
ECHO [1] AAC
ECHO [2] FLAC
ECHO [3] MP3
ECHO [4] M4A
ECHO [5] OPUS
ECHO [6] VORBIS
ECHO [7] WAV
ECHO.
CHOICE /C 01234567 /N /M "Choose Audio Format:"
IF %ERRORLEVEL%==1 SET AUDIO_FORMAT=best
IF %ERRORLEVEL%==2 SET AUDIO_FORMAT=aac
IF %ERRORLEVEL%==3 SET AUDIO_FORMAT=flac
IF %ERRORLEVEL%==4 SET AUDIO_FORMAT=mp3
IF %ERRORLEVEL%==5 SET AUDIO_FORMAT=m4a
IF %ERRORLEVEL%==6 SET AUDIO_FORMAT=opus
IF %ERRORLEVEL%==7 SET AUDIO_FORMAT=vorbis
IF %ERRORLEVEL%==8 SET AUDIO_FORMAT=wav
EXIT /B

:DOWNLOAD_LIVE_SELECTION
CLS
ECHO [0] Best Available
ECHO [1] 4K
ECHO [2] 1440p
ECHO [3] 1080p
ECHO [4] 720p
ECHO.
CHOICE /C 01234 /N /M "Choose Live Download Mode:"
IF %ERRORLEVEL%==1 SET DOWNLOAD_LIVE_FORMAT=-f "bestvideo+bestaudio/best"
IF %ERRORLEVEL%==2 SET DOWNLOAD_LIVE_FORMAT=-f "bestvideo[height<=?2160]+bestaudio/best[height<=?2160]"
IF %ERRORLEVEL%==3 SET DOWNLOAD_LIVE_FORMAT=-f "bestvideo[height<=?1440]+bestaudio/best[height<=?1440]"
IF %ERRORLEVEL%==4 SET DOWNLOAD_LIVE_FORMAT=-f "bestvideo[height<=?1080]+bestaudio/best[height<=?1080]"
IF %ERRORLEVEL%==5 SET DOWNLOAD_LIVE_FORMAT=-f "bestvideo[height<=?720]+bestaudio/best[height<=?720]"
EXIT /B

:LIVE_SELECTION
CLS
ECHO [0] Best Available
ECHO [1] 4K
ECHO [2] 1440p
ECHO [3] 1080p
ECHO [4] 720p
ECHO.
CHOICE /C 01234 /N /M "Choose Live Mode:"
IF %ERRORLEVEL%==1 SET LIVE_FORMAT=-f "bestvideo+bestaudio/best"
IF %ERRORLEVEL%==2 SET LIVE_FORMAT=-f "bestvideo[height^<=?2160]+bestaudio/best[height^<=?2160]"
IF %ERRORLEVEL%==3 SET LIVE_FORMAT=-f "bestvideo[height^<=?1440]+bestaudio/best[height^<=?1440]"
IF %ERRORLEVEL%==4 SET LIVE_FORMAT=-f "bestvideo[height^<=?1080]+bestaudio/best[height^<=?1080]"
IF %ERRORLEVEL%==5 SET LIVE_FORMAT=-f "bestvideo[height^<=?720]+bestaudio/best[height^<=?720]"
EXIT /B

:SUBTITLE
CLS
ECHO Choose the language of the subtitle by letters code, for example:
ECHO.
ECHO  English            ^> en
ECHO  Thai               ^> th
ECHO  Japanese           ^> ja
ECHO  Taiwanese Mandarin ^> zh-TW
ECHO.
SET /P SUBTITLE_LANGUAGE=Language Code (leave empty to download all subtitle available): 
IF DEFINED SUBTITLE_LANGUAGE (
	SET SUBTITLE_LANGUAGE=--sub-lang %SUBTITLE_LANGUAGE%
) ELSE (
	SET SUBTITLE_LANGUAGE=--all-subs
)
CLS & CHOICE /C yn /M "Download YouTube's Automatically Generated Subtitle"
IF %ERRORLEVEL%==1 SET SUBTITLE_AUTO=--write-auto-sub
SET SUBTITLE=--skip-download --write-sub --sub-format best %SUBTITLE_AUTO% %SUBTITLE_LANGUAGE%
SET SAVEPATH="%~d0%~p0%%(title)s.%%(ext)s"
EXIT /B

:LIST
"%~d0%~p0tools\youtube-dl.exe" --extractor-descriptions>"%TEMP%\YouTube-DL Supported Websites"
START "YouTube-DL Supported Websites" /B Notepad "%TEMP%\YouTube-DL Supported Websites"
GOTO :MODE

:DAILY_CHECK_UPDATE
FOR /F %%a IN ('PowerShell -Command "Get-Date -format dd"') DO SET TODAY_NOW=%%a
SET /P TODAY_SAVE=<"%~d0%~p0tools\check"
IF NOT "%TODAY_NOW%"=="%TODAY_SAVE%" CALL :CHECK_UPDATE
EXIT /B

:CHECK_UPDATE
ECHO Checking for YouTube-DL Suite updates . . .
"%~d0%~p0tools\wget.exe" --quiet --no-verbose --no-check-certificate --no-hsts --no-cookies "https://github.com/MinorMole/YouTube-DL-Suite/releases/latest/download/version" -O "%~d0%~p0tools\version"
SET /P VERSION_CHECK=<"%~d0%~p0tools\version"
IF "%VERSION%"=="%VERSION_CHECK%" (
	ECHO %TODAY_NOW%>"%~d0%~p0tools\check"
) ELSE (
	CLS & ECHO YouTube-DL Suite %VERSION_CHECK% is Released! & ECHO. & ECHO Press any key to download . . . & ECHO. & PAUSE>NUL
	START https://github.com/MinorMole/YouTube-DL-Suite/releases/latest/download/YouTube-DL.Suite.zip
	START https://github.com/MinorMole/YouTube-DL-Suite/releases/latest
	GOTO :END
)
CLS & ECHO Checking for youtube-dl updates . . . & ECHO.
"%~d0%~p0tools\youtube-dl.exe" --update --no-check-certificate
IF EXIST "%~d0%~p0tools\youtube-dl-updater.bat" TIMEOUT /T 6 /NOBREAK>NUL
EXIT /B

:END
IF %DEBUG%==True PAUSE
EXIT