# <a id="top">Useful Bash Functions</a>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

## <a id="purpose">Purpose</a>

The bash functions in the file `functions.sh` can be used to enhance and manage bash scripts.
When the file `functions.sh` is included (sourced) in a parent script more than 70 useful functions and many variables are available to the parent script.
Some additional gawk scripts present in this distribution are used by and provide support for `functions.sh`.
Also included in the distribution are a few additional and useful bash support scripts.

This distribution is designed to work in a bash shell environment on a system executing the Linux O/S.
It has only been tested on the KDE terminal emulator `konsole` and partially tested on GNOME `terminal`.

There are three major functions in `functions.sh`: `GET_ARGS`, `IS_EXCLUSIVE` and the set of `ASK` functions.

In a parent script, `GET_ARGS` is called with arguments (directives) that "define" the options and arguments
available to the parent script and provide built-in help.
When the parent script is invoked as a command, GET_ARGS parses the parent script options on the command line
and presents the script with a deterministic summary of the options used.
The `GET_ARGS_DIRECTIVES` also allow the user to describe the script purpose and the meaning of each option/argument
defined. This makes the parent script self documenting with man-like pages.

The `IS_EXCLUSIVE` function allows you to easily verify combinations and defaults of parent script options.

The `ASK` set of functions provide mechanisms for asking a question and verifying the response.
The ASK prompt is fully configurable. Acceptable responses can be specified with the -C "CHOICES" option.
`ASK_WITH_MENU` presents a menu created from an array or from an argument list.
ASK can interact with the user with a text-based interface or a GUI dialog box interface.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="contents">Contents</a>

&nbsp;&nbsp;&nbsp;&nbsp;[Purpose](#purpose)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Contents](#contents)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Caveat](#caveat)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Installation](#installation)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Required Commands](#required-commands)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Installation Procedure](#installation-procedure)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Uninstall Procedure](#uninstall-procedure)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Summary of the Major Functions and Variables](#summary)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Major Functions](#major-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Major Global Variables](#major-global-variables)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Introduction to Some Major Components](#documentation)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Scripts](#script-documentation)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[`functions.sh`](#functionssh)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[FIND-FUNCTIONS](#find-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[MKSCRIPT](#mkscript)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[EXTRA BASH FUNCTIONS](#extra-bash-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[GET ARGS GLOBAL DEFAULTS](#get-args-global-defaults)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Functions](#function-documentation)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[GET_ARGS](#get-args)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Examples of Help Implemented by GET_ARGS](#example-of-help)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[IS_EXCLUSIVE](#is-exclusive)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Example of GET_ARGS and IS_EXCLUSIVE working together](#example-of-get-args)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ASK Functions](#ask-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[TMP_FILE_CREATE Functions](#tmp-file-create-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Examples of Functions](#examples-of-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Experiment](#experiment)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Experiment with ASK](#experiment-with-ask)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Experiment with ASK_WITH_MENU](#experiment-with-ask-with-menu)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Fancy Sparse Arrays with ASK_WITH_MENU](#fancy-ask-with-menu)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Fancy Multi-Menus with ASK_WITH_MENU](#fancy-ask-with-menu2)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Experiment with Some Other Functions](#experiment-with-other-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[COLOR Functions](#color-functions)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ERROR & WARNING](#error-warning)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[PAD_IT, TRIM & ZERO_FILL](#padit-trim-zerofill)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[PAUSE](#pause)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[PROGRESS](#progress)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[SORT_ARGS & SORT_ARGS_WS](#sort-args-ws)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[FUNCTIONS](#functionsexample)<br>
&nbsp;&nbsp;&nbsp;&nbsp;[Bugs](#bugs)<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="caveat">Caveat</a>

The functions and scripts are written in the bash scripting language, with some supporting scripts written in gawk.
The intention of this distribution is to provide, to the home user writing bash scripts, easy access to boilerplate or to capabilities not immediately available or obvious.
It is, and always will be, a work in progress.
For more advanced scripting users they provide a quick way to implement some standard scripting capability.

I have carefully checked and re-checked everything ad-nauseam. So, of course, there are many undiscovered bugs.

Note: The coding is not necessarily the best or the most efficient. Therefore it is suggested that `functions.sh` not be used in a production or multi-user environment.
However, be that as it may, the functions allow one to concentrate on the purpose of a new script rather than having to duplicate common requirements.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="installation">Installation</a>

### <a id="required-commands">Required Commands</a>

The following linux commands are required for full functionality.
Most commonly used Linux distributions either include or make available these commands.
The install script checks fo the the existance of these commands.

| COMMAND | REQUIREMENT |
|--|--|
| bash      | Required. |
| gawk/awk  | gawk (or a link to awk) is required. |
| sort      | Required. |
| curl      | Required to download the distribution. |
| python    | Required to extract the distribution. |
| less      | The default "pager". Required unless you configure a different pager. |
| nmap      | Only if you use the network functions. |
| yad       | Only if you use the -G (GUI) option in any "GUI-enabled" functions. |

if you don't have `gawk` then a symbolic link to awk will work as well. This is done by the intall script.

```bash
sudo ln -s /usr/bin/awk /usr/bin/gawk
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="installation-procedure">Installation Procedure</a>

There are two ways to install `useful-bash-functions` - a user install and a system install.  

1. The user install is made into your personal directory `~/bin` (<WHERE_BIN_DIR>).
The functions are only available to your login.  

2. In a system install the functions are available to all users.
The installation script `install.sh` installs the bash scripts in the directory /usr/local/bin (`<WHERE_BIN_DIR>`)
except for:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`FUNCTIONS-SH-EXTRA-FUNCTIONS.sh`  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`FUNCTIONS-SH-GLOBAL-DEFAULTS.sh`  
which are installed in the directory /etc/profile.d (`<WHERE_ETC_DIR>`).

> [!IMPORTANT]
> In this README, the terms `<WHERE_BIN_DIR>` and `<WHERE_ETC_DIR>` are used in some pathnames.
They have different values depending upon whether you used a user install or a system install.
>
> | TERM | User Install | System Install |
> |--|--|--|
> | <WHERE_BIN_DIR> | ~/bin | /usr/local/bin |
> | <WHERE_ETC_DIR> | ~/bin | /etc/profile.d |

#### Step 1

From the command line in your terminal emulator create an empty download directory.
Then change your working directory to it.

```bash
mkdir ~/MyDownLoad                   # Or to wherever you want
cd ~/MyDownLoad                      # And set your working directory
```

#### Step 2

Download the distribution file:

```bash
curl -L -O  https://github.com/ProcessorMicro/useful-bash-functions/archive/refs/heads/main.zip
```

Extract the downloaded `main.zip` file.

```bash
python -m zipfile -e main.zip .    # Unzip the downloaded file
```

> [!TIP]
> Most linux distributions provide a GUI **unzip** alternative to using python.
> 
> 1. Open the linux distribution file manager (dolphin, nautilus, files, ...)
> 
> 2. Locate the downloaded file `main.zip`.
> 
> 3. Right-click on `main.zip` and select **Extract**.  
Then select **Extract to here** (or similar wording).

#### Step 3

Install the distribution either for just one user (User Install) or for all users (System Install).

#### Step 3a - User Install (Recommended)

```bash
cd useful-bash-functions-main      # Change your workng directory
bash ./install.sh                  # And install it for your use only
```

#### Step 3b - System Install

```bash
# Open a terminal session as "root"
bash <PATH_TO_UNZIPPED_DISTRIBUTION>/install.sh" --system-install   # Install it for every user
```

#### Step 3c - Continue...

The install script should display the following message:  
&nbsp;&nbsp;&nbsp;&nbsp;**Install script for the "functions.sh" distribution.**  
&nbsp;&nbsp;&nbsp;&nbsp;**Beginning installation...**

- Instead, if the first message is an error something like:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Command not found.**

- or a message something like:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**./install.sh: cannot execute: required file not found.**

- Or an error message

It means the command `bash` is not installed.  
Install `bash` and re-execute `install.sh`.

#### Step 4

`MKSCRIPT` creates a script "template" and inserts YOUR copyright notice into the generated script.
To reflect your needs for the generated copyright, edit the file `<WHERE_BIN_DIR>/MKSCRIPT`.

- Modify the generated name by changing the following line:

```bash
DEFAULT_NAME="Mike Armstrong"
```
-  Modify the generated copyright lines after the following comment lines:

```bash
# ==============================================================
# = Modify the following copyright information as appropriate. =
# ==============================================================

```

#### Step 5

Edit the file `<WHERE_ETC_DIR>/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh` and change the value of the global environment variables
(as instructed within the script) to meet your needs.

#### Step 6

After installation,there are three ways to implement `functions.sh`.

1. Like a bull in a china shop:  
&nbsp;&nbsp;&nbsp;&nbsp;Logout and then login.

2. Refined:  
&nbsp;&nbsp;&nbsp;&nbsp;Close all terminal sessions and re-open them.

3. Laborious - Type the commands:
```bash
source <WHERE_ETC_DIR>/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh
source <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="uninstall-procedure">Uninstall Procedure</a>

The uninstall script `uninstall.sh` removes the components of `functions.sh`.

#### Step 1

Change your working directory to the unzipped contents: e.g., `~/MyDownload/useful-bash-functions`

```bash
cd ~/MyDownload/useful-bash-functions-main       # Or wherever you unzipped the distribution
```

#### Step 2

Execute the uninstall script.  
There are two ways cepending whether you did a user install or a system install.

#### Step 2a - If you did a user install

```bash
bash ./uninstall.sh
```

#### Step 2b - If You did a system install

```bash
# Open a terminal session as "root"
bash <PATH_TO_UNZIPPED_DISTRIBUTION>/uninstall.sh" --system-install
```

#### Step 3

Clean up.

```bash
cd ~/MyDownload                          # Backup to the parent directory
rm -rf useful-bash-functions             # Remove the installation files
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

# <a id="summary">Summary of the Major Functions and Variables within `functions.sh`</a>

The following is a description of the functions and variables in `functions.sh` that are most likely to be used.

-----------------------------

## <a id="major-functions">Major Functions</a>

| MAJOR FUNCTIONS             | DESCRIPTION |
|--|--|
| GET_ARGS                    | Parses parent script options and arguments and provides man-page like help. Described in more detail below. |
| IS_EXCLUSIVE                | Detects and manages combinations of parent script options when the parent script is executed as a command. Described in more detail below. |
| USAGE, ERROR, WARNING       | A set of functions to manage error or warning parent script messages. |
| ASK, ASK_GUI                | Manages parent script questions and validates the answers. Described in more detail below. |
| ASK_WITH_MENU, ASK_WITH_MENU_GUI | Same as `ASK` but presents a menu of choices generated from an array or from its arguments and accepts single or multiple answers. Described in more detail below. |
| IS_ROOT, IS_NUMERIC, IS_... | A set of testing functions. for example `IS_ROOT` returns TRUE if the parent script is running with root privileges. |
| ROOT_ONLY | Exits the parent script if it is not executed as `root`. |
| TEST_...                    | A set of functions and variables that can be used while testing the parent script to surround commands that make a (critical) 'change'. Executing the parent script with the option `-t` or `--test` will cause those commands to be displayed (after all expansions) rather than being executed. |
| SORT_ARGS, SORT_ARGS_WS     | Functions that sorts the arguments to the function and display the sorted result. |
| TMP_FILE_..., TMP_DIR_...   | A set of functions to manage creation and deletion of temporary files and directories. |
| Cleanup Operations          | Upon parent script exit, `functions.sh` automatically deletes any temporary files/directories created by the TMP_... functions and unmounts any filesystems mounted by MOUNT-IT in `functions.sh`. |
| Many other functions...     | Many other uses... |

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="major-global-variables">Major Global Variables</a>

Some of the many variables available for use by the parent script.

| VARIABLE            | DESCRIPTION |
|--|--|
| Opt_XXX             | A variable set by `GET_ARGS` for an option parsed from the command line when the parent script is executed. `Opt_XXX` contains the number of times a particular option is encountered. |
| Opt_XXX_Val[*]      | An array containing the option values for any option `Opt_XXX` having a required or optional value. |
| Opts_All            | A variable containing a list every option encountered (in order but with no values). |
| Args[*]             | An array (origin 1) containing all the arguments encountered when the parent script is executed. |
| CMD                 | The basename of the executing parent script. |
| CMD_DIR             | The directory that contains the parent script |
| ANSWER...           | A (set of) variables containing the response(s) entered by the user when the ASK function is invoked. |
| BLK, RED, GLD, etc. | Variables that can be used to color and format messages displayed by `echo -e`. The function `COLORS_DISPLAY` displays the colors implemented. |
| And many more       | ... |

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

# <a id="documentation">Introduction to some Major Components</a>

All the scripts are self documenting as they all use `GET_ARGS` to define and display options and arguments.
And all the functions are preceded by documentation describing the function usage.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="script-documentation">Scripts</a>

### <a id="functionssh">`functions.sh`</a>

`functions.sh` is a bash script that contains the functions for this distribution.  
It is self documenting. So, typing:

```bash
# Display the complete documentation for every function and variable.
# The display is paged with 'less'.
functions.sh
```

The first page displays the purpose of `functions.sh`.
Followed by the suggested coding to implement `functions.sh` that either should be entered into the environment or at the beginning of a parent script.

Documentation for any `<FUNCTION_NAME>` can be displayed with:

```bash
# Display the documentation for <FUNCTION_NAME>
functions.sh <FUNCTION_NAME>
```

The `functions.sh` self help displays additional information. Vis:

```bash
# Display an introduction to `functions.sh`
functions.sh INTRODUCTION
```

```bash
# Display a list and brief description of the functions available.
functions.sh FUNCTIONS
```

```bash
# Display a list and brief description of the global variables defined.
functions.sh VARIABLES
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="find-functions">FIND-FUNCTIONS</a>

The bash script `FIND-FUNCTIONS` displays the function source code or the documentation for a single function (or a set of functions matching a PATTERN) in `functions.sh`.
However it also can be used for any script that has a recognizable PATTERN for documentation.
It assumes `functions.sh` is installed in the directory <WHERE_BIN_DIR>.
To see the options available for `FIND-FUNCTIONS` type:

```bash
Display an example of `FIND-FUNCTIONS` usage
FIND-FUNCTIONS --HELP
```

```bash
# Display the documentation (comments) paged with "less"
# for the `SORT_ARGS` function in `functions.sh`
FIND-FUNCTIONS -c -l SORT_ARGS
```
To get a paged list of all the functions available in `functions.sh`, type:

```bash
# The pattern "[^_].*" eliminates internal (reserved) functions
FIND-FUNCTIONS --ns -f -l "[^_].*"
```

The same command as above but using long options.

```bash
FIND-FUNCTIONS --no-separator --function-names-only --less "[^_].*"
```

You can use `FIND-FUNCTIONS` to display the comments or functions in another script.
So, for the functions contained in the script `<WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh`  
Try:

```bash
FIND-FUNCTIONS --comments --less --script <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh
```

```bash
# Display the comments for the function RUNME
FIND-FUNCTIONS -c -l -s <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh RUNME
```

```bash
# Display the source code for the function RUNME
FIND-FUNCTIONS -l -s <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh RUNME
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="mkscript">MKSCRIPT</a>

The script MKSCRIPT creates a script template containing the initial lines recommended for a parent script. It also sets execute permission on the created script.  
Try the following examples:

```bash
# Create the script My_Script with execute permission.
# My_Script contains the code to implement functions.sh,
# a copyright notice and a small sample of GET_ARGS.
MKSCRIPT My_Script
```

```bash
less My_Script               # View the generated script code
```

```bash
./My_Script -H               # View the generated help for My_Script
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="extra-bash-functions">FUNCTIONS-SH-EXTRA-FUNCTIONS.sh</a>

The script 'FUNCTIONS-SH-EXTRA-FUNCTIONS.sh' contains additional useful functions.
`install.sh` copies it to the directory `<WHERE_ETC_DIR>`.
These functions are particularly useful in debugging other functions.
And they are always available at the bash command line in a terminal session.

Full documentation of `FUNCTIONS-SH-EXTRA-FUNCTIONS.sh` can be viewed by:

```bash
FIND-FUNCTIONS -c -l -s <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh
```

Three extra functions are available:

| FUNCTION     | DESCRIPTION |
|--|--|
| FUNCTIONS    | Typing this at a command line loads `functions.sh` into your current environment. It also turns off bash debugging (set +x) and sets all `exit` statements in `functions.sh` to be `return` thus preventing any error exits from closing your terminal session. |
| HIGHLIGHT    | A complex grep command that highlights, in a script, salient functions and arguments related to the major functions `GET_ARGS` and `IS_EXCLUSIVE` in this distribution.<br>&nbsp;&nbsp;&nbsp;&nbsp;[(see: FIND-FUNCTIONS Hidden Option)](#find-functions-hidden-option) |
| RUNME        | A function that executes any function in `functions.sh` (or another function library) in a safe (child process) environment and displays the result(s). |

For example, full documentation of function `RUNME` in `FUNCTIONS-SH-EXTRA-FUNCTIONS.sh` can be viewed by:

```bash
FIND-FUNCTIONS -c -l -s <WHERE_ETC_DIR>/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh RUNME
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="get-args-global-defaults">FUNCTIONS-SH-GLOBAL-DEFAULTS.sh</a>

This script sets global variables (`_GET_ARGS_GLOBAL_HELP_DEFAULT_` etc.) and contains instructions on how to change it's value.
Note: The variable establishes a default format for the GET_ARGS help display.
It is installed in the directory `<WHERE_ETC_DIR>`.
For more information see:

```bash
FIND-FUNCTIONS -c -l -s <WHERE_ETC_DIR>/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="function-documentation">Functions</a>

### <a id="get-args">GET_ARGS</a>

`GET_ARGS` is the primary function in this distribution.
It has three basic purposes:

1. Define the parent script's allowable options and arguments with GET_ARGS_DIRECTIVES.
2. When the parent script is executed, GET_ARGS parses the options and arguments supplied on the command line based upon the instructions of the GET_ARGS_DIRECTIVES. The parsed results are made available to the parent script in a deterministic form.
3. Format and display a manpage-like USAGE (help) for the parent script.

`GET_ARGS` functionality is summarized as follows:

| FEATURE | GET_ARGS FEATURE DEXCRIPTION |
|--|--|
| --Opt_D | Options available to the parent script are defined with the GET_ARGS_DIRECTIVES pair `--Opt_D "..."` and `--Des_D "..."`.<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(`--Option_Definition` and `--Description_Definition`). |
| --Des_D | Each defined option has a description that specifies the purpose of that option. The description is formatted and displayed in the help display.
| Options | Options can be single character `-a` or multiple character `--all`. |
| Multiple Spellings | Any option can be defined to have several spellings (`-a` and `--all` and ...). |
| Option Values | Any option can be defined (and enforced) with: no value, a required value or an optional value. |
| Option Control | By default any option can be specified only once. But multiple use of an option can be configured ( i.e. `-x abc -x def -x ghi`) |
| Option Order | When the parent script is invoked the options and arguments can be specified in any order. |
| Opt_XXX, Opt_XXX_Val | Options and values specified when the parent script is invoked are identified in the parent script as variables `Opt_<XXX>` and `Opt_<XXX>_Val`. |
| Arguments | Arguments are collected into an array `Args[*]` (origin 1). |
| Opt/Arg Enforcement | The number of options or arguments can be defined (and enforced). Vis: `--Opts_Min 1`, `--Args_Req 3` ... |
| Built-in Options | Options `-h` `--help` `-H` `--HELP` `-v` `--version` `-t` `--test` are automatically implemented. |
| Auto ManPage | A manpage-like USAGE display (help with color highlights) is generated from the GET_ARGS_DIRECTIVES. |
| Help Formats | For help when the parent script is invoked, three display formats are available: expanded, compact and brief. |
| Help Sections | Help output is divided into sections. GET_ARGS_DIRECTIVES can be used to create text in each section in addition to the text generated automatically.<br>E.G. `--Para O "..."` inserts a paragraph in the options section, `--Example "..."` creates an EXAMPLE section. |
| Help Display | Help output is automatically folded and (usually) properly indented to fit ${COLUMNS} wide.
| Filtered Help | Help output can be filtered to only display portions of the complete help output. This is useful for scripts that have many options or large help displays. |
| Optimization | GET_ARGS saves the results of parsing the GET_ARGS_DIRECTIVES and restores them at subsequent invocations of the parent script. This can save a few milliseconds of CPU time for scripts that have a lot of options. |
| Configurable Defaults | `GET_ARGS` is fully configurable. Every default variable name, default variable value or default action cn be modified. |
| Complementary Functions | Functions IS_EXCLUSIVE, USAGE, ERROR and WARNING compliment GET_ARGS option processing. |

Full documentation of `GET_ARGS` (it is extensive) can be viewed by:

```bash
functions.sh GET_ARGS
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="example-of-help">Examples of Help Implemented by GET_ARGS</a>

Before we look at an example of the coding for `GET_ARGS` we will use help for `FIND-FUNCTIONS` to see how it works. Try the following:

```bash
FIND-FUNCTIONS -h              # This displays the help text in the global default mode.
```

```bash
FIND-FUNCTIONS -he             # This displays the help text in expanded mode.
```

```bash
COLUMNS=70 FIND-FUNCTIONS -H   # Simulate a 70-column terminal. The folding is (almost) perfect.
```

```bash
FIND-FUNCTIONS --HELP=c        # An example of compressed and paged output (or use "-Hc").
```

```bash
FIND-FUNCTIONS -Hb             # Brief, paged help displaying help sections:
                               #   purpose, synopsis and options.
```

> [!NOTE]
> The brief help "options" lines are not wrapped. Use keyboard keys &rarr; and &larr; to view long lines.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="is-exclusive">IS_EXCLUSIVE</a>

This is a "daughter" function to GET_ARGS and must be called after GET_ARGS has been invoked. It's purpose is to create rules that validate allowed combinations of command-line options when a parent script is executed.
When an `IS_EXCLUSIVE` rule is violated, an error message summarizing the problem is displayed and the parent script is exited.

Basic `IS_EXCLUSIVE` functionality is summarized as follows:

| Arg 1 TYPE  | OPTIONS LIST |
|--|--|
| <empty>     | The options are mutually exclusive (only one can be specified). |
| Only One    | Only one (or none) of the options can be specified. |
| Just One    | Just one (or none) of the options must be specified. No other options are allowed. |
| Default     | Set option 1 as the default if none of option 1, option 2, ... is specified. |
| Assume      | Set option 2, option 3, ... if option 1 is used. |
| One Of      | check if exactly one of the options have been specified. |
| All Of      | check if all (or none) of the options have been specified. |
| At Least    | check if at least one of the options have been specified. |
| Only With   | Option 1 can only be used with the options specified in option 2, option 3 ... |
| Not With    | Option 1 must not be paired with any of the options specified in option 2, option 3 ... |
| Paired With | The list of options must be used together. |


Full documentation of `IS_EXCLUSIVE` can be viewed by:

```bash
functions.sh IS_EXCLUSIVE
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="example-of-get-args">Example of GET_ARGS and IS_EXCLUSIVE working together</a>

To see how `GET_ARGS` and `IS_EXCLUSIVE` work together and to see some other features we will use the `FIND-FUNCTIONS` command.

##### <a id="find-functions-hidden-option">FIND-FUNCTIONS Hidden Option</a>

`FIND-FUNCTIONS` has a hidden option `--highlight` (it is not displayed by help) that uses the `GET_ARGS_HIGHLIGHT` function.
This invokes a rather complex egrep pattern to display and highlight how `functions.sh` is used within `FIND-FUNCTIONS`.  
So type:

```bash
# There is a hidden option in FIND-FUNCTIONS to highlight itself.
# For screens that have a dark background...
FIND-FUNCTIONS --highlight
```

```bash
# The same as above but for screens with a light background...
FIND-FUNCTIONS --highlight=light
```

The result is a list of lines containing highlighted words and comments.
The table below gives a description of the lines containing highlights.

| &nbsp;&nbsp;LINE&nbsp;#&nbsp;&nbsp; | HIGHLIGHTED TEXT       | DESCRIPTION |
| :--: |--|--|
|  | Note 1:                      | The GET_ARGS function requires arguments. These are known as GET_ARGS_DIRECTIVES. They define the options allowed when executing `FIND-FUNCTIONS`. |
|  | Note 2:                      | To make it easier to see the GET_ARGS_DIRECTIVES, each is on a separate line and each line ends with the line continuation characters ` \`. |
|  | Note 3:                      | To help explain the highlighted code, I have added the line continuation characters ` \` at the end of some comments so they are included in the displayed output. |
| 4 | SCRIPT_PURPOSE              | A variable that summarizes what the script does. The value is displayed in the help output. |
| 6 | SCRIPT_VERSION              | The value of this variable is displayed if the script is invoked with option `-v` or `--version`. |
| 7-12 | Load and/or Initialize   | The bash coding that ensures `functions.sh` is loaded and/or initialized. |
| 10 | COMMON_FUNCTIONS           | Variable containing the pathname of `functions.sh`. |
| 17-54 | GET_ARGS coding         | The call to the GET_ARGS function. The following highlighted lines are GET_ARGS_DIRECTIVES.|
| 17 | `--Args_Array`             | Instructs GET_ARGS to create an array `Args` which contains the `FIND-FUNCTIONS` non-option arguments found. |
| 18 | `--Copyright`              | Causes the default copyright notice to be inserted into the help text. |
| 19-43 | `--Opt_D` `--Hid_D` `--Des_D`     | Defines and describes the `FIND-FUNCTIONS` options allowed. |
| 28  | `--Para O` | Adds an aditional paragraph at this point in the OPTIONS section |
| 31 | `--Hid_D`                  | This is like `--Opt_D` in that it defines a parent script option ``--highlight``. But this option is is not displayed by help. |
| 31 | ${`CMD`}                   | `functions.sh` creates this variable with the basename of the parent script name as the value. (Other useful variables are created as well.) |
| 44-49 | `--Where` and `--Info`  | Create the sections `WHERE` and `INFO` which provide extra information in the help display. |
| 50-53 | `--Exam`                | Creates an EXAMPLE section in the help display. |
| 54 | `--` `"$@"`                | These two arguments must always be the last of the GET_ARGS arguments. |
| 58-68 | IS_EXCLUSIVE            | These are examples of IS_EXCLUSIVE that define rules for acceptable combinations of parent script options. |
| 74 | Opt_list                   | Is a variable created if the parent script is invoked with the option `--list` or `--ListOptions`.
| 74 | Opt_list_Val               | Is the (optional) value created by using the syntax `--list=VALUE` or `--ListOptions=VALUE`.
| 74-109 | Opt_X, Opt_XXX         | When executing `FIND-FUNCTIONS` these variables are created (incremented) each time option `-X` or `--XXX` is encountered on the command line. I.E. If Opt_X tests TRUE then option `-X` was used. |
| 74-107 | Opt_X_Val, Opt_XXX_Val | At parent script execution, these variables contain the value if option `-X VALUE` or `--XXX=VALUE` was speciified. |
| 95 | E.G `(( Opt_c ))`          | If option `-c` (or `--comments`) was used then set the variable `OnlyComments` to `1`. |
| 119-126 | ${TEST_CMD}           | Causes the command line to be displayed if option `--test` (`-t`) was used. Otherwise the command is executed. Useful for testing a script. |
| 129 | ERROR                     | A function that displays the error message and immediately exits `FIND-FUNCTIONS`. |

`FIND-FUNCTIONS` has another hiddden option `--list` (it is not displayed by help) that displays a list of the generated variables and the  possibile spellings of all the options defined by GET_ARGS within the script.
Type:

```bash
FIND-FUNCTIONS --list                # Calls the GET_ARGS_LIST_OPTIONS function
```

Within the script `FIND-FUNCTIONS` you can see the coding that generates the help that is displayed by:

```bash
FIND-FUNCTIONS -H
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="ask-functions"><br>&nbsp;&nbsp;&nbsp;&nbsp;ASK Functions</a>

The basic functionality of the set of `ASK` functions (`ASK`, `ASK_GUI`, `ASK_WITH_MENU`, `ASK_WITH_MENU_GUI`)
is to display statements or questions (the prompt) to a user and to record the response.
The response can be verified against a set of acceptable responses.
In which case the `ASK` function loops until a correct response is entered or a `quit` is requested.
The first argument to `ASK` specifies the type of response expected (numeric, word, ...).
It defines both the type of response and the type of choices available.

`ASK` functionality is summarized as follows:

| FEATURE | EXPLANATION |
|--|--|
| Prompt | The prompt is fully configurable and can include a header, instructions, a legend, a list of choices or just ":&nbsp;" |
| Responses | Expected response types can be: yes or no, a number, a character (UPPER CASE, lower case, mixed case, alphanumeric or any character), a range, a word, a phrase or anything at all, |
| Choices | `ASK` verifies that the response matches the type and/or is one of the choices. |
| Verification | If it is not, `ASK` displays an error message and re-prompts for an answer. |
| Quit | `ASK` always recognizes a "quit" response (usually "q") that exits the parent script with an error code. |
| Default Answer | You can configure `ASK` to have a default result inserted for a null (empty) response. |
| Result | By default the response is placed in the variable ANSWER. The variable name can be changed.
| Muiltiple Responses | Multiple responses can be configured in which case the responses are placed in the array ANSWER. |
| 'ASK_WITH_MENU` | An extension where the "questions" are elements of an array or arguments. The elements/args become the choices available. |
| Array or Args | The array can be an indexed array, an associative array or arguments to `ASK_WITH_MENU`. Either array can be "sparse" I.E. have noncontiguous elements. |
| Selectors | From the array elements, `ASK_WITH_MENU` creates a menu with sequential number selectors or with the array indices as selectors. |
| Sorting | The selectors can be sorted a number of ways. |
| Sub-Menus | Long menus can be split into sub-menus that can be accessed with the arrow keys. |
| Muiltiple Responses | Like `ASK`, `ASK_WITH_MENU` can be configured to accept multiple responses and there is always a "quit" response. |
| Result | The results are placed in three arrays: ANSWER, ANSWER_IDX and ANSWER_VAL. The default prefix "ANSWER" can be changed. |
| GUI Dialog | The `ASK` functions can be executed with a GUI interface using `yad` to implement dialog boxes. |

Full documentation of the set of `ASK` functions can be viewed by:

```bash
FIND-FUNCTIONS -c -l "ASK.*"
```

or

```bash
functions.sh "ASK.*"
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="tmp-file-create-functions">TMP_FILE_CREATE Functions</a>

Several functions manage temporary files and directories.
Any files or directories created are automatically deleted when the parent script terminates.
Unless directed otherwise, the files/dirs are created in `/tmp`.  
The functions are summarized below.

| FUNCTION | Description |
| -------- | ----------- |
| TMP_FILE_CREATE | Create a file with a unique name and assign that name to a bash variable. |
| TMP_FILE_PERMANENT | Like TMP_FILE_CREATE but the file is not deleted at parent script termination. |
| TMP_FILE_DELETE | Delete a created file. |
| TMP_DIR_CREATE | Create a directory with a unique name and assign that name to a bash variable. |
| TMP_DIR_PERMANENT | Like TMP_DIR_CREATE but the directory is not deleted at parent script termination. |
| TMP_DIR_DELETE | Delete a created directory. |

To see the documentation for TMP_FILE_CREATE type:

```bash
functions.sh TMP_FILE_CREATE                # Display help for the function TMP_FILE_CREATE
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="examples-of-functions">Examples of Functions</a>

There are two ways you can practice using the functions.
The better way is to use the RUNME function as it also displays the result(s) from executing a function.

```bash
RUNME FUNCTION_WITH_ARGUMENTS      # The preferred way
```

RUNME is a function that operates in a subshell. It loads `<WHERE_BIN_DIR>/functions.sh` and `<WHERE_ETC_DIR>/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh` into it.
It then executes the FUNCTION_WITH_ARGUMENTS and attempts to display the contents of the variable(s) created (if any).
You can freely experiment, in an initialized environment, at the command line with the functions made available.
RUNME can also turn on bash debugging (-x) so the function can be tested.

Or, slightly less useful, by loading `functions.sh` into your environment:

```bash
FUNCTIONS                          # load `functions.sh` into your environment and set every "exit" to a "return".
FUNCTION_WITH_ARGUMENTS            # Execute the function
echo <VARIABLES_CREATED>           # Display the created variables
```

The function `FUNCTIONS` "sources" `functions.sh` and calls the function `USAGE_RETURN` (wow this sentence is certainly **_function_**al).
This changes any `exit` commands to be the command `return` so your terminal session is not closed when an error occurs.
Now you can freely experiment at the command line with the functions made available.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

### <a id="experiment">Experiment</a>

#### <a id="experiment-with-ask">Experiment with ASK</a>

The ASK function displays a question or statement and records the response in the variable `ANSWER`.
It also validates the response to determine if it is one of the acceptable choices.

Try the following `ASK TYPE` command with each of the possible response types.

| TYPE | RESPONSE EXPECTED |
|--|--|
|      | Yes or no (If TYPE is missing, -yn is the default) |
| -yn  | Yes or no |
| -n   | A number |
| -a   | An alphabetic character |
| -u   | An uppercase character |
| -l   | A lowercase character |
| -c   | Any character |
| -w   | A word. First character alphabetic or "_", the remainder alphanumeric and "_" |
| -e   | Anything at all |

```bash
# Try ASK. Enter the following replacing <TYPE> with one of the above TYPEs.
RUNME ASK <TYPE>
```

```bash
# Now, for an alphabetic response, specify a set of acceptable choices.
# Notice how to specify ranges and how the display of choices is "normalized".
RUNME ASK -a -C "A B C x-z d thru g D"
```

ASK has much more functionality. To see the full documentation type:

```bash
functions.sh ASK         # Shows (with `less`) the documentation for the `ASK` function.
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="experiment-with-ask-with-menu">Experiment with ASK_WITH_MENU</a>

Now try ASK_WITH_MENU.
It creates a menu of choices from an array (or from the arguments) and returns three variables:

| VARIABLE     | PURPOSE |
|--|--|
| `ANSWER`     | The valid response made. |
| `ANSWER_IDX` | The index into the array (or the arg) based upon the response. |
| `ANSWER_VAL` | The value of the array element (or arg) based upon the response. |

```bash
# First a simple example using arguments.
RUNME ASK_WITH_MENU Arg1 Arg2 "This is argument 3"

# The results are displayed.
```

Now try an array.
Copy the code below and paste it into your terminal command line.
Try making an invalid choice before entering a valid one.

```bash
# Setup: Create a sparse array (one with some elements missing) and initiate with 4 elements.
unset sarray ; declare -a sarray
sarray+=( [1]="Question1: sarray index=1" )
sarray+=( [9]="Question4: sarray index=9" )
sarray+=( [4]="Question2: sarray index=4" )
sarray+=( [7]="Question3: sarray index=7" )
```

```bash
# Execute ASK_WITH_MENU (with a header to make it nice)
RUNME ASK_WITH_MENU -H "\n\tMake your choice\n" sarray

# The results are displayed.
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="fancy-ask-with-menu">Fancy Sparse Arrays with ASK_WITH_MENU</a>

Again try ASK_WITH_MENU but with an associative `Array` (an array with non-numeric indices).
Also we will implement multiple answers.
Copy the code below and paste it into your terminal command line.

```bash
# Setup: Create an associative Array and initiate with 5 elements (random order).
# Note:  The array elements can contain spaces.
unset Array ; declare -A Array
Array+=( [2nd]="Question2: the index is 2nd" )
Array+=( [1st]="Question1: the index is 1st" )
Array+=( [3rd]="Question3: the index is 3rd" )
Array+=( [8th]="Question5: the index is 8th" )
Array+=( [6th]="Question4: the index is 6th" )
```

```bash
# Execute ASK_WITH_MENU with the results in variable QED and allowing multiple answers.
# Try making an invalid choice before entering a valid one.
RUNME ASK_WITH_MENU -V QED -M -H "\n\tMake your choice\n" Array
```

The results are displayed.
Notice that for an associative Array the order of the elements is non-determinant.
Add the option `-S` (before `Array`) to sort the Array indices or -S=r for a reverse sort.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;     [contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="fancy-ask-with-menu2">Fancy Multi-Menus with ASK_WITH_MENU</a>

Just for fun to see how multi-menus work, create a 20-element array named `array`.
Copy and execute the following:

```bash
# Create an associative, 20-element array with random, 1-char indices.
a=( {A..Z} {a..z} )
unset array ; declare -A array
Count=0 ; Elements=20 ; indexlen=1
while read -u 3 app ; do                   # Get names from /usr/bin/...
  unset l
  j=$(( ${SRANDOM} % ${indexlen} ))
  for (( i=0;i<=j;i++ )) ; do
    k=$(( ${SRANDOM} % ${#a[*]} ))
    l+=${a[k]}
  done
  [[ -n ${array[$l]} ]] && continue        # Ignore duplicates
  array+=( [$l]=${app} )
  (( ++Count < Elements )) || break
done 3< <(ls /usr/bin/[bB]* | sed -e 's;.*/;;')
```

The command below will split the array menu into 3 sub-menus (`-MM=3`) starting with sub-menu 2 (`-MM=3:2`).  
Run it as is. Then, in the space, add `-I` (use the indices as the selectors).  
Then add the sort option `-S` (ASCII) or `-S=n` (numeric) or `-S=nr` (numeric reversed).  
Note: `array` must be the last argument.

```bash
RUNME ASK_WITH_MENU -H "  \t${UL}Fancy Menus${DEF}" -M -MM=3:2        array
```

Now try a 30-element array named `VARRAY` of random "version" choices.
Copy and execute the following:

```bash
# Create a 30-element VARRAY with random "version-like" indices.
unset VARRAY ; declare -A VARRAY
Count=0 ; Elements=30
while true ; do
  a="$(( ${SRANDOM} % 10 ))"
  (( ${SRANDOM} % 2 == 0 )) && a=$a$a
  b="$(( ${SRANDOM} % 10 ))"
  (( ${SRANDOM} % 2 == 0 )) && b=.$b$b || b=.$b
  c="$(( ${SRANDOM} % 10 ))"
  (( ${SRANDOM} % 2 == 0 )) && c=.$c$c || c=.$c
  k="$(( ${SRANDOM} % 4 ))"
  (( k == 0 )) && unset c
  (( k == 3 )) && unset b c
  [[ -n ${VARRAY[$a$b$c]} ]] && continue            # Ignore duplicates
  VARRAY+=( [$a$b$c]="Release=$a  Major=${b:1}  Minor=${c:1}" )
  (( ++Count < Elements )) || break
done
```

And try the following command inserting combinations of: nothing, `-I` or `-I=11` and `-S=v` or `-S=vr`  
Note: `VARRAY` must be the last argument.

```bash
RUNME ASK_WITH_MENU -H "\t\t${UL}Fancy Menus${DEF}" -M -MM=3       VARRAY
```

Finally try any of the above in a GUI environment (by adding `-G`) and with a default response (using `-D <X>`).

```bash
RUNME ASK_WITH_MENU -V QED -M -D "*" -G -H "A GUI Example\n\tMake your choice\n" array
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="experiment-with-other-functions">Experiment with Some Other Functions</a>

There are many functions available within `functions.sh`.
The following examples show some of the capability available.

#### <a id="color-functions">COLOR Functions</a>

The functions related to colors are interesting. Try:

```bash
# Display the function names containing "COLOR"
FIND-FUNCTIONS -f '.*COLOR.*'
```

```bash
# Display the comments (help) for the COLOR functions
FIND-FUNCTIONS -c -l ".*COLOR.*"
```

```bash
# Now display the code
FIND-FUNCTIONS -l ".*COLOR.*"
```

```bash
# See the built-in colors
RUNME COLORS_DISPLAY
```

```bash
echo -e "\nExample of 'echo' using a color: A ${UL}book${DEF} that is ${GRN}read${DEF} doesn't have to be ${RED}red${DEF}.\n"
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="error-warning">ERROR & WARNING</a>

Errors and warnings can be used as follows.
Note: Normal operation of `ERROR` forces immediate exit from the parent script

```bash
RUNME ERROR "This is an error message.\nThe error is..."
```

```bash
RUNME WARNING "This is a warning message.\nThe correct..."
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="padit-trim-zerofill">PAD_IT, TRIM & ZERO_FILL</a>

The next three functions deal with spaces and zeros surrounding a string.

```bash
# Help for the three functions: PAD_IT TRIM ZERO_FILL
functions.sh PAD_IT TRIM ZERO_FILL
```

```bash
# Padding left justified (the default), 6 charaters
RUNME PAD_IT -V RESULT -L 6 "abc"
```

```bash
RUNME PAD_IT -V RESULT -L 15 -P "HO " "Santa: "
```

```bash
# Padding right justified, 9 characters
RUNME PAD_IT -RJ -V RESULT -L 9 abc
```

```bash
# Trim surrounding whitespace
RUNME TRIM -V RESULT  "   abc def   "
```

```bash
# Trim (-L) the whitespace on the left
RUNME TRIM -V RESULT -L "   abc def   "
```

```bash
# Trim (-R) the whitespace on the right
RUNME TRIM -V RESULT -R "   abc def   "
```

```bash
# Zero fill on the left
RUNME ZERO_FILL -V RESULT -L 6 123
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)


#### <a id="pause">PAUSE</a>

The function `PAUSE` is a simple way to "wait and continue".

```bash
# View the documentation
FIND-FUNCTIONS -c PAUSE
```

```bash
RUNME PAUSE "\nAn easy way for the program to wait for user input before continuing.\n\t"
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="progress">PROGRESS</a>

The function `PROGRESS` can be used within a loop to indicate your script is 'thinking'.
It displays (on /dev/stderr) a dot "." every time it is executed.

```bash
# View the documentation
FIND-FUNCTIONS -c PROGRESS
```

The following is an example of how PROGRESS could be used.

```bash
PROGRESS 2                            # Setup to display "." every 2 iterations
echo -n "Processing your request. Please wait: "
for (( i=1 ; i<=10 ; i++ )) ; do      # A 10-times loop
  sleep 0.5                           # Simulate "work"
  PROGRESS                            # PROGRESS without arguments implements the "." counter
done
echo -e "\nFinished."
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="functionsexample">FUNCTIONS</a>

If you make changes to `functions.sh` and want to test it out then, before you test, execute the following:

```bash
# Reload `functions.sh` into the environment
FUNCTIONS
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

#### <a id="sort-args-ws">SORT_ARGS & SORT_ARGS_WS</a>

`SORT_ARGS` acts like its name: it sorts the arguments.
The only restriction is no argument can contain whitespace.
In simple form...

```bash
RUNME SORT_ARGS ddd ggg qwqq aaa ccc bbb zzz jjj
```

Now see what happens to an argument with whitespace.
We display the results line-by-line with -L.

```bash
RUNME SORT_ARGS -L 'gg g' 'dd d' 'qw qq' 'a aa'
```

The same as above but using `SORT_ARGS_WS`.

```bash
RUNME SORT_ARGS_WS -L 'gg g' 'dd d' 'qw qq' 'a aa'
```

Suppose you have an array of file names all of which contain a number.
And you want to sort them in reverse number order.
The function `SORT_ARGS_WS` is needed to do this as the "names" in this example contain whitespace.
But be aware it is more expensive processing wise than `SORT_ARGS`.

First an explanation of the arguments to the `SORT_ARGS_WS` examples below.

| ARGUMENT | EXPLANATION |
|--|--|
| -V SORTED_NAMES | Store the result into the variable SORTED_NAMES. |
| -A | And make it an array. |
| -S "-n -r -t- -k2,2" | Pass options to the `sort` command<br>-n&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A numeric sort.<br>-r&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Sort in reverse order.<br>-t-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The field separator is "-"<br>-k2,2&nbsp;Sort on the second field |
| `${FILE_NAMES_ARRAY[@]}` | The contents of the file-name array (requoted) as the remaining arguments. |

```bash
# Create the array of file names.
FILE_NAMES_ARRAY=( "my file-11" file-20 "our file-10" file-2 "new file-1.x" file-3 file-30 )
```

```bash
# The simple case. Just sort by file name.
RUNME SORT_ARGS_WS -V SORTED_NAMES -A "${FILE_NAMES_ARRAY[@]}"
```

```bash
# Now sort by the number in the name and in decreasing order.
RUNME SORT_ARGS_WS -V SORTED_NAMES -A -S "-n -r -t- -k2,2" "${FILE_NAMES_ARRAY[@]}"
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

-----------------------------

## <a id="bugs">Bugs</a>

#### Definition

A Pandora's box of nasty little Boggarts hiding in your code just waiting to pop up with a knowing grin.  
Removing one seems to invite friends and relations to the party.

Where would Linux be if there weren't any bugs or unfinished business?

#### Limited Usefulness

Because I wrote these functions and scripts for my personal use, the following may not be useful or may have to be modified for your "setup".

| THINGS THAT DEPEND UPON MY SETUP |
|--|
| Any function using `/etc/fstab` |
| The `MOUNT` function uses preset directories and system links in `/media` |
| The variables `All_PCS` and `OTHER_PCS` are related to my internal DNS |
| The network functions in general are based upon my internal DNS |

#### Specifics

| WHAT | WHY |
|--|--|
| `GET_IP_FROM_DOMAIN` | Minimum usefulness |
| `GET_MATCHING_NFS_DOMAIN_IN_FSTAB` | Ditto |
| `GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB` | Ditto |
| ... | ... |

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[top](#top)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[contents](#contents)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[bottom](#bottom)

<a id="bottom"></a>
