# PowerShell Whisper Batch Subtitle Generator
# Detects language, switches models, and translates to English if needed.
# Saves SRT files as [episode name].[Language_Code].srt (e.g., episode.en.srt)

# USER: PLEASE CONFIGURE THIS
# -------------------------------------------------------------------------------------
$whisperCallMethod = "direct" # "direct" or "python_module"
$whisperPythonExecutable = "python" # or python3, py, etc. if method is "python_module"
$whisperDirectCommand = "whisper"   # command if method is "direct" (e.g. whisper.exe or an alias)

# Example: If you use "python -m whisper", set:
# $whisperCallMethod = "python_module"
# $whisperPythonExecutable = "python3" # or whatever your python command is
# --- Adjust the above based on your Whisper installation ---

# Supported video formats
$videoExtensions = @("*.mkv", "*.mp4", "*.avi", "*.mov", "*.webm", "*.flv")

# Script's current directory
$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptFolder) { # If running selection in ISE/VSCode, $MyInvocation might be different
    $scriptFolder = Get-Location
    Write-Warning "Could not determine script folder via \$MyInvocation.MyCommand.Path, using current location: $scriptFolder"
}

# Ensure $env:TEMP directory exists
if (-not (Test-Path $env:TEMP)) {
    try {
        New-Item -ItemType Directory -Path $env:TEMP -Force -ErrorAction Stop | Out-Null
        Write-Host "Created TEMP directory: $env:TEMP"
    } catch {
        Write-Error "Failed to create TEMP directory: $env:TEMP. Please check permissions or create it manually."
        exit 1
    }
}

foreach ($ext in $videoExtensions) {
    Get-ChildItem -Path $scriptFolder -Filter $ext -Recurse | ForEach-Object {
        $videoPath = $_.FullName
        $videoDir = Split-Path -Parent $videoPath
        $filenameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)

        # Determine the language code for the output SRT file's name.
        # Given the script's logic (translate non-English to English, transcribe English as English),
        # the SRT content is always English.
        $outputSrtLangCode = "en" 

        $finalSubtitleFilename = "$filenameWithoutExt.$outputSrtLangCode.srt"
        $finalSubtitlePath = Join-Path $videoDir $finalSubtitleFilename

        # Check if the FINAL specific subtitle file already exists
        if (-not (Test-Path $finalSubtitlePath)) {
            Write-Host "`nProcessing video: $($_.Name)"

            # --- 1. Language Detection ---
            Write-Host "Detecting language for: $($_.Name)..."
            $detectionArgs = @(
                "`"$videoPath`"", 
                "--model", "tiny",
                "--task", "transcribe",
                "--threads", "2", 
                "--output_format", "txt", 
                "--output_dir", "`"$env:TEMP`"" 
            )

            $detectOutputLines = $null
            if ($whisperCallMethod -eq "python_module") {
                $detectOutputLines = & $whisperPythonExecutable -m whisper $detectionArgs 2>&1
            } else {
                $detectOutputLines = & $whisperDirectCommand $detectionArgs 2>&1
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Language detection command failed for $($_.Name). Exit code: $LASTEXITCODE"
                Write-Warning "Whisper Output (Detection): $($detectOutputLines | Out-String)"
                $detectedLanguage = "english" # Defaulting
                Write-Host "Defaulting to English due to detection command failure."
            } else {
                $detectedLanguage = $null
                foreach ($line in $detectOutputLines) {
                    if ($line -match "Detected language:\s*(.+)") {
                        $detectedLanguage = $Matches[1].Trim().ToLower()
                        Write-Host "Raw detected language string: '$($Matches[1].Trim())', processed as: '$detectedLanguage'"
                        break
                    }
                }

                if (-not $detectedLanguage) {
                    Write-Warning "Could not parse detected language for $($_.Name) from Whisper output."
                    Write-Warning "Whisper Output (Detection): $($detectOutputLines | Out-String)"
                    Write-Host "Defaulting to English processing for $($_.Name)."
                    $detectedLanguage = "english" 
                }
            }

            Get-ChildItem -Path $env:TEMP -Filter "$filenameWithoutExt.*" | Where-Object {
                $_.Name -in @("$filenameWithoutExt.txt", "$filenameWithoutExt.vtt", "$filenameWithoutExt.srt", "$filenameWithoutExt.json", "$filenameWithoutExt.tsv")
            } | ForEach-Object {
                Write-Host "Cleaning up temporary detection file: $($_.FullName)"
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }

            # --- 2. Determine Model, Task, and Language for Subtitle Generation ---
            $model = ""
            $task = ""
            $languageToUse = "" # This is the language Whisper will use as input

            if ($detectedLanguage -ne "english") {
                Write-Host "Non-English detected ($detectedLanguage). Using 'large' model and translating to English..."
                $model = "large"       
                $task = "translate"    
                $languageToUse = $detectedLanguage 
            } else {
                Write-Host "English detected (or defaulted to English). Using 'small' model for transcription..."
                $model = "small"       
                $task = "transcribe"
                $languageToUse = "en"
            }

            # --- 3. Generate Subtitles ---
            Write-Host "Generating subtitles for $($_.Name) (will be saved as $finalSubtitleFilename) using model '$model', task '$task', source language '$languageToUse'..."
            
            $subtitleArgs = @(
                "`"$videoPath`"", 
                "--model", $model,
                "--language", $languageToUse, 
                "--task", $task,
                "--threads", "2", 
                "--output_format", "srt",
                "--output_dir", "`"$videoDir`"" 
            )
            
            # Define the path where we expect Whisper to create its raw output (e.g., video.srt)
            $whisperExpectedRawOutputSrtPath = Join-Path $videoDir "$filenameWithoutExt.srt"

            # If this raw output path somehow already exists, remove it.
            if (Test-Path $whisperExpectedRawOutputSrtPath) {
                Remove-Item $whisperExpectedRawOutputSrtPath -Force -ErrorAction SilentlyContinue
            }
            # Also, if the final path exists (e.g. video.en.srt) and it's different from raw path,
            # ensure it's removed if we intend to overwrite via rename.
            # However, the top-level "if (-not (Test-Path $finalSubtitlePath))" handles skipping if it's already perfectly done.
            # If $finalSubtitlePath exists but $whisperExpectedRawOutputSrtPath does not, and we are here, it means
            # the initial check passed (e.g. case difference). Move-Item -Force will handle overwrite.
            if (($finalSubtitlePath -ne $whisperExpectedRawOutputSrtPath) -and (Test-Path $finalSubtitlePath)) {
                 # This state might occur if a previous run created video.en.srt but the script was stopped before video.srt was removed.
                 # Or if filenames differ only by case and Test-Path is case-sensitive for the initial check but not for Whisper's output.
                 # To be safe, if we are regenerating, clear the final path if it's not the same as the temp path Whisper might create.
                 # Remove-Item $finalSubtitlePath -Force -ErrorAction SilentlyContinue
                 # On second thought, Move-Item -Force later should handle this. Let's simplify and rely on Move-Item -Force.
            }


            $subtitleGenerationOutput = $null
            if ($whisperCallMethod -eq "python_module") {
                $subtitleGenerationOutput = & $whisperPythonExecutable -m whisper $subtitleArgs 2>&1
            } else {
                $subtitleGenerationOutput = & $whisperDirectCommand $subtitleArgs 2>&1
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Error "Subtitle generation command failed for $($_.Name). Exit code: $LASTEXITCODE"
                Write-Warning "Whisper Output (Generation): $($subtitleGenerationOutput | Out-String)"
            } else {
                # Whisper command was successful, now try to find and rename/confirm the output.
                if (Test-Path $whisperExpectedRawOutputSrtPath) {
                    # Whisper created the expected raw output (e.g., video.srt)
                    if ($whisperExpectedRawOutputSrtPath -ne $finalSubtitlePath) {
                        try {
                            Move-Item -Path $whisperExpectedRawOutputSrtPath -Destination $finalSubtitlePath -Force -ErrorAction Stop
                            Write-Host "Successfully generated subtitles: $finalSubtitlePath"
                        } catch {
                            Write-Error "Successfully generated Whisper output ($whisperExpectedRawOutputSrtPath), but failed to rename to $finalSubtitlePath. Error: $($_.Exception.Message)"
                        }
                    } else {
                         # This case is unlikely if $outputSrtLangCode is always "en"
                         Write-Host "Successfully generated subtitles: $finalSubtitlePath (Whisper's output name matched the desired final name)."
                    }
                } elseif (Test-Path $finalSubtitlePath) {
                    # Whisper didn't create the expected raw "video.srt", but it MIGHT have directly created "video.en.srt"
                    Write-Host "Successfully generated subtitles: $finalSubtitlePath (Whisper seems to have created this file directly)."
                } else {
                    # Neither the expected raw output nor the final file was found.
                    Write-Warning "Whisper command succeeded, but its expected default output file ($whisperExpectedRawOutputSrtPath) was NOT found."
                    Write-Warning "Also, the final target file ($finalSubtitlePath) was not found."
                    Write-Warning "Please check the directory '$videoDir' for any .srt files related to '$filenameWithoutExt'."
                    Write-Warning "Whisper Output (Generation): $($subtitleGenerationOutput | Out-String)"
                }
            }
        } else {
            Write-Host "Skipping $($_.Name) - subtitles already exist at $finalSubtitlePath."
        }
    }
}

Write-Host "`nAll videos processed."
