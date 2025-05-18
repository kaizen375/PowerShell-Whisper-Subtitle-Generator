# PowerShell Whisper Batch Subtitle Generator

This PowerShell script automates the process of generating subtitles for video files using the powerful [Whisper](https://github.com/openai/whisper) speech-to-text model by OpenAI. It can detect the language of the video, utilize appropriate Whisper models for transcription or translation (to English), and saves the subtitles in the standard `.srt` format.

## Features

* **Batch Processing:** Automatically processes all supported video files within the script's directory (and subdirectories if desired).
* **Language Detection:** Attempts to detect the language of the audio track using Whisper's language identification capabilities.
* **Model Switching:** Uses the `tiny` model for language detection and defaults to the `small` model for English transcription. For non-English videos, it utilizes the `large` model for potentially better translation to English.
* **Translation to English:** If a non-English language is detected, the script automatically translates the subtitles to English.
* **Simple Output:** Saves the subtitle file (`.srt`) in the same directory as the video file, named after the video file (e.g., `movie.mkv` will produce `movie.srt`).
* **Configuration:** Easy-to-configure variables at the beginning of the script to match your Whisper installation.

## Prerequisites

Before using this script, you need to have **Whisper** installed and accessible on your system. Here are the common ways to install it:

**1. Using `whisper-standalone` (Recommended for ease of use):**

   * This is a standalone, pre-packaged version of Whisper that includes all necessary dependencies.
   * Go to the [Releases page of `whisper-standalone`](https://github.com/jianfch/whisper-standalone-win/releases) (for Windows) or search for similar standalone packages for other operating systems.
   * Download the latest release (usually a `.zip` file).
   * Extract the contents to a folder on your computer (e.g., `C:\Whisper`).
   * **Configuration:** In the PowerShell script, you would likely set the `$whisperDirectCommand` variable to the path of the `whisper.exe` executable within the extracted folder (e.g., `$whisperDirectCommand = "C:\Whisper\whisper.exe"`). You would also set `$whisperCallMethod = "direct"`.

**2. Using `pip` (if you have Python and `ffmpeg` installed):**

   * Ensure you have Python 3.8+ installed on your system. You can download it from [https://www.python.org/downloads/](https://www.python.org/downloads/).
   * Ensure you have `ffmpeg` installed. This is a crucial dependency for Whisper to handle audio and video files.
      * **Windows:** You can download `ffmpeg` from [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html). Download the "git master builds" or a stable release, extract the `ffmpeg.exe`, `ffplay.exe`, and `ffprobe.exe` files, and add the directory containing them to your system's `PATH` environment variable.
      * **macOS:** You can install it using Homebrew: `brew install ffmpeg`
      * **Linux (Debian/Ubuntu):** `sudo apt update && sudo apt install ffmpeg`
      * **Linux (Fedora/CentOS):** `sudo dnf install ffmpeg`
   * Open your Command Prompt or PowerShell and install Whisper using `pip`:
      ```bash
      pip install -U openai-whisper
      ```
   * **Configuration:** In the PowerShell script, you would typically set:
      ```powershell
      $whisperCallMethod = "python_module"
      $whisperPythonExecutable = "python" # or "python3" depending on your Python installation
      ```

## How to Use

1.  **Save the Script:** Save the PowerShell code as a `.ps1` file (e.g., `generate_subtitles.ps1`).
2.  **Configure Whisper Command:** Open the `.ps1` file in a text editor and carefully configure the **`# USER: PLEASE CONFIGURE THIS`** section at the beginning. Choose the method you used to install Whisper and set the `$whisperCallMethod`, `$whisperPythonExecutable`, and `$whisperDirectCommand` variables accordingly.
3.  **Place in Video Directory (Optional):** You can place the script in the same directory as your video files, or in a parent directory to process videos recursively.
4.  **Run the Script:** Open PowerShell, navigate to the directory where you saved the script, and run it using the following command:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\generate_subtitles.ps1
    ```
    **Explanation:**
    * `powershell`: Invokes the PowerShell executable.
    * `-ExecutionPolicy Bypass`: Temporarily bypasses the PowerShell execution policy to allow the script to run.
    * `-File .\generate_subtitles.ps1`: Specifies the path to your script file.
5.  **Subtitles Generated:** The script will process all supported video files in the current directory (and subdirectories if you don't modify the `Get-ChildItem` command) that do not already have a corresponding `.srt` file. The generated subtitle files (`.srt`) will be saved in the same directory as their respective video files.

**Important Note on Execution Policy:** You might be able to change the default execution policy for your user or the entire system using the `Set-ExecutionPolicy` cmdlet. However, using `Bypass` in the command line is a common way to run a specific script without altering the global or user policy. If you frequently run your own scripts, you might consider setting a less restrictive policy for your user (e.g., `RemoteSigned`), but understand the security implications before doing so.

## Script Configuration

The following variables at the beginning of the script need to be configured based on your Whisper installation:

* `$whisperCallMethod`: Set to `"direct"` if you are using a standalone executable or an alias directly accessible in your system's PATH. Set to `"python_module"` if you installed Whisper using `pip`.
* `$whisperPythonExecutable`: If `$whisperCallMethod` is `"python_module"`, set this to the command to run Python (e.g., `"python"`, `"python3"`, `"py"`).
* `$whisperDirectCommand`: If `$whisperCallMethod` is `"direct"`, set this to the direct command to run Whisper (e.g., `"whisper"`, `"C:\Whisper\whisper.exe"`).

You can also adjust the `$videoExtensions` array to include other video file formats you want to process.

## License

[*(Choose a license and add it here, e.g., MIT License. You can find common licenses at https://choosealicense.com/)*](https://choosealicense.com/)

## Contributing

[*(Optional: Add information on how others can contribute to your script)*]

## Issues

If you encounter any issues or have suggestions for improvement, please feel free to [open an issue](https://github.com/kaizen375/PowerShell-Whisper-Subtitle-Generator/issues) on this GitHub repository.
