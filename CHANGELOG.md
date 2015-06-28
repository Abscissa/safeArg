safeArg - ChangeLog
===================

(Dates below are YYYY/MM/DD)

v0.9.6 - 2015/06/27
-------------------
- **Enhancement:** Add ```--verbose|-v``` to echo the generated command to stdout before running.

v0.9.5 - 2015/06/15
-------------------
- **Fixed:** Correctly pass-thru all options after program_to_run, instead of mistakenly trying to process them.
- **Fixed:** Fix a build issue for dub projects with a dependency on safearg by updating minimum gen-package-version to v0.9.3.

v0.9.4 - 2015/06/14
-------------------
- **Fixed:** Build failure for projects depending on safeArg (gen-package-version was run from wrong directory).

v0.9.3 - 2015/06/14
-------------------
- **Enhancement:** Allow extra "initial-arguments" to be specified on the command line (ex: ```safearg echo -n < WHATEVER```).
- **Enhancement:** Add ```--post|-p``` for "post"-arguments to be added to the *end* of the command line.

v0.9.2 - 2015/06/14
-------------------
- **Enhancement:** Use ```--newline|-n``` to delimit with newlines (both \n and \r\n) instead of \0.
- **Enhancement:** Use ```--delim=VALUE``` to use custom one-byte delimiter instead of \0.
- **Enhancement:** Auto-generated version number shown in help screen, and via new ```--version``` flag.
- **Change:** Cleaned up internal directory structure.
- **Change:** Documentation improvements, including changelog and license files.

v0.9.1 - 2015/06/09
-------------------
- Minor documentation fixes.

v0.9.0 - 2015/06/09
-------------------
- Initial version.
