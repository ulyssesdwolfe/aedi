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

	Decorator!DecoratorType current;

	this(ComponentType initial) @trusted {
		current = cast(Decorator!DecoratorType) initial;
	}

	this(Decorator!DecoratorType copy) {
		current = copy;
	}

	bool empty() {
		return current is null;
	}

	Decorator!DecoratorType front() {
		return current;
	}

	void popFront() @trusted {
		current = cast(Decorator!DecoratorType) current.decorated;
	}

	typeof(this) save() {
		return typeof(this)(current);
	}
}

/**
Given a range of objects filter them by Interface they are implementing.

Params:
	Interface = interface by which to filter the range
	range = range of objects to filter

Returns:
	InterfaceFilter!(Range, Interface) a range of filtered objects by Interface
**/
InterfaceFilter!(Range, Interface) filterByInterface(Interface, Range)(auto ref Range range) {
	return InterfaceFilter!(Range, Interface)(range);
}

/**
ditto
**/
@safe struct InterfaceFilter(Range, Interface)
if (isForwardRange!Range && (is(ElementType!Range == class) || is(ElementType!Range == interface))) {

	Range range;
	Interface current;

	this(this) {
		range = range.save;
	}

	this(ref Range range) {
		this.range = range.save;
		this.popFront;
	}

	private this(ref Range range, Interface current) {
		this.range = range.save;
		this.current = current;
	}

	bool empty() {
		return current is null;
	}

	Interface front() {
		return current;
	}

	void popFront() @trusted {
		while (!range.empty) {
			auto front = range.front;
			range.popFront;

			current = cast(Interface) front;

			if (current !is null) {
				return;
			}
		}

		current = null;
	}

	typeof(this) save() {
		return typeof(this)(range, current);
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
			return this.decorated_;
		}
	}
}