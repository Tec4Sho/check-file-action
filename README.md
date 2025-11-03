
# Check-File-Action v1.1.0


Use to check **workspace build files** for errors and try auto fixing them or display suggestions to fix found errors. **Can locate file(s) an display it's content or search for a text (string) match within all __local__ files.**

![Check File Action](/assets/images/check_file_action.png)

## **Helpful**

>[!IMPORTANT]
Search starts from github workspace or root directory on all files.


### Parameters:

- `filename:`  File name to search for in workspace directories.
  - string required: ` init.c `
 
__OR__

- `filetext:`  Text pattern to search for in workspace directory files.
  - string required: ` OF_CONFIG `

### Optional:

- `filetype:`  Check only these file types when searching for text word match use when needed. Defaults search all files.
  - string: ` .c .h .cpp `

- `dirname:`  Your workspace directory name use when needed.
  - string: ` workspace `

- `content:`  Display file & directory contents for filename found.
  - boolean: ` true `

- `include:`  Check all #include <name> for errors in C/C++ file if found.  - boolean: ` true `

- `rootdir:`  Search from root directory use when needed.
  - boolean: ` true `

- `recheck:`  Recheck file(s) for errors if repaired by filefix.
  - boolean: ` true `

- `repair:`  Fix files with errors if able in workspace directories.
  - boolean: ` true `

- `report:`  Create logs for files with errors in user repo releases section.
  - boolean: ` true `

- `update:`  Update remote repo with locally fixed files when using filefix.
  - boolean: ` true `


#### Wildcard Support :

- Supports `*` all files. If a given filename is found multiple times in different directories all will be checked for errors if of extension types listed.

>[!TIP]
Use `dirname:` to add directory name that contains file to check errors if multiple files with same name so only that file is checked or simply rename the file for checking.
  
  - ( `*.extension` ) searches allowed.
 

#### Defaults :

When considering using wildcards, check your (**LOCAL REPO**) overall file count to determine possible runtime length. 

- Displays repo file count if ` content: true `

Names allowed for text matches

- All text string patterns ( `musbfsh_base MUSBFSH base` ) an so on. Experiment with it.

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
 Makefile Files are not auto-fix with ` repair: true `


#### Check File Report :

- Found in github action runner workflow logs.

  - Check your step output.
    - (`check-file-action@master`)

  - check file action `error.log` report file can be found in repo releases under the `filename:` that you set.

 - if `repair:` , `update:` and `report: ` are all `true` their will be additional information about any files changes that happened remotely.

#### Workflow Actions :

 Action step example:



    - name: Check File
      if: inputs.check-file != ''
      uses: Tec4Sho/check-file-action@v2
      with:
        filename: ${{ inputs.check-file }}
        filetext: ${{ inputs.check-text }}
        filetype: .c .h .cpp .cxx .txx
        dirname: workspace
        content: true
        include: true
        rootdir: false
        recheck: false
        repair: false
        report: true
        update: false
      continue-on-error: true

>[!CAUTION]
When `update: true` is set `.git` may need special permissions to push changes back remotely in these cases adding the below code to your own workflow.yml may help.

    permissions: # required for all workflows 
      security-events: write # only required for workflows in private repositories 
      actions: write 
      contents: write
      

**Action runs using**

[cppcheck](https://github.com/danmar/cppcheck)

[checkmake](https://github.com/checkmake/checkmake)

[clang-tidy](https://clang.llvm.org/extra/clang-tidy/)

[shellharden](https://github.com/anordal/shellharden)

[shellcheck](https://github.com/koalaman/shellcheck)

[batcat](https://github.com/sharkdp/bat)

**linux packages and development tools.**


[.github/workflows/Check-File-Action.yml](.github/workflows/Check-File-Action.yml)

  - Workflow template to run checks locally on your repository files. ***It's location is in the required path needed for running a github workflow action***.

>[!TIP]
Fork this repo to run error checking of your cloned repository files locally using our custom workflow template. Add one or two repositories for file searches and checking.


#### Checkmake Info :

- You can add a `checkmake.ini` file found above to your repo root directory to apply rules for checking Makefile types.

  - checkmake link: 
https://github.com/checkmake/checkmake


#### Cppcheck Info :

- When checking c, h family types listed above if no error is found. Rarely cppcheck may still ask about header file or to suppress a warning, below is totally fine to ignore.
  
  - ( `nofile:0:0: information:` )

  - cppcheck link:
https://github.com/danmar/cppcheck


#### Clang-tidy Info :

- When checking `c, h` family types listed above if error is found. clang-tidy will try to fix them if `repair: true`. Afterwards cppcheck will check again for errors if `recheck: true`. **If errors are repaired locally, setting `update: true` will also update your remote repo files**.

  - clang-tidy link:
https://clang.llvm.org/extra/clang-tidy/


#### Shellharden Info :

- Make sure any sh files you want fixed has a shebang eg: ( `#!/bin/ksh` ) at the vary top of the file before scanning for repairing any error.

  - shellharden link:
https://github.com/anordal/shellharden


#### Shellcheck Info :

- Please make sure any sh files you want checked has a shebang eg: ( `#!/bin/bash` ) at the vary top of the file before scanning for errors.

  - shellcheck link:
https://github.com/koalaman/shellcheck


#### Batcat Info :

- Batcat is using custom settings for its style and display for a elegant yet informative UI display. **Do to the display output during `content: true` usage runtime may slightly increase**.

  - uses: ` --theme=ansi ` to support light and dark mode in terminal logs for compatibility purposes.

  - bat link:
https://github.com/sharkdp/bat



##### Usage Skill Level :

- User Friendly `Beginners`
 - Professional `Developers`
   - Very easy to **setup**



- Link to the helpful section: [Link Text](#helpful).

![Screenshot of a commit on GitHub.](https://myoctocat.com/assets/images/base-octocat.svg)
