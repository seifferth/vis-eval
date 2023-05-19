# Vis Eval

This is a simple plugin for [vis](https://github.com/martanne/vis) that
allows evaluating markdown code blocks using arbitrary shell commands.
Code blocks are assumed to be surrounded by lines starting with three
backticks like this:

    ```python
    print("Hello World!")
    ```

The starting line of a code block must contain the name of an interpreter
to use for evaluating the code block. (If a line contains nothing but
three backticks, this plugin will assume that it is the closing rather
than an opening delimiter of a code block.) To evaluate the closest of
these code blocks preceding the primary cursor, once the plugin is loaded,
simply type `g<Enter>` when in normal mode. The closest code block is
always the one whose starting line is the first one encountered when
looking up in the file from the current primary cursor position. It is
thus possible to evaluate a code block both by placing the cursor inside
and by placing the cursor after that code block.

By default, the contents of this code block are provided to the command
specified as the interpreter name on stdin. Whatever that command produces
on stdout will be added immediately below the code block like this:

    ```python
    print("Hello World!")
    ```
    ::: {.output exit_code="0"}
        Hello World!
    :::

If a markdown div starting with `::: {.output` is located immediately
beneath the code block being evaluated, eval.lua will remove this div
before adding the new output. The exit_code parameter shows which exit
code the command returned.

In theory, any kind of shell command can be specified as an interpreter
name. Arguments to that command can be specified by using the same
syntax one would use in a normal shell command. Since most markdown
processors assume the string following the opening delimiter to be the
name of a syntax highlighting scheme, specifying an actual shell command
in its place may at times be somewhat inconvenient. This plugin therefore
includes a facility to map interpreter names to actual shell commands. To
use the `python3` executable to execute code tagged simply as `python`,
you could run the following command to set up that mapping:

    :evalmap python python3

To run `sqlite3 -bail -column /path/to/some/db` for evaluating code
tagged simply as `sql`, use

    :evalmap sql sqlite3 -bail -column /path/to/some/db

These mappings can also be made persistent by including lines like the
following ones in your `visrc.lua`:

    evalmap('python', 'python3')
    evalmap('sql', 'sqlite3 -bail -column /path/to/some/db')

Since hanging shell commands can be a great nuisance when their execution
makes your text editor block, commands are always executed with a timeout.
By default, this timeout is set to two seconds, which should be long
enough to execute most code blocks and still short enough to not make
the user feel like their text editor has just frozen up for good. To
adjust this timeout, simply use the following command:

    :set evaltimeout N

Where N is the number of seconds to wait for the command to complete.

## Installing

To use this plugin, simply copy `eval.lua` to `~/.config/vis/` and then
add the following line to `visrc.lua`:

    require('eval')

Further information about vis plugins can be found at
<https://github.com/martanne/vis/wiki/Plugins>.
