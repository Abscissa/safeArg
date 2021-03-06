safeArg - Pass a null-delimited list of command line args to a program
======================================================================

[ [Changelog](https://github.com/Abscissa/safeArg/blob/master/CHANGELOG.md) ]

Using eval or command substitution to pass arguments to a program is error-prone, non-portable and a potential security risk:

- Error-Prone: Proper shell quoting/escaping rules can be complex and confusing. Ignoring proper quoting/escaping can cause your program to fail (or worse) on certain inputs (such as filepaths with spaces, or multi-line data).

- Non-Portable: Posix platforms and Windows have completely different shells, and not all Windows machines have a Posix-style shell installed. Even the various Posix shells may have differences, and knowing whether you're relying on an extension-specific feature isn't always obvious.

- Potential Security Risk: Specially-constructed arguments can give an attacker full shell access.

A [recommended solution](http://stackoverflow.com/questions/30720364/honoring-quoting-in-reading-shell-arguments-from-a-file)
is to use a null-delimited stream for sending the output of one command to the command line of another. This completely bypasses the shell's command parsing, and thus can avoid the problems above. Unfortunately, using the shell to actually send a null-delimited stream of arguments to a program can still be non-trivial and platform-specific, so this cross-platform tool helps you out:

```bash
$ safearg program_to_run [initial-arguments] < INPUT
```

For example (Granted, this example is using tools that aren't built-in on Windows, but it's only an example for illustration. Safearg itself is cross-platform, and sticking to only cross-platform tools would still work fine):
```bash
$ printf "[%s]\n" abc 'hello world'     # Let's try doing this
[abc]
[hello world]

$ echo abc \'hello world\' >datafile    # Store in file: abc 'hello world'
$ printf "[%s]\n" $(<datafile)          # Fails?! Plus, it's a security risk :(
[abc]
['hello]
[world']

$ printf "abc\0hello world" >datafile   # Store in file: abc\0hello world
$ safearg printf '[%s]\n' <datafile     # Works!
[abc]
[hello world]
```

Compiling
---------

With [DUB](http://code.dlang.org/getting_started) (requires an installed [D](http://dlang.org) compiler):
```bash
$ dub build
```

Usage
-----

View this with ```safearg --help``` or ```dub run safearg -- --help```

```
Takes a null-delimited list of args on stdin, and passes them as command line
arguments to any program you choose.

This is more secure, less error-prone, and more portable than using the shell's
command substitution or otherwise relying on the shell to parse args.

USAGE:
safearg [options] program_to_run [initial-arguments] < INPUT

INPUT:
A null-delimited (by default) list of command line arguments to app.

EXAMPLE:
    printf 'mid1\0mid2' | safearg --post=end1 --post=end2 program_to_run first

    The above (effectively) runs:
    program_to_run first mid1 mid2 end1 end2

EXAMPLE:
    printf 'middle 1\0middle 2' | safearg --post=end printf '[%s]\n' first

    The above (effectively) runs:
    printf '[%s]\n' 'middle 1' 'middle 2' end

    And outputs:
    [first]
    [middle 1]
    [middle 2]
    [end]

OPTIONS:
-n --newline Use \n and \r\n newlines as delimiter instead of \0
     --delim Use alternate character as delimiter instead of \0 (ex: --delim=,)
-p    --post Extra "post"-args to be added at the end of the command line.
-v --verbose Echo the generated command to stdout before running.
   --version Show safearg's version number and exit
-h    --help This help information.
```

Differences from xargs -0
-------------------------

The Posix xargs tool has a ```-0``` flag that can do accomplish the same task as safeArg. But there some differences:

- The command-line interfaces are different.
- **xargs:** Has more features. **safeArg:** Simpler.
- **xargs:** Defaults are constrained by legacy compatibility. **safeArg:** Defaults have been rethought and chosen based on safety and reliability.
- **xargs:** Null-delimited *isn't* the default. **safeArg:** Null-delimited *is* the default.
- **xargs:** If the argument list is long, automatically splits it into multiple invokations of the command (by default). This may or may not be appropriate, depending on the command). **safeArg:** Does not support splitting the argument list into multiple invocations. Leaves that up to an external tool.
- **xargs:** There are some rare systems where ```-0``` isn't supported.
- **xargs:** Built-in on nearly every Posix machine. Can be obtained for Windows, but is rarely installed. **safeArg:** Not built-in on any system, but obtaining it is exactly the same regardless of platform.
- **xargs:** Built-in limits on command length, to match the OS environment. **safeArg:** No built-in limits (you may or may not still be constrained by your OS, but the shell interpreter's limits are bypassed).
