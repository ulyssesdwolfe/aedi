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
module aermicioi.aedi.factory.wrapping_factory;

import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.wrapper;
import std.traits;

/**
Wraps up the result of some factory in Wrapper object if component is not
derived from Object.
**/
@safe class WrappingFactory(T : Factory!Z, Z) : ObjectFactory, MutableDecorator!T {

    private {
        RCIAllocator allocator_;

        T decorated_;
    }

    public {

        /**
        Constructor for WrappingFactory!(T, Z)

        Params:
            factory = factory that is wrapped
        **/
        this(T factory) {
            import std.experimental.allocator : theAllocator;

            this.decorated = factory;
            this.allocator = theAllocator;
        }

        @property {
            /**
            Set allocator

            Params:
                allocator = allocator used to allocate wrappers when needed.

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(RCIAllocator allocator) @safe nothrow
            in (allocator !is null, "Expected an allocator, not null.") {
                this.allocator_ = allocator;
                this.decorated.allocator = allocator;

                return this;
            }

            /**
            Get allocator

            Returns:
                RCIAllocator
            **/
            RCIAllocator allocator() @safe nothrow {
                return this.allocator_;
            }
            /**
            Set the decorated object for decorator.

            Params:
                decorated = decorated component

            Returns:
            	this
            **/
        	WrappingFactory!(T, Z) decorated(T decorated) @safe nothrow pure
            in (decorated !is null, "Expected a factory to decorate for type " ~ typeid(T).toString ~ " not null.") {
        		this.decorated_ = decorated;

        		return this;
        	}

            /**
            Get the decorated object.

            Returns:
            	T decorated object
            **/
        	inout(T) decorated() @safe nothrow inout {
        		return this.decorated_;
        	}

            /**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created component.
    		**/
        	TypeInfo type() @safe nothrow const {
        	    return this.decorated.type;
        	}

            /**
            Set a locator to object.

            Params:
                locator = the locator that is set to oject.

            Returns:
                LocatorAware.
            **/
        	WrappingFactory!T locator(Locator!() locator) {
        		this.decorated.locator = locator;

        		return this;
        	}

        }

        /**
		Instantiates component of type T.

		Returns:
			Object instantiated component and probably wrapped if not derived from Object.
		**/
        Object factory() @trusted {
            static if (is(Z : Object)) {

                return this.decorated.factory;
            } else static if (is(Z == class)) {
                import aermicioi.aedi.storage.wrapper : CastableWrapperImpl;
                return this.allocator.make!(CastableWrapperImpl!(Z, InterfacesTuple!Z))(this.decorated.factory);
                // return this.allocator.make!(CastableWrapperImpl!(Z, InterfacesTuple!Z, BaseClassesTuple!Z))(this.decorated.factory); /// Nope not working with extern classes
            } else static if (is(Z == ubyte)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, ushort, uint, ulong, short, int, long, float, double))(this.decorated.factory);
            } else static if (is(Z == ushort)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, uint, ulong, int, long, float, double))(this.decorated.factory);
            } else static if (is(Z == uint)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, ulong, long, float, double))(this.decorated.factory);
            } else static if (is(Z == ulong)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, double))(this.decorated.factory);
            } else static if (is(Z == byte)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, short, int, long, float, double))(this.decorated.factory);
            } else static if (is(Z == short)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, int, long, float, double))(this.decorated.factory);
            } else static if (is(Z == int)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, long, float, double))(this.decorated.factory);
            } else static if (is(Z == long)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, double))(this.decorated.factory);
            } else static if (is(Z == float)) {
                return this.allocator.make!(CastableWrapperImpl!(Z, double))(this.decorated.factory);
            } else static if (is(Z == double)) {
                return this.allocator.make!(WrapperImpl!(Z))(this.decorated.factory);
            } else {
                return this.allocator.make!(WrapperImpl!Z)(this.decorated.factory);
            }
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref Object component) @trusted {
            static if (is(Z : Object)) {

                Z casted = cast(Z) component;

                if (casted !is null) {

                    this.decorated.destruct(casted);
                    return;
                }
            } else {

                Wrapper!Z casted = cast(Wrapper!Z) component;

                if (casted !is null) {
                    this.decorated.destruct(casted.value);
                    this.allocator.dispose(component);
                    return;
                }
            }

            import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
            throw new InvalidCastException(
                "Cannot destruct component of type ${actual} expected component of ${expected} type", null, typeid(Z), component.classinfo
            );
        }

    }
}

/**
A proxy factory that returns a proxy when object cannot be constructed due to circular reference errors.

A proxy factory that returns a proxy when object cannot be constructed due to circular reference errors.
The wrapper will provide a proxy object instead of original only when, an deffered executioner is provided,
and exception chain contains a CircularReferenceException. Due to providing a proxy instead of original object
usage of this factory wrapper should be considered in cases when performance is not of first priority.
**/
@safe class DefferedProxyWrapper(T : Factory!Z, Z : Object) : Factory!Z, MutableDecorator!T, DefferredExecutionerAware {
    import aermicioi.aedi.exception : AediException, CircularReferenceException;
    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin, theAllocator;

    mixin MutableDecoratorMixin!T;

    private {

        DefferredExecutioner executioner_;
        RCIAllocator allocator_;
    }

    invariant {
        assert(decorated_ !is null);
        assert(!allocator_.isNull);
    }

    public {

        /**
        Default constructor for DefferedProxyWrapper
        **/
        this(T factory) {
            this.decorated_ = factory;
            this.allocator_ = theAllocator;
        }

        @property {

            /**
            Set allocator

            Params:
                allocator = allocator used to allocate deffered proxies and original objects.

            Returns:
                typeof(this)
            **/
            typeof(this) allocator(RCIAllocator allocator) @safe nothrow {
                this.allocator_ = allocator;
                this.decorated.allocator = allocator;

                return this;
            }

            /**
            Get allocator

            Returns:
                RCIAllocator
            **/
            RCIAllocator allocator() @safe nothrow {
                return this.allocator_;
            }
            /**
            Set executioner

            Params:
                executioner = executioner used for deffered construction.

            Returns:
                typeof(this)
            **/
            typeof(this) executioner(DefferredExecutioner executioner) @safe nothrow pure {
                this.executioner_ = executioner;

                return this;
            }

            /**
            Get executioner

            Returns:
                DefferredExecutioner
            **/
            DefferredExecutioner executioner() @safe nothrow pure {
                return this.executioner_;
            }

            /**
    		Get the type info of T that is created.

    		Returns:
    			TypeInfo object of created component.
    		**/
        	TypeInfo type() @safe nothrow const {
        	    return this.decorated.type;
        	}

            /**
            Set a locator to object.

            Params:
                locator = the locator that is set to oject.

            Returns:
                LocatorAware.
            **/
        	DefferedProxyWrapper!T locator(Locator!() locator) {
        		this.decorated.locator = locator;

        		return this;
        	}
        }

        /**
		Instantiates component of type Z.

		Returns:
			Z instantiated component.
		**/
        Z factory() @trusted {
            try {
                return this.decorated.factory();
            } catch (AediException exception) {

                if (this.executioner !is null) {

                    Throwable current = exception;

                    while (current !is null) {

                        CircularReferenceException circularReferenceException = cast(CircularReferenceException) current;

                        if (current !is null) {

                            if (circularReferenceException !is null) {

                                DefferedProxy!Z proxy = this.allocator.make!(DefferedProxy!Z);
                                this.executioner.add(
                                    () {
                                        proxy.original__ = this.decorated.factory();
                                    }
                                );

                                return proxy;
                            }
                        }

                        current = current.next;
                    }
                }

                throw exception;
            }
        }

        /**
        Destructs a component of type Z.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref Z component) @trusted {
            DefferedProxy!Z proxy = cast(DefferedProxy!Z) component;

            if (proxy !is null) {
                this.allocator.dispose(proxy);

                return;
            }

            this.decorated.destruct(component);
        }
    }
}

private abstract class DefferedProxyHusk(T) : T {

    protected {
        T original__;
    }

    public {

    }
}

import std.typecons : AutoImplement;
import std.traits;

alias DefferedProxy(T) = AutoImplement!(
    DefferedProxyHusk!T,
    __how,
    __what
    );

template __what(alias fun) {
    enum bool __what = !isFinalFunction!(fun) || (__traits(identifier, fun) == "__ctor") || (__traits(identifier, fun) == "__dtor");
}

string __how(C, alias fun)() {

    static if (__traits(identifier, fun) == "__ctor") {
        return __ctor!(C, fun);
    } else static if (__traits(identifier, fun) == "__dtor") {
        return __dtor!(C, fun);
    } else {
        return __method!(C, fun);
    }
}

string __method(C, alias fun)() {
    string stmt;
    static if (!is(ReturnType!fun == void)) {

        stmt ~= q{return };
    }

    return stmt ~ q{original__.} ~ __traits(identifier, fun) ~ q{(args);};
}

string __ctor(C, alias fun)() {
    return q{
        super(args);
    };
}

string __dtor(C, alias fun)() {
    return q{};
}