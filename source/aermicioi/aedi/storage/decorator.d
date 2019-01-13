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

import std.range.primitives : isInputRange, isForwardRange, ElementType;

/**
Provides the underlying decorated object.
**/
@safe interface Decorator(T) {

    public {
        @property {

            /**
            Get the decorated object.

            Returns:
            	T decorated object
            **/
        	inout(T) decorated() @safe nothrow inout;
        }
    }
}

/**
Allows to get and set decorated object.
**/
@safe interface MutableDecorator(T) : Decorator!T {
    public {
        @property {

            alias decorated = Decorator!T.decorated;
            /**
            Set the decorated object for decorator.

            Params:
                decorated = decorated component

            Returns:
            	this
            **/
        	typeof(this) decorated(T decorated) @safe nothrow;
        }
    }
}

/**
Treat component as a chain of decorated entities and express this as a range of decorators.

Params:
	ComponentType = The original type of component attempted to interpret as a range of decorators.
	DecoratorType = type each decorator in decorator chain.
	component = component to express as a range of decorators.

Returns:
	DecoratorChain!(ComponentType, DecoratorType) the range.
**/
DecoratorChain!(ComponentType, DecoratorType) decorators(DecoratorType, ComponentType)(ComponentType component) {
	return DecoratorChain!(ComponentType, DecoratorType)(component);
}

/**
ditto
**/
@safe struct DecoratorChain(ComponentType, DecoratorType)
if (is(ComponentType == class) || is(ComponentType == interface)) {
	import std.traits : Unqual, QualifierOf;
	import std.typecons : Rebindable;

	private alias QualifierOfComponentType = QualifierOf!ComponentType;
	private alias QualifiedDecoratorType = QualifierOfComponentType!(Decorator!DecoratorType);

	private Rebindable!(QualifiedDecoratorType) current;

	/**
	Constructor for decorator chain

	Params:
		initial = starting point of decorated component
	**/
	this(ComponentType initial) @trusted {
		current = cast(QualifiedDecoratorType) initial;
	}

	private this(QualifiedDecoratorType copy) {
		current = copy;
	}

	/**
	Whether empty or not

	Returns:
		true if empty false otherwise
	**/
	bool empty() {
		return current is null;
	}

	/**
	The first decorator in chain of decorators.

	Returns:
		Decorated component with storage class preserved.
	**/
	QualifiedDecoratorType front() {
		return current;
	}

	/**
	Move to next decorator in chain
	**/
	void popFront() @trusted {
		current = cast(QualifiedDecoratorType) current.decorated;
	}

	/**
	Save decorator range.

	Returns:
		A copy of current range
	**/
	typeof(this) save() {
		return typeof(this)(current);
	}
}

/**
Mixin implementing MutableDecorator for a decorated element of T.
**/
@safe mixin template MutableDecoratorMixin(T) {

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
		inout(T) decorated() @safe nothrow pure inout {
			auto t = this.decorated_;
			return t;
		}
	}
}