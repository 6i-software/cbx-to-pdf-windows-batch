
## Version 1.1.0
> 2023.10.23

### Features

- Check if binaries dependencies are installed and available (*7Zip* and *ImageMagick*). CbxToPdf use 7-Zip to unpack CBX file, and ImageMagick to convert webp images in png format and convert images to PDF.
- Measures time conversion of each cbx files. Show with info verbosity level.
- Deletes temporary images folder from cbx file on each iteration, if the option `OPTION_KEEP_FOLDER_TEMP` is not enabled.

### Fix

- Fix: Support folder and filename with parenthesis.
- Fix: Change the current working directory to the folder of the batch script at begin of process.

---

## Version 1.0.0
> 2023.05.30

### Features

- Convert a cbr and a cbz file into PDF.
- Batch processing of one or multiple given folder. All cbx files in given folder are convert in PDF.
- Convert images (webp support) before Pdf generation.
- Handle of several levels of verbosity (`--quiet`, `-v=normal`, `-vv=info` or `-vvv=debug`).
- Set output folder, where all PDF are generated.
- Use a configuration file `config.ini` to set binary dependencies, and configure the process of conversion according to the ImageMagick's parameters.