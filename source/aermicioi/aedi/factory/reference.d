/**
Contains primitives related to reference resolving during construction of component
(objects, structs, basic types, etc.).

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
module aermicioi.aedi.factory.reference;

import aermicioi.aedi.exception.invalid_cast_exception;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.storage.locator;
import std.traits;
import std.conv : text;

/**
Represents a reference that some component is dependent on it.

Represents a reference that some component is dependent on it.
It will resolve itself to the referenced component, that is
subclass of Object, or component that is encapsulated in Wrapper object.
**/
@safe interface RuntimeReference {

    /**
    Resolve the reference, to referenced component.

    Resolve the reference, to referenced component.

    Params:
    	locator = an optional source of component used to resolve reference

    Returns:
    	Object the actual object, or component that is wrapped in Wrapper object.
    **/
    Object get(Locator!() locator);
}

/**
Represents a reference that is located in locator.

Represents a reference that is located in locator.
It uses referenced component's identity in locator to
find it and serve.
**/
@safe class LocatorReference : RuntimeReference {
    private {
        string identity_;
    }

    public {
        /**
        Constructor for LocatorReference

        Params:
            id = identity of component that is referenced
        **/
        this(string id) {
            this.identity = id;
        }

        @property {

            /**
            Set the identity of referenced component.

            Set the identity of referenced component.
            Description

            Params:
            	identity = the identity of referenced component.

            Returns:
            	this
            **/
        	LocatorReference identity(string identity) @safe nothrow {
        		this.identity_ = identity;

        		return this;
        	}

        	/**
        	Get the identity of referenced component.

        	Get the identity of referenced component.

        	Returns:
        		string the identity of referenced component
        	**/
        	string identity() @safe nothrow {
        		return this.identity_;
        	}
        }

        /**
        Resolve the reference, to referenced component.

        Resolve the reference, to referenced component.

        Params:
            locator = an optional source of components used to resolve reference

        Returns:
            Object the actual object, or component that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            return locator.get(this.identity);
        }

        override string toString() const {
            return text("IdRef(", identity_, ")");
        }
    }
}

/**
ditto
**/
@safe auto lref(string id) {
    return new LocatorReference(id);
}

/**
ditto
**/
@safe auto lref(string name)() {
    return name.lref;
}

/**
Reference to a component stored in a locator by it's type.
**/
@safe class TypeLocatorReference(T) : RuntimeReference {

    public {
        /**
        Resolve the reference, to referenced component.

        Resolve the reference, to referenced component.

        Params:
            locator = an optional source of components used to resolve reference

        Returns:
            Object the actual object, or component that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            auto type = typeid(T);

            if (locator.has(type.toString())) {

                return locator.get(type.toString());
            } else {

                return locator.get(fullyQualifiedName!T);
            }
        }

        override string toString() {
            return text("TypeRef(", typeid(T), ")");
        }
    }
}

/**
ditto
**/
@safe auto lref(T)() {
    return new TypeLocatorReference!T;
}

/**
Represents a reference to component yet to be constructed.

Represents a reference to component yet to be constructed.
It will instantiate the referenced component using an object
factory, and will serve it to requestor.
**/
@safe class AnonymousFactoryReference : RuntimeReference {

    private {
        ObjectFactory factory_;
    }

    public {
        @property {
            /**
            Set factory

            Params:
                factory = factory used by anonymous reference to create component
            Returns:
                typeof(this)
            **/
        	AnonymousFactoryReference factory(ObjectFactory factory) @safe nothrow {
        		this.factory_ = factory;

        		return this;
        	}

            /**
            Get factory

            Returns:
                ObjectFactory
            **/
        	ObjectFactory factory() @safe nothrow {
        		return this.factory_;
        	}
        }

        /**
        Resolve the reference, to referenced component.

        Resolve the reference, to referenced component.

        Params:
            locator = an optional source of components used to resolve reference

        Returns:
            Object the actual object, or component that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            this.factory.locator = locator;
            scope(exit) this.factory.locator = null;

            return this.factory.factory;
        }

        override string toString() {
            return text("AnonRef(", factory.type, ")");
        }
    }
}

/**
ditto
**/
@safe auto anonymous(T : Factory!X, X)(T factory) {
    import aermicioi.aedi.factory.wrapping_factory : WrappingFactory;
    return anonymous(new WrappingFactory!T(factory));
}

/**
ditto
**/
@safe auto anonymous(ObjectFactory factory) {
    auto anonymous = new AnonymousFactoryReference();
    anonymous.factory = factory;

    return anonymous;
}

/**
Reference that defaults to alternate component in case that original one is not fetchable from container

Params:
    original = original reference to a component that is attempted to be fetched.
    alternate = reference to alternate component that is meant to substitute original component in case of some failure.
Throws:

Returns:
    AlternateReference
**/
@safe AlternateReference alternate(RuntimeReference original, RuntimeReference alternate) {
    AlternateReference reference = new AlternateReference();

    reference.original = original;
    reference.alternative = alternate;

    return reference;
}

/**
ditto
**/
@safe class AlternateReference : RuntimeReference {
    private {
        RuntimeReference original_;
        RuntimeReference alternative_;
    }

    public {
        /**
            Set original

            Params:
                original = primary reference used to fetch dependency
            Returns:
                typeof(this)
        **/
        typeof(this) original(RuntimeReference original) @safe nothrow pure {
            this.original_ = original;

            return this;
        }

        /**
            Get original

            Returns:
                RuntimeReference
        **/
        RuntimeReference original() @safe nothrow pure {
            return this.original_;
        }

        /**
            Set alternative

            Params:
                alternative = the second reference used when first throws exception

            Returns:
                typeof(this)
        **/
        typeof(this) alternative(RuntimeReference alternative) @safe nothrow pure {
            this.alternative_ = alternative;

            return this;
        }

        /**
            Get alternative

            Returns:
                RuntimeReference
        **/
        RuntimeReference alternative() @safe nothrow pure {
            return this.alternative_;
        }

        /**
        Resolve the reference, to referenced component.

        Resolve the reference, to referenced component.

        Params:
            locator = an optional source of components used to resolve reference

        Returns:
            Object the actual object, or component that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            import aermicioi.aedi.exception.not_found_exception : NotFoundException;

            try {

                return this.original.get(locator);
            } catch (NotFoundException e) {

                return this.alternative.get(locator);
            }
        }

        override string toString() @trusted {
            return text("OptRef(", this.original, ", ", this.alternative, ")");
        }
    }
}

/**
Create a reference with type enforcement.

The resulting reference will check for returned object to be compliant
with specified T type, otherwise a not found exception is thrown.

Params:
    reference = reference to be enforced with expected type
    T = expected type returned from container

Returns:
    TypeEnforcedRuntimeReference!T enforced reference with type.
**/
auto typeEnforcedRef(T)(RuntimeReference reference) {
    return new TypeEnforcedRuntimeReference!T(reference);
}

/**
ditto
**/
@safe class TypeEnforcedRuntimeReference(T) : RuntimeReference {
    private {
        RuntimeReference reference;
    }

    public {
        /**
        Constructor for enforced type reference accepting reference to be enforced.

        Params:
            reference = reference to enforce with type
        **/
        this(RuntimeReference reference)
        in (reference !is null, "Expected a reference, not null value") {
            this.reference = reference;
        }

        /**
        Resolve the reference, to referenced component.

        Resolve the reference, to referenced component.

        Params:
            locator = an optional source of components used to resolve reference

        Returns:
            Object the actual object, or component that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) @trusted {
            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;
            import aermicioi.aedi.storage.wrapper : unwrap;

            Object value = this.reference.get(locator);

            try {
                cast(void) value.unwrap!T;
            } catch (InvalidCastException exception) {

                throw new NotFoundException(text(
                    "The component was found using ", this.reference, " however it wasn't of expected type ", typeid(T), " but of ", value, "."
                ), null, exception);
            }

            return value;
        }

        override string toString() @trusted {
            return text("TypeEnfRef!(", typeid(T), ")(", this.reference, ")");
        }
    }
}

/**
Resolve a reference, and attempt to convert to component of type T.

See:
    aermicioi.aedi.storage.wrapper : unwrap for downcasting semantics.

Params:
	T = the expected type of resolved component.
	locator = optional source of components for resolving reference

Throws:
	InvalidCastException when resolved component is not of expected type.

Returns:
	T referenced object
	Wrapper!T referenced component that is not of Object subclass.
**/
@trusted auto resolve(T)(RuntimeReference reference, Locator!() locator) {
    import aermicioi.aedi.storage.wrapper : unwrap;
    return reference.get(locator).unwrap!T;
}

/**
ditto
**/
@trusted auto ref Z resolve(T, Z)(auto ref Z reference, Locator!() locator)
    if (!is(Z : RuntimeReference)) {
    return reference;
}

/**
Alias to fullyQualifiedName from std.traits, for shorter notation.
**/
template name(alias T)
    if (is(typeof(T))) {
    alias name = fullyQualifiedName!(typeof(T));
}

/**
ditto
**/
template name(T) {
    alias name = fullyQualifiedName!T;
}

RuntimeReference withDefault(T)(RuntimeReference reference, T defaults) {
    import aermicioi.aedi.factory.generic_factory : genericFactory, ValueInstanceFactory;
    auto factory = genericFactory!T(null);

    factory.setInstanceFactory(new ValueInstanceFactory!T(defaults));
    return reference.alternate(factory.anonymous);
}

auto transformToReference(string reference, string symbol) {
    string delegate (string) toTypeGen = (s) => "toType!(" ~ s ~ ")";
    string delegate (string, string) typeEnforcedRefGen = (t, s) => "typeEnforcedRef!(" ~ toTypeGen(t) ~ ")(" ~ s ~ ")";
    string delegate (string) identifierGen = (s) => "__traits(identifier, " ~ s ~ ")";
    string delegate (string) lrefGen = (s) => s ~ ".lref";
    string delegate (string) typeLrefGen = (s) => "lref!(" ~ s ~ ")";
    string delegate (string, string) alternateGen = (f, s) => f ~ ".alternate(" ~ s ~ ")";
    return "
        import aermicioi.aedi.util.traits : toType;
        static if (is(typeof(" ~ identifierGen(symbol) ~ "))) {
            " ~ reference ~ " = " ~ alternateGen(typeEnforcedRefGen(symbol, lrefGen(identifierGen(symbol))), typeEnforcedRefGen(symbol, typeLrefGen(toTypeGen(symbol)))) ~ ";
        }

        if (" ~ reference ~ " is null) {
            " ~ reference ~ " = " ~ typeLrefGen(toTypeGen(symbol)) ~ ";
        }

        static if (is(typeof(((" ~ symbol ~ " arg) => arg[0])()))) {
            import aermicioi.aedi.factory.reference : withDefault;
            " ~ reference ~ " = " ~ reference ~ ".withDefault(((" ~ symbol ~ " arg) => arg[0])());
        }
    ";
}

auto makeFunctionParameterReferences(alias FunctionType, alias transformer = transformToReference)() {
    static if (is(FunctionTypeOf!FunctionType params == __parameters)) {
        import std.meta : Repeat;
        import std.conv : to;
        import aermicioi.aedi.util.typecons : tuple;
        import aermicioi.aedi.util.traits : toType;

        Repeat!(params.length, RuntimeReference) references;

        static foreach (index, reference; references) {
            mixin(transformer("references[" ~ index.to!string ~ "]", "params[" ~ index.to!string ~ ".." ~ (index + 1).to!string ~ "]"));
        }

        return tuple(references);
    }
}