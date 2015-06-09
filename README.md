safeArg - Pass a null-delimited list of command line args to a program
======================================================================

[Changelog](https://github.com/Abscissa/safeArg/blob/master/CHANGELOG.md)

Using eval or command substitution to pass arguments to a program is error-prone, non-portable and a potential security risk:

- Error-Prone: Proper shell quoting/escaping rules can be complex and confusing. Ignoring proper quoting/escaping can cause your program to fail (or worse) on certain inputs (such as filepaths with spaces, or multi-line data).

- Non-Portable: Posix platforms and Windows have completely different shells, and not all Windows machines have a Posix-style shell installed. Even the various Posix shells may have differences, and knowing whether you're relying on an extension-specific feature isn't always obvious.

- Potential Security Risk: Specially-constructed arguments can give an attacker full shell access.

A [recommended solution](http://stackoverflow.com/questions/30720364/honoring-quoting-in-reading-shell-arguments-from-a-file)
is to use a null-delimited stream for sending the output of one command to the command line of another. This completely bypasses the shell's command parsing, and thus can avoid the problems above. Unfortunately, using the shell to actually send a null-delimited stream of arguments to a program can still be non-trivial and platform-specific, so this cross-platform tool helps you out:

```bash
$ safearg program_to_run < INPUT
```

For example (Granted, this example is using tools that aren't built-in on Windows, but it's only an example for illustration. Safearg itself is cross-platform, and sticking to only cross-platform tools would still work fine):
```bash
$ printf "[%s]\n" abc 'hello world'       # Let's try doing this
[abc]
[hello world]

$ echo abc \'hello world\' >datafile      # Store in file: abc 'hello world'
$ printf "[%s]\n" $(<datafile)            # Fails?! Plus, it's a security risk :(
[abc]
['hello]
[world']

$ echo -n '[%s]\n' >datafile              # Send printf's first arg to datafile
$ printf "\0abc\0hello world" >>datafile  # Append next two args: \0abc\0hello world
$ safearg printf <datafile                # Works!
[abc]
[hello world]
```

Compiling
---------

With [DUB](http://code.dlang.org/getting_started) (requires an installed [D](http://dlang.org) compiler):
```bash
$ dub build
```
