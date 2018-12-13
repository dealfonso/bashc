# bashc
A simple framework to ease the development of bash applications.

Other programming languages (e.g. python, perl, C, etc.) have libraries that ease common tasks. bashc is a framework that enables to have **libraries of bash functions** instead of forcing the programmer to develop ad-hoc solutions. These libraries can be used in your bash scripts, by including them in common bash scripts, and _somehow compiling_ the scripts into a **re-distributable and library independent** one.

**What includes**
- For **code re-usage**, a library of **common functions** in bash (e.g. `is_int`, parameter parsing, `readconffile`, `trim`, `in_list`, etc.).
- To **ease re-distribution**, a _compiler-like_ application that makes a **single bash script** out of multiple scripts that are included using the `source` statement.
- To **reduce the size** of the scripts, a _removal of unused functions_ tool that enables to include all the libraries, but only redistribute those functions that are used.
- To create **packages for re-distribution**, `bashcbuild` that is a package builder that eases the **creation of simple rpm and deb packages**.
- To **ease starting a new application**, `bashcgen` that is an application that creates a new application from a template folder (including a customizable folder tree, customizable files, etc.).

The functions work for the library, but also for any other bash script. So, you can use applications such as `bashc`, `bashcbuild` and `bashcgen` but not use any function in the library. E.g. you can create your own library of functions and use `bashc` to generate a single script and to remove the unused functions, or you can create your own template for `bashcgen` to create (e.g.) _NodeJS_ base applications.

## Installing

You can get `bashc` in source form, or in one of the [packages](https://github.com/dealfonso/bashc/releases).

### Packages

**Ubuntu**

```
$ apt install -y ./bashc_0.9-rc1.deb
$ bashc --version
0.9-rc1
```

**CentOS**

```
$ yum install -y ./bashc-0.9-rc1.noarch.rpm
$ bashc --version
0.9-rc1
```

> This version do not support the creation of deb packages. You can use [FPM](https://github.com/jordansissel/fpm) to create the deb package from the rpm package.

**Other distro**
```
$ tar xfz bashc_0.9-rc1.tar.gz -C / --strip-components=1
$ bashc --version
0.9-rc1
```

> In this case, you will need to solve the dependencies.

### Source

Use the code without the need of installing:

```
$ git clone https://github.com/dealfonso/bashc
$ cd bashc
$ ./bashc --version
0.9-rc1
```

## Why `bashc`?

bash scripting is a powerful language to develop **applications that manage servers**, but also to **automate processes** in Linux, to execute **batch tasks**, or to other tasks that can be executed in the **Linux commandline** e.g. implement workflows in scientific applications (processing the output from one application to prepare it for other application).

The **immediate use of bash scripting is to automate scripts**, but there are a lot of applications and **tools in the commandline that are powerful** enough and easy to use to have the need to use other languages such as _python_, _perl_, etc. that will have harder to learn just to implement workflows of other tools. 

When you start accepting parameters in the commandline, and you want to make checks of the results (to create better tools), etc. **you need common functions** as the other languages have.

**bashc** solves that problem by enabling to have **libraries of bash functions** that can be re-used in your bash scripts.

**Example of a typical bash script**
```
#!/bin/bash
execute_app > myoutput
sed -i 's/.../g' myoutput
RESULT=`execute_otherapp < myoutput`
echo $RESULT
...
```

The problem happens when you need to get options from the commandline, sanitize these options, make checks between in the outputs, etc.

**Example of the same script with parameters**
```
#!/bin/bash
while [ $# -gt 0 ]; do
  case $1 in
    --debug|-d)   DEBUG=1;;
    --output|-o)  shift
                  OUTPUTFILE=$1;;
    *)  echo "error" >&2
        exit 1;;
  esac
  shift
done
execute_app > $OUTPUTFILE
sed -i 's/.../g' $OUTPUTFILE
RESULT=`execute_otherapp < $OUTPUTFILE`
if [[ "$1" =~ ^[+-]{0,1}[0-9]+$ ]]; then
  echo "the result is a number"
else
  echo "error"
fi
```

> Using that script you cannot manage parameters constructions such as `-do <ouput file>`.

**Example of the same script using bashc**
```
#!/bin/bash
source all.bashc

bashc.parameters_start
while bashc.parameters_next; do
  PARAM="$(bashc.parameters_current)"
  case "$PARAM" in
    --debug|-d)   DEBUG=1;;
    --output|-o)  shift
                  OUTPUTFILE=$1;;
    *)            usage && bashc.finalize 1 "invalid parameter $PARAM";;
  esac
done

execute_app > $OUTPUTFILE
sed -i 's/.../g' $OUTPUTFILE
RESULT=`execute_otherapp < $OUTPUTFILE`

if is_int "$RESULT"; then
  echo "the result is a number"
else
  echo "error"
fi
```

The ad-hoc bash script is **hard to read for maintaining the code**. E.g. what means `[[ "$1" =~ ^[+-]{0,1}[0-9]+$ ]]`? Or how can I implement parameters constructions such as `-do <ouput file>`?

The bashc script is easier to understand and **easier to maintain** in the future.

## Use case

We'll start a new application using `bashcgen`...

```
root@95b847d5cbaa:~# bashcgen myapp
application myapp created in folder ./myapp
root@95b847d5cbaa:~# cd myapp/
root@95b847d5cbaa:~/myapp# ls -l
total 16
drwxr-xr-x 3 root root 4096 Sep  6 12:42 etc
-rwxr-xr-x 1 root root 2349 Sep  6 12:42 myapp.bashc
-rw-r--r-- 1 root root  488 Sep  6 12:42 myapp.bashcbuild
-rw-r--r-- 1 root root   13 Sep  6 12:42 version
```

The code for the new app is the next:
```bash
#!/bin/bash
function usage() {
  cat <<EOF

This is a template for a bash application

myapp <appname>

  --version | -V            Shows the version number and finalizes.
  --verbose | -v            Shows more information about the procedure.
  --debug                   Shows a lot more information about the procedure.
  --help | -h               Shows this help and exits.
EOF
}

function verify_dependencies() {
  if false; then
    bashc.finalize 1 "dependency failed"
  fi
}

# The list of default configuration files (it is set here just in case that you want to change it in the commandline)
CONFIGFILES="/etc/default/myapp.conf /etc/myapp/myapp.conf /etc/myapp.conf $HOME/.myapp etc/myapp.conf etc/myapp/myapp.conf"

# The basic include than gets all from bashc (you should use -S flag to remove the unused functions)
source all.bashc

# A include for the version of this application
source version

# Parse the commandline into an array
bashc.parameter_parse_commandline "$@"

bashc.parameters_start
while bashc.parameters_next; do
  PARAM="$(bashc.parameters_current)"
  case "$PARAM" in
    --verbose|-v)           VERBOSE=true;;
    --debug)                DEBUG=true;;
    --help | -h)            usage && bashc.finalize;;
    --version|-V)           p_out "$VERSION"
                            bashc.finalize 0;;
    *)                      usage && bashc.finalize 1 "invalid parameter $PARAM";;
  esac
done

# You should check this function to include the checks for the dependencies of your bash application
verify_dependencies

# Read the variables from the configuration files
bashc.readconffiles "$CONFIGFILES" VAR_myapp

# Now you have to implement your app
p_out "wellcome to myapp, I got the value ${VAR_myapp} for var VAR_myapp from the config file"
```

The application is fully working, but by now you need to run it using `bashc`:

```
root@95b847d5cbaa:~/myapp# ./myapp.bashc 
./myapp.bashc: line 43: all.bashc: No such file or directory
./myapp.bashc: line 49: bashc.parameter_parse_commandline: command not found
./myapp.bashc: line 51: bashc.parameters_start: command not found
./myapp.bashc: line 52: bashc.parameters_next: command not found
./myapp.bashc: line 68: bashc.readconffiles: command not found
./myapp.bashc: line 71: p_out: command not found
root@95b847d5cbaa:~/myapp# bashc myapp.bashc --version
0.0-0
```

The application is even able to read variables from its config file

```
root@95b847d5cbaa:~/myapp# bashc myapp.bashc
wellcome to myapp, I got the value false for var VAR_myapp from the config file
```

Now you can "compile" the application into a single independent script, and then the application will be independent from `bashc`:

```
root@95b847d5cbaa:~/myapp# bashc -cS myapp.bashc -o myapp
root@95b847d5cbaa:~/myapp# chmod +x myapp
root@95b847d5cbaa:~/myapp# ./myapp
wellcome to myapp, I got the value false for var VAR_myapp from the config file
```

## Building packages with `bashcbuild`
Sometimes you have very simple pieces of code that are likely to be re-distributed. The structure of the code is very simple, but if you want to create deb or rpm packages, you need to learn the structure of them

`bashcbuild` is a very straightforward package builder that is suitable for simple packages such as those that consist in bash scripts.

**example**

to create a package that has a /etc/myapp/myapp.conf and a binary that is located in /usr/bin/myapp, you simply have to create the next file:

```
PACKAGE=myapp
/etc/$PACKAGE/;etc/myapp/myapp.conf
/usr/bin/;myapp
```

And run the next command:

```
# bashcbuild myapp.bashcbuild --deb --rpm
[WARNING]  2018.09.06-14:09:36 information about version not included (i.e. VERSION variable in package descriptor). Using 0.0 as the version number.
/root/myapp/myapp_0.0-0.tar.gz successfully created
/root/myapp/myapp-0.0-0.noarch.rpm successfully created
/root/myapp/myapp_0.0-0.deb successfully created
```

Then you can verify the contents of the packages:

```
$ tar tf myapp_0.0-0.tar.gz 
myapp-0.0/
myapp-0.0/etc/
myapp-0.0/etc/myapp/
myapp-0.0/etc/myapp/myapp.conf
myapp-0.0/usr/
myapp-0.0/usr/bin/
myapp-0.0/usr/bin/myapp
$ dpkg-deb -c myapp_0.0-0.deb 
drwxr-xr-x root/root         0 2018-09-06 14:09 ./
drwxr-xr-x root/root         0 2018-09-06 14:09 ./etc/
drwxr-xr-x root/root         0 2018-09-06 14:09 ./etc/myapp/
-rw-r--r-- root/root        87 2018-09-06 14:09 ./etc/myapp/myapp.conf
drwxr-xr-x root/root         0 2018-09-06 14:09 ./usr/
drwxr-xr-x root/root         0 2018-09-06 14:09 ./usr/bin/
-rwxr-xr-x root/root      8711 2018-09-06 14:09 ./usr/bin/myapp
$ rpm -qlp ./myapp-0.0-0.noarch.rpm 
/etc/myapp/myapp.conf
/usr/bin/myapp
```

# Library

The functions that are included in the library
**(list in progress)**

**Configuration files**
- `bashc.readconf` reads configuration variables from a string and exports them. Supports quotes and double quoted parameters, comments, etc.
- `bashc.readconffile` reads configuration variables from a file (see also `bashc.readconf`).
- `bashc.readconffiles` reads configuration variables from a set of files (see also `bashc.readconf` and `bashc.readconffile`).
- `bashc.cleanvalue` reads the value for a variable from a string.

**Logging and output**
- `p_out`: outputs a string to the stdout (as is).
- `p_debug`: outputs a string to stderr and tags it with the timestamp as debug info (if _DEBUG_ var is set to true).
- `p_error`: outputs a string to stderr and tags it with the timestamp as error info.
- `p_warning`: outputs a string to stderr and tags it with the timestamp as warning info.
- `p_info`: outputs a string to stderr and tags it with the timestamp as verbose info (if _DEBUG_ or _VERBOSE_ vars are set to true).
- `p_mute`: mutes debug, warning, etc. info that fulfil a regular expressions.
- `p_errfile`: outputs a string to stderr or to the file in LOGFILE variable.
- `bashc.set_logger`: sets the prepended string to `p_*` functions.
- `bashc.push_logger`: adds a logger info to the prepended info to the `p_*` functions.
- `bashc.pop_logger`: remove a logger info to the prepended info to the `p_*` functions.
- `bashc.finalize`: finalizes the execution of the current script, with an error code and (optional) outputs some information.

**Parameter parsing**
- `bashc.parameter_parse_commandline`: prepares the commandline to be parsed.
- `bashc.parameters_start`: goes to the first parameter.
- `bashc.parameters_next`: advances to the next parameter.
- `bashc.parameters_end`: checks whether there are more parameters or not.
- `bashc.parameters_current`: returns the current parameter.

**Temporary files**
- `bashc.tempfile`: creates a temporary file.
- `bashc.tempdir`: creates a temporary folder.

**Utility functions**
- `bashc.trim`: remove leading and trailing blank spaces from a string.
- `bashc.ltrim`: remove leading blank spaces from a string.
- `bashc.rtrim`: remove trailing blank spaces from a string
- `bashc.build_cmdline`: builds a quoted commandline from the parameters to the function.
- **deprecated** `bashc.dump_list`: (please use `bashc.dump_in_lines`) dumps the list of parameters and prepends its position.
- `bashc.parameters_to_list`: converts a set of parameters to the function, to an array.
- `bashc.list_append`: adds a value to the end of an array.
- `bashc.in_list`: checks whether a value is in an array or not.
- `bashc.is_int`: checks if a string is a integer.
- `bashc.arrayze_cmd`: creates an array of parameters from a commandline string.
- `bashc.lines_to_array`: converts a set of lines to an array.
- `bashc.cleanfile`: removes blank lines, bash-like comments, trailing and leading spaces from a string.
- `bashc.dump_in_lines`: dumps the list of parameters and prepends its position.
- `bashc.dump_vars`: dumps the value of the variables passed as parameters.
- `bashc.expand_ranges`: expand ranges in strings such as `myrange[0-2]` into `myrange0, myrange1, myrange2` (it also support ranges of characters and reverse order).