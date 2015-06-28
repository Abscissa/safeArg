module safearg.main;

import std.algorithm;
import std.array;
import std.conv;
import std.getopt;
import std.process;
import std.range;
import std.stdio;
import std.traits;

import scriptlike.fail;
import safearg.packageVersion;

immutable helpBanner =
`safeArg `~packageVersion~`: <https://github.com/Abscissa/safeArg>
Built on `~packageTimestamp~`
-----------------------------------------------------
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

OPTIONS:`;

bool useNewlineDelim = false;
string alternateDelim = null;
string[] postArgs = null;
bool verbose = false;

// Returns: Should program execution continue?
bool doGetOpt(ref string[] args)
{
	immutable usageHint = "For usage, run: safearg --help";
	bool showVersion;
	
	try
	{
		auto helpInfo = args.getopt(
			std.getopt.config.stopOnFirstNonOption,
			"n|newline", `Use \n and \r\n newlines as delimiter instead of \0`, &useNewlineDelim,
			"delim",     `Use alternate character as delimiter instead of \0 (ex: --delim=,)`, &alternateDelim,
			"p|post",    `Extra "post"-args to be added at the end of the command line.`, &postArgs,
			"v|verbose", "Echo the generated command to stdout before running.", &verbose,
			"version",   "Show safearg's version number and exit", &showVersion,
		);

		if(helpInfo.helpWanted)
		{
			defaultGetoptPrinter(helpBanner, helpInfo.options);
			return false;
		}
	}
	catch(GetOptException e)
		fail(e.msg ~ "\n" ~ usageHint);
	
	if(showVersion)
	{
		writeln(packageVersion);
		return false;
	}
	
	if(alternateDelim.length > 1)
		fail("Value for --delim=VALUE must be only byte\n" ~ usageHint);
	
	if(useNewlineDelim && alternateDelim)
		fail("Cannot use both --newline and --delim=VALUE\n" ~ usageHint);
	
	if(args.length < 2)
		fail("Missing program to run\n" ~ usageHint);
	
	return true;
}

version(unittest) void main() {} else
int main(string[] args)
{
	// Handle our own args
	if(!doGetOpt(args))
		return 0;
	
	// Parse input
	string[] outArgs;
	auto inputRange = stdin.byChunk(1024).joiner();

	if(useNewlineDelim)
		outArgs = parseNewlineDelimited(inputRange);
	else if(alternateDelim)
		outArgs = parseDelimited(inputRange, cast(const(ubyte)) alternateDelim[0]);
	else
		outArgs = parseNullDelimited(inputRange);
	
	// Build and echo command
	string[] cmd = args[1..$] ~ outArgs ~ postArgs;
	if(verbose)
		stdout.rawWrite(escapeShellCommand(cmd)~"\n");

	// Invoke command
	try
		return spawnProcess(cmd).wait();
	catch(ProcessException e)
	{
		fail(e.msg);
		assert(0);
	}
}

string[] parseNullDelimited(T)(T inputRange)
	if(isInputRange!T && is(ElementType!T == ubyte))
{
	return parseDelimited(inputRange, cast(const(ubyte)) '\0');
}

string[] parseNewlineDelimited(T)(T inputRange)
	if(isInputRange!T && is(ElementType!T == ubyte))
{
	return parseDelimited(inputRange, cast(const(ubyte)) '\n', true, cast(const(ubyte)) '\r');
}

string[] parseDelimited(T)(T inputRange, const ubyte delim, bool useLookBehind=false, const ubyte lookBehind=ubyte.init)
	if(isInputRange!T && is(ElementType!T == ubyte))
{
	string[] result;
	ubyte prevByte;
	size_t length = 0;
	auto buf = appender!(ubyte[])();

	foreach(dataByte; inputRange)
	{
		length++;
		
		//writeln(cast(char)dataByte);
		if(dataByte == delim)
		{
			auto str = cast(string) buf.data.idup;
			if(useLookBehind && length > 1 && prevByte == lookBehind)
				str = str[0..$-1];
			result ~= str;
			
			buf.clear();
			length = 0;
		}
		else
			buf.put(dataByte);
		
		prevByte = dataByte;
	}
	result ~= cast(string) buf.data.idup;

	//writeln("--------------------");
	//foreach(elem; result)
	//	writeln(cast(string)elem);
	
	return result;
}

unittest
{
	auto convert(string str)
	{
		return cast(ubyte[]) str.dup;
	}
	
	writeln("Testing parseNullDelimited");
	assert(
		parseNullDelimited( convert("abc\0'hello world'\0def\0\0_123") ) ==
		["abc", "'hello world'", "def", "", "_123"]
	);
	assert(
		parseNullDelimited( convert("\0'hello world'\0") ) ==
		["", "'hello world'", ""]
	);
	assert(parseNullDelimited( convert("\0") ) == ["", ""]);
	assert(parseNullDelimited( convert("a") ) == ["a"]);
	assert(parseNullDelimited( convert("") ) == [""]);

	writeln("Testing parseNewlineDelimited");
	assert(
		parseNewlineDelimited(convert("abc\n'hello world'\r\ndef\r\n\r\n123\n\n456") ) ==
		["abc", "'hello world'", "def", "", "123", "", "456"]
	);
	assert(
		parseNewlineDelimited( convert("\n'hello world'\r\n") ) ==
		["", "'hello world'", ""]
	);
	assert(
		parseNewlineDelimited( convert("\r\n'hello world'\n") ) ==
		["", "'hello world'", ""]
	);
	assert(parseNewlineDelimited( convert("\n") ) == ["", ""]);
	assert(parseNewlineDelimited( convert("\r\n") ) == ["", ""]);
	assert(parseNewlineDelimited( convert("a") ) == ["a"]);
	assert(parseNewlineDelimited( convert("") ) == [""]);
	assert(parseNewlineDelimited( convert("abc\rdef") ) == ["abc\rdef"]);
}
