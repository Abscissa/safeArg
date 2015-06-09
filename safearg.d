import std.algorithm;
import std.array;
import std.conv;
import std.getopt;
import std.process;
import std.range;
import std.stdio;
import std.traits;

import scriptlike.fail;

immutable helpBanner =
"safeArg - <https://github.com/Abscissa/safeArg>
-----------------------------------------------
Takes a null-delimited list of args on stdin, and passes them as command line
arguments to any program you choose.

This is more secure, less error-prone, and more portable than using the shell's
command substitution or otherwise relying on the shell to parse args.

USAGE:
safearg [options] program_to_run < INPUT

INPUT:
A null-delimited list of command line arguments to app.

options:";

bool doGetOpt(string[] args)
{
	immutable usageHint = "For usage, run: safearg --help";
	
	try
	{
		auto helpInfo = args.getopt(
			// No other options supported right now.
		);

		if(helpInfo.helpWanted)
		{
			defaultGetoptPrinter(helpBanner, helpInfo.options);
			return false;
		}
	}
	catch(GetOptException e)
		fail(e.msg ~ "\n" ~ usageHint);
	
	if(args.length != 2)
		fail("Wrong number of arguments\n" ~ usageHint);
	
	return true;
}

version(unittest) void main() {} else
int main(string[] args)
{
	if(!doGetOpt(args))
		return 0;
	
	// Parse input
	auto outArgs = parseNullDelimited( stdin.byChunk(1024).joiner() );
	
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
	string[] result;
	auto buf = appender!(ubyte[])();
	foreach(dataByte; inputRange)
	{
		//writeln(cast(char)dataByte);
		if(dataByte != 0)
			buf.put(dataByte);
		else
		{
			result ~= cast(string) buf.data.idup;
			buf.clear();
		}
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
	assert(parseNullDelimited( convert("abc\0'hello world'\0def") ) == ["abc", "'hello world'", "def"]);
}
