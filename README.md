# Check-File-Action 
v2.0.0

Use to check **workspace build files** for errors and try auto fixing them or display suggestions to fix found errors. also locate file(s) an display its location, content or search for any text (string) match located within all files.


>[!NOTE]
Search starts from github workspace or root directory on all files.


## Parameters:

- `filename:`  File name to search for in workspace directories.
  - string required eg: < `init.c` >

- `filetext:`  Text to search files for matches in workspace directories.
  - string required eg: < `OF_CONFIG` >

## Optional:

- `filetype:`  Check only these file types when searching for text word match use when needed. Defaults search all files.
  - string required: < `.c .h .cpp` >
 
- `filefix:`  Fix files with errors if able in workspace directories.
  - boolean required eg: < `true` >

- `dirname:`  Your workspace directory name use when needed.
  - string required: < `workspace` >

- `rootdir:`  Search from root directory use when needed.
  - boolean required: < `true` >

- `content:`  Display file & directory contents for filename found.
  - boolean required: < `true` >

- `include:`  Check all #include <name> for errors in C/C++ file if found.
  - boolean required: < `true` >

- `recheck:`  Recheck file(s) for errors if repaired by filefix.
  - boolean required: < `true` >

- `report:`  Create logs for files with errors in user repo releases section.
  - boolean required eg: < `true` >

- `update:`  Update all locally fixed files with errors to remote repo.
  - boolean required eg: < `true` >

### Wildcard Support :

- Support not fully tested. If a filename is found multiple times in different directories all will be checked for errors if of extension types listed. Use dirname to add directory of files exact folder name to search if known.
  
  - ( `*.extension` ) searches allowed.
 
### Defaults :

**TEXT STRING MATCHES** of the provided information.

Names allowed for text matches

- All text strings ( `musbfsh_base musbfsh base` ) an so on. Experiment with it.

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

>[!NOTE]
 Makefile Files are not auto-fix with `filefix: true` .

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

#### Clang-tidy Info :

- When checking `c, h` family types listed above if error is found. clang-tidy will try to fix them if `filefix: true`. Afterwards cppcheck will be ran to recheck for errors again. If errors are repaired locally. Setting `update: true` will update your remote repo files after repairing any files.

  - clang-tidy link:
https://clang.llvm.org/extra/clang-tidy/

#### Batcat Info :

- Batcat is using custom settings for its style and display for a elegant yet informative UI display. Do to the display output during `content: true` usage runtime may increase.

  - uses: ` --theme=ansi ` to support light and dark mode in terminal logs for compatibility purposes.

  - bat link:
https://github.com/sharkdp/bat

##### Usage Skill Level :

- User Friendly `Beginners`
 - Professional `Developers`
   - Very easy to **setup**
