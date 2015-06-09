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
import safearg.version_;

immutable helpBanner =
"safeArg - <https://github.com/Abscissa/safeArg>
Version: "~appVersion~"
-----------------------------------------------
Takes a null-delimited list of args on stdin, and passes them as command line
arguments to any program you choose.

This is more secure, less error-prone, and more portable than using the shell's
command substitution or otherwise relying on the shell to parse args.

USAGE:
safearg [options] program_to_run < INPUT

INPUT:
A null-delimited (by default) list of command line arguments to app.

options:";

bool useNewlineDelim = false;
string alternateDelim = null;

// Returns: Should program execution continue?
bool doGetOpt(ref string[] args)
{
	immutable usageHint = "For usage, run: safearg --help";
	bool showVersion;
	
	try
	{
		auto helpInfo = args.getopt(
			"n|newline", `Use \n and \r\n newlines as delimiter insetad of \0`, &useNewlineDelim,
			"delim",     `Use alternate character as delimiter insetad of \0 (ex: --delim=,)`, &alternateDelim,
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
		writeln(appVersion);
		return false;
	}
	
	if(alternateDelim.length > 1)
		fail("Value for --delim=VALUE must be only byte\n" ~ usageHint);
	
	if(useNewlineDelim && alternateDelim)
		fail("Cannot use both --newline and --delim=VALUE\n" ~ usageHint);
	
	if(args.length != 2)
		fail("Wrong number of arguments\n" ~ usageHint);
	
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
	
	// Invoke command
	try
		return spawnProcess(args[1] ~ outArgs).wait();
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
