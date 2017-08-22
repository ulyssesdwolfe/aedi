/**
Contains primitives related to reference resolving during construction of data
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
import aermicioi.aedi.storage.wrapper;
import std.traits;

/**
Represents a reference that some data is dependent on it.

Represents a reference that some data is dependent on it. 
It will resolve itself to the referenced data, that is
subclass of Object, or data that is encapsulated in Wrapper object.
**/
interface RuntimeReference {
    
    /**
    Resolve the reference, to referenced data.
    
    Resolve the reference, to referenced data.
    
    Params:
    	locator = an optional source of data used to resolve reference
    
    Returns:
    	Object the actual object, or data that is wrapped in Wrapper object.
    **/
    Object get(Locator!() locator);
}

/**
Represents a reference that is located in locator.

Represents a reference that is located in locator.
It uses referenced data's identity in locator to
find it and serve.
**/
class LocatorReference : RuntimeReference {
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
            Set the identity of referenced data.
            
            Set the identity of referenced data.
            Description
            
            Params:
            	identity = the identity of referenced data.
            
            Returns:
            	this
            **/
        	LocatorReference identity(string identity) @safe nothrow {
        		this.identity_ = identity;
        	
        		return this;
        	}
        	
        	/**
        	Get the identity of referenced data.
        	
        	Get the identity of referenced data.
        	
        	Returns:
        		string the identity of referenced data
        	**/
        	string identity() @safe nothrow {
        		return this.identity_;
        	}
        }
        
        /**
        Resolve the reference, to referenced data.
        
        Resolve the reference, to referenced data.
        
        Params:
            locator = an optional source of data used to resolve reference
        
        Returns:
            Object the actual object, or data that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            return locator.get(this.identity);
        }
    }
}

/**
ditto
**/
auto lref(string id) {
    return new LocatorReference(id);
}

/**
ditto
**/
auto lref(string name)() {
    return name.lref;
}

/**
Reference to a component stored in a locator by it's type.
**/
class TypeLocatorReference(T) : RuntimeReference {
    
    public {
        /**
        Resolve the reference, to referenced data.
        
        Resolve the reference, to referenced data.
        
        Params:
            locator = an optional source of data used to resolve reference
        
        Returns:
            Object the actual object, or data that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            auto type = typeid(T);
            
            if (locator.has(type.toString())) {
                
                return locator.get(type.toString());
            } else {
                
                return locator.get(fullyQualifiedName!T);
            }
        }
    }
}

/**
ditto
**/
auto lref(T)() {
    return new TypeLocatorReference!T;
}

/**
Represents a reference to data yet to be constructed.

Represents a reference to data yet to be constructed.
It will instantiate the referenced data using an object
factory, and will serve it to requestor.
**/
class AnonymousFactoryReference : RuntimeReference {

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
        Resolve the reference, to referenced data.
        
        Resolve the reference, to referenced data.
        
        Params:
            locator = an optional source of data used to resolve reference
        
        Returns:
            Object the actual object, or data that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            return this.factory.factory;
        }
    }
}

/**
ditto
**/
auto anonymous(T : Factory!X, X)(T factory) {
    import aermicioi.aedi.factory.wrapping_factory : WrappingFactory;
    return anonymous(new WrappingFactory!T(factory));
}

/**
ditto
**/
auto anonymous(ObjectFactory factory) {
    auto anonymous = new AnonymousFactoryReference();
    anonymous.factory = factory;
    
    return anonymous;
}

class AlternateReference : RuntimeReference {
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
        Resolve the reference, to referenced data.
        
        Resolve the reference, to referenced data.
        
        Params:
            locator = an optional source of data used to resolve reference
        
        Returns:
            Object the actual object, or data that is wrapped in Wrapper object.
        **/
        Object get(Locator!() locator) {
            import aermicioi.aedi.exception.not_found_exception : NotFoundException;
            
            try {
                
                return this.original.get(locator);
            } catch (NotFoundException e) {
                
                return this.alternative.get(locator);
            }
        }
    }
}

AlternateReference alternate(RuntimeReference original, RuntimeReference alternate) {
    AlternateReference reference = new AlternateReference();

    reference.original = original;
    reference.alternative = alternate;

    return reference;
}

/**
Resolve a reference, and attempt to convert to data of type T.

Resolve a reference, and attempt to convert to data of type T.

Params:
	T = the expected type of resolved data.
	locator = optional source of data for resolving reference

Throws:
	InvalidCastException when resolved data is not of expected type.

Returns:
	T referenced object
	Wrapper!T referenced data that is not of Object subclass.
**/
auto resolve(T : Object)(RuntimeReference reference, Locator!() locator)
body {
    T result = cast(T) reference.get(locator);
    
    if (result !is null) {
        return result;
    }
    
    throw new InvalidCastException(
        "Resolved runtime reference " ~ 
        typeid(reference.get(locator)).toString() ~ 
        " is not of expected type: " ~ 
        fullyQualifiedName!T
    );
}

/**
ditto
**/
auto resolve(T)(RuntimeReference reference, Locator!() locator)
    if (is(T == interface)) {
    
    Object obj = reference.get(locator);
    {
        T result = cast(T) obj;
        
        if (result !is null) {
            return result;
        }
    }
    
    {
        Wrapper!T result = cast(Wrapper!T) obj;
        
        if (result !is null) {
            return result.value;
        }
    }

    {
        Castable!T result = cast(Castable!T) obj;
        
        if (result !is null) {
           
            return result.casted;
        }
    }
    
    throw new InvalidCastException(
        "Resolved runtime reference " ~ 
        typeid(reference.get(locator)).toString() ~ 
        " is not of expected type: " ~ 
        fullyQualifiedName!T
        );
}

/**
ditto
**/
auto resolve(T)(RuntimeReference reference, Locator!() locator)
    if (!is(T == interface)) {
    
    Object obj = reference.get(locator);

    {
        Wrapper!T result = cast(Wrapper!T) obj;
        
        if (result !is null) {
            return result.value;
        }
    }

    {
        Castable!T result = cast(Castable!T) obj;
        
        if (result !is null) {
            
            return result.casted;
        }
    }
    
    throw new InvalidCastException(
        "Resolved runtime reference " ~ 
        typeid(reference.get(locator)).toString() ~ 
        " is not of expected type: " ~ 
        fullyQualifiedName!T
        );
}

/**
ditto
**/
auto ref Z resolve(T, Z)(auto ref Z reference, Locator!() locator)
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

/**
Convert a type into a locator reference by type's name.
**/
template toLref(Type) {
    auto toLref() {
        return name!Type.lref;
    }
}

/**
ditto
**/
template toLrefType(Type) {
    alias toLrefType = LocatorReference;
}