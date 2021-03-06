/**
License:
	Boost Software License - Version 1.0 - August 17th, 2003

	Permission is hereby granted, free of charge, to any person or organization
	obtaining a copy of the software and accompanying documentation covered by
	this license (the "Software") to use, reproduce, display, distribute,
	execute, and transmit the Software, and to prepare derivative works of the
	Software, and to permit third-parties to whom the Software is furnished to
	do so, all subject to the following:

	The copyright notices in the Software and this entire statement, including
	the above license grant, this restriction and the following disclaimer,
	must be included in all copies of the Software, in whole or in part, and
	all derivative works of the Software, unless such copies or derivative
	works are solely in the form of machine-executable object code generated by
	a source language processor.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
	SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
	FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.

Authors:
	aermicioi
**/
module aermicioi.aedi.exception.property_configurer_exception;

import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.util.range : BufferSink;

/**
Denotes an error that occurred during configuration process done by an object which is a subclass of
PropertyConfigurer.
**/
@safe class PropertyConfigurerException : AediException {

	/**
	Type of offending component
	**/
	TypeInfo type;

	/**
	Property of offending component where exception was thrown
	**/
	string property;

	/**
     * Creates a new instance of Exception. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    pure nothrow this(string msg, string identity, string property, TypeInfo type, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, identity, file, line, next);
		this.property = property;
		this.type = type;
    }

	/**
	ditto
	**/
    nothrow this(string msg, string identity, string property, TypeInfo type, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, identity, file, line, next);
		this.property = property;
		this.type = type;
    }

	override void pushMessage(scope void delegate(in char[]) sink) const @system {
		import std.algorithm : substitute;
        import std.utf : byChar;
        auto substituted = this.msg.substitute("${property}", property, "${identity}", identity, "${type}", type.toString).byChar;

		while (!substituted.empty) {
            auto buffer = BufferSink!(char[256])();
            buffer.put(substituted);

            sink(buffer.slice);
        }
	}
}