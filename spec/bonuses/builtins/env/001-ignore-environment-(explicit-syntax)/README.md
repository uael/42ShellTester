# 001-ignore-environment-(explicit-syntax)

*[spec > bonuses > builtins > env](..) > 001-ignore-environment-(explicit-syntax)*

The purpose of this test is to check the implementation of the option `-i` with the explicit syntax `--ignore-environment`.
We are using a binary which have to display environment variable. But we a launching this binary with env -i, the output is suppose to be empty.
### Shell commands that are sent to the standard entry

```bash
env --ignore-environment ./display_env

```

### What is expected on standard output

```bash
expected_to have_nb_of_lines 2
expected_to match_regex "START DISPLAYING ENVIRONMENT VARIABLES$"
expected_to match_regex "END DISPLAYING ENVIRONMENT VARIABLES$"

```

### What is expected on error output

```bash
expected_to be_empty
```

### Variables

The following variables may appear in this test:

* ${**GLOBAL_INSTALLDIR**} -> The installation directory of 42ShellTester
* ${**GLOBAL_TMP_DIRECTORY**} -> The temporary directory in which tests are executed
* ${**GLOBAL_TOKEN**} -> A token that changes value at launch time
* ${**PATH**} -> The standard environment variable PATH
* ${**HOME**} -> The standard environment variable HOME

### Support binaries

The following binaries may appear in this test:


* **./display_env** -> A binary that iterates on `**envp` and write each element on standard output.
* **./display_program_name** -> A binary that writes its name on standard ouput.
* **./display_pwd** -> A binary that writes on standard output the absolute path of the current directory returned by `getcwd(3)`, encountered with the strings `PWD:` and `:PWD`.
* **./exit_with_status** -> A binary that immediately exits with the status given as first argument.
* **./read_on_stdin** -> A binary that reads on standard entry and write each line on standard output suffixed with the character `@` (e.g. same behavior as `cat -e` and the *newline* character). When `read(2)` returns `-1`, then the string `STDIN READ ERROR` is written on standard error.
* **./sleep_and_write_on_stderr** -> A binary that sleeps for a duration in seconds given as first argument and then writes on STDERR the string given as second argument without EOL.
* **./write_on_stderr** -> A binary that writes on standard error the first given argument (the same behavior as `echo` but with only one argument) and exits with an error status code given as second argument. If no argument is given, it writes the string "write on stderr" and exit with status `1`.
* **./write_on_stdout** -> A binary that writes on standard output the first given argument (the same behavior as `echo` but with only one argument). If no argument is given, it writes the string "write on stdout".
* **./write_on_stdout_and_stderr** -> A binary that writes on standard output the first given argument, and writes on standard error the second given argument. If an argument is missing, it writes the strings "write on stdout" and "write on stderr".