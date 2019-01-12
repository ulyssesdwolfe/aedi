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
	Alexandru Ermicioi
**/
module aermicioi.aedi.exception.circular_reference_exception;

import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.util.range : BufferSink;

/**
Exception denoting a circular dependency in DI container.

Exception denoting a circular dependency in DI container.
It is thrown when a DI gets an InProgressException, or it detected a circular dependency in other way.
**/
@safe class CircularReferenceException : AediException {
    string[] chain;

    public {
        nothrow this(string msg, string identity, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
        {
            super(msg, identity, file, line, next);
        }

        nothrow this(string msg, string identity, Throwable next, string file = __FILE__, size_t line = __LINE__)
        {
            super(msg, identity, file, line, next);
        }

        override void pushMessage(scope void delegate(in char[]) sink) const @system {
            import std.algorithm : joiner, substitute;
            import std.array : array;
            import std.utf : byChar;

            string[] chain = this.chain.dup;
            auto substituted = this.msg.substitute("${chain}", chain.joiner(" -> ").byChar.array.idup, "${identity}", identity).byChar;

            while (!substituted.empty) {
                auto buffer = BufferSink!(char[256])();
                buffer.put(substituted);

                sink(buffer.slice);
            }
        }
    }
}