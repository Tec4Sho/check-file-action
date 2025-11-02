# Check-File-Action v1.0.0

Use to check **workspace build files** for errors and also locate file(s) an display its content or search for a text (string) match located within all files.


[***Please use v1.1.0 for fixing errors or advanced search engine.***](https://github.com/Tec4Sho/check-file-action/tree/v2)


>[!NOTE]
Search starts from github workspace or root directory on file types listed here for matches.


## Parameters:

- `filename:`  File name to search for in workspace directories.
  - string required eg: < `init.c` >

## Optional:

- `filetype:`  Check only these file types when searching for text word match use when needed. Defaults search all files.
  - string required: < `.c .h .cpp` >

- `dirname:`  Your workspace directory name use when needed.
  - string required: < `workspace` >

- `rootdir:`  Search from root directory use when needed.
  - boolean required: < `true` >

- `content:`  Display file & directory contents for filename found.
  - boolean required: < `true` >

- `include:`  Check all #include <name> for errors in C/C++ file if found.
  - boolean required: < `true` >

### Wildcard Support :

- Support for **wildcards is limited** not fully tested. If a file is found multiple times in different directories all will be checked for errors if of extension types listed. Use dirname to add directory of files exact folder name to search if known.
  
  - ( `*.extension` ) searches allowed.
 
### Defaults :

Adding a name that is not a actual file **check-file-action** will then proceed with checking files for any **TEXT STRING MATCHES** of the provided information.

Names not allowed for text matches

- Makefile, common /bin file names ( `grep cat log` ) you get the point here. Also ( `text.text` ) searches.

Names allowed for text matches 

- Non system filename ( `musbfsh_base musbfsh base` ) an so on. Experiment with it.

File types not listed for error checking if found will still display file location and file text data if `content: true`.

- File names found will be scanned if they are of file types listed below only for `errors` .
  
  - `c`
  - `cc`
  - `cpp`
  - `cxx`
  - `h`
  - `hh`
  - `hpp`
  - `hxx`
  - `c++`
  - `tpp`
  - `txx`
  - `c*`
  - `h*`
  - `t*`
  - `sh`
  - `SH`
  - `mk`
  - `makefile`
  - `Makefile`
  - `GNUmakefile`

### Check File Report :

- Found in github action runner workflow logs.

  - Check your step output.
    - (`check-file-action@master`)

  - check file action `error.log` report file can be found in repo releases under the `filename:` that you set.

### Workflow Actions :

 Action step example:



    - name: Check File
      if: inputs.check-file != ''
      uses: Tec4Sho/check-file-action@v1.0.0
      with:
        filename: ${{ inputs.check-file }}
        filetype: .c .h .cpp .c++ .txx
        dirname: workspace
        rootdir: false
        content: true
        include: true
      continue-on-error: true



- Action runs using [cppcheck](https://github.com/danmar/cppcheck) [shellcheck](https://github.com/koalaman/shellcheck)
[checkmake](https://github.com/checkmake/checkmake)
[batcat](https://github.com/sharkdp/bat) linux packages development tools using their custom settings.

[.github/workflows/Check-File-Action.yml](.github/workflows/Check-File-Action.yml)

  - Workflow template to run checks locally on your repository files located in the required path for running github workflow actions.

>[!TIP]
Fork this repo to run error checking of your cloned repository files locally using our custom workflow template. Add one or two repositories for file searches and checking.

#### Checkmake Info :

- You can add a `checkmake.ini` file found above to your repo root directory to apply rules for checking Makefile types.

  - checkmake link: 
https://github.com/checkmake/checkmake

#### Shellcheck Info :

- You should make sure any sh files you want checked has a shebang eg: ( #!/bin/bash ) at the vary top of the file before scanning for errors.

  - shellchell link:
https://github.com/koalaman/shellcheck

#### Cppcheck Info :

- When checking c, h family types listed above if no error is found. Rarely cppcheck may still ask about header file or to suppress a warning, below is totally fine to ignore.
  
  - ( `nofile:0:0: information:` )

  - cppcheck link:
https://github.com/danmar/cppcheck

#### Batcat Info :

- Batcat is using custom settings for its style and display for a elegant yet informative UI display. Do to the display output during `content: true` usage runtime may increase.

  - uses: ` --theme=ansi ` to support light and dark mode in terminal logs for compatibility purposes.

  - bat link:
https://github.com/sharkdp/bat

##### Usage Skill Level :

- User Friendly `Beginners`
 - Professional `Developers`
   - Very easy to **setup**
