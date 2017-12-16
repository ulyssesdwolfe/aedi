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
module aermicioi.aedi.storage.decorator;

/**
Provides the underlying decorated object.
**/
interface Decorator(T) {

    public {
        @property {

            /**
            Get the decorated object.

            Returns:
            	T decorated object
            **/
        	T decorated() @safe nothrow pure;
        }
    }
}

/**
Allows to get and set decorated object.
**/
interface MutableDecorator(T) : Decorator!T {
    public {
        @property {

            alias decorated = Decorator!T.decorated;
            /**
            Set the decorated object for decorator.

            Params:
                decorated = decorated data

            Returns:
            	this
            **/
        	typeof(this) decorated(T decorated) @safe nothrow pure;
        }
    }
}

/**
Find a decorator in decorator chain that implements Needle type.

Find a decorator in decorator chain that implements Needle type.

Params:
	Needle = the type searched decorator should implement
	Haystack = type of the chain of decorators through which to traverse
	decorated = top of decorator chain.

Returns:
	Decorator or null if not found.
**/
Needle findDecorator(Needle, Haystack : Decorator!Z, Z, T)(T decorated) {

    Haystack decorator = cast(Haystack) decorated;
    Needle needle = cast(Needle) decorated;

    while ((needle is null) && (decorator !is null)) {
        decorator = cast(Haystack) decorator.decorated;
        needle = cast(Needle) decorator;
    }

    return needle;
}

mixin template MutableDecoratorMixin(T) {

	private {
		T decorated_;
	}

	public {
		/**
		Set decorated

		Params:
			decorated = the element that is decorated by implementor

		Returns:
			typeof(this)
		**/
		typeof(this) decorated(T decorated) @safe nothrow pure {
			this.decorated_ = decorated;

			return this;
		}

		/**
		Get decorated

		Returns:
			T
		**/
		T decorated() @safe nothrow pure {
			return this.decorated_;
		}
	}
}