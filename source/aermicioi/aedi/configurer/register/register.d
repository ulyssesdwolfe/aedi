/**
Provides an interface for registering components into containers.

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
module aermicioi.aedi.configurer.register.register;

import aermicioi.aedi.configurer.register.generic_factory_metadata_decorator;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.wrapping_factory : WrappingFactory;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.container.proxy_container;
import aermicioi.aedi.container.container;
import aermicioi.util.traits : isReferenceType;
import aermicioi.aedi.exception;

/**
Register a new factory for type T object into storage/DI container by id.

Params:
    Type = the type of object registered in storage
	storage = the storage where factory will be stored.
	locator = the locator that will be used by GenericFactory implementation to fetch required objects.
	id = the identity by which to register the factory in storage.
	
Returns:
	GenericFactory implementation for further configuration.
**/
auto register(Type)(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, string id) {
    auto fact = new GenericFactoryImpl!Type(locator);
    auto configurable = new MetadataDecoratedGenericFactory!Type();
    configurable.storage = storage;
    configurable.locator = locator;
    configurable.identity = id;
    configurable.decorated = fact;
    configurable.wrapper = new WrappingFactory!(Factory!Type)(fact);
    
    storage.set(configurable.wrapper, id);
    
    return configurable;
}

/**
ditto
**/
auto register(Type)(ConfigurableContainer storage, string id) {
    return register!Type(storage, storage, id);
}

/**
Register a new factory for type Type object into storage/DI container by it's fully qualified name.

Params:
    Type = the type of object registered in storage
	storage = the storage where factory will be stored.
	locator = the locator that will be used by GenericFactory implementation to fetch required objects.
	
Returns:
	GenericFactory implementation for further configuration.
**/
auto register(Type)(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator) {
    return storage.register!(Type)(locator, name!Type);
}

/**
ditto
**/
auto register(Type)(ConfigurableContainer storage) {
    return register!Type(storage, storage);
}

/**
Register a new factory for type T object into storage/DI container by Interface fully qualified name.

Params:
    Type = the type of object registered in storage
    Interface = interface implemented by object registered in storage
	storage = the storage where factory will be stored.
	locator = the locator that will be used by GenericFactory implementation to fetch required objects.
	
Returns:
	GenericFactory implementation for further configuration.
**/
auto register(Interface, Type)(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator)
	if (is(Type : Interface) && isReferenceType!Type) {
    
    return storage.register!Type(locator, name!Interface);
}

/**
ditto
**/
auto register(Interface, Type)(ConfigurableContainer storage) {
    return register!(Interface, Type)(storage, storage);
}

/**
Register an object into a storage by storageId located in storageLocator.

Params:
    Type = the type of object registered in storage
    storageLocator = locator containing the storage where to store object.
    locator = locator used to fetch dependencies for registered object
    id = the id of object registered in storage
    storageId = the id of storage where object is stored.
    
Throws:
    NotFoundException when storage with storageId is not found.
    
Returns:
    storageLocator for further configuration
**/
auto register(Type, R : Locator!())(R storageLocator, Locator!() locator, string id, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
    import std.algorithm;

    return storageLocator
        .locate!(Storage!(ObjectFactory, string))(storageId)
        .register!Type(locator, id);
}
    
/**
ditto
**/
auto registerInto(Type, R : Locator!())(R storageLocator, Locator!() locator, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
    
    return storageLocator.register!Type(locator, name!Type, storageId);
}

/**
ditto
**/
auto register(Type, R : Locator!())(R locator, string id, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
    
    return locator.register!Type(locator, id, storageId);
}
    
/**
ditto
**/
auto registerInto(Type, R : Locator!())(R locator, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
    
    return locator.registerInto!Type(locator, storageId);
}

/**
Register an object into a storage by storageId located in storageLocator with id being FQN of an Interface that object implements.

Params:
    Interface = interface that object implements
    Type = the type of object registered in storage
    storageLocator = locator containing the storage where to store object.
    locator = locator used to fetch dependencies for registered object
    storageId = the id of storage where object is stored.
    
Throws:
    NotFoundException when storage with storageId is not found.
    
Returns:
    storageLocator for further configuration
**/
auto register(Interface, Type, R : Locator!())(R storageLocator, Locator!() locator, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
        
    return storageLocator.register!Type(locator, name!Interface, storageId);
}

/**
ditto
**/
auto register(Interface, Type, R : Locator!())(R locator, string storageId = "singleton") 
    if (!is(R : Storage!(ObjectFactory, string))) {
        
    return locator.register!Type(locator, name!Interface, storageId);
}

/**
Register data into an object storage.

Wraps up any already instantiated data that is not reference type into an object, and saves it into storage.
Any data that is of reference type is just saved in storage

Params:
    Type = the type of object registered in storage
    storage = the storage were data is saved
    data = actual data to be saved
    id = the identity of data that is to be saved.
    
Returns:
    the storage were data was saved.
**/
auto register(Type)(Storage!(Object, string) storage, Type data, string id) {
    import aermicioi.aedi.storage.wrapper : WrapperImpl;
    
    static if (is(Type : Object)) {
        
        storage.set(data, id);
    } else {

        auto wrapper = new WrapperImpl!Type(data);
        storage.set(wrapper, id);
    }
    
    return storage;
}

/**
Register data inta a object storage identified by it's type.

Wraps up any copy-by-value data into an object, and saves it into storage by it's type.

Params:
    Type = the type of object registered in storage
    storage = the storage were data is saved
    data = actual data to be saved

Returns:
    the storage were data was saved.
**/
auto register(Type)(Storage!(Object, string) storage, Type data) {
    return storage.register!Type(data, name!Type);
}

/**
Register data into an object storage identified by implemented interface.

Wraps up any copy-by-value data into an object, and saves it into storage by it's type.

Params:
    Interface = interface that object implements
    Type = the type of object registered in storage
    storage = the storage were data is saved
    data = actual data to be saved

Returns:
    the storage were data was saved.
**/
auto register(Interface, Type)(Storage!(Object, string) storage, Type data)
    if (is(Type : Interface) && !is(Type == Interface)) {
    
    return storage.register!Type(data, name!Interface);
}

/**
Register data into an object storage located in locator by storageId.

Params:
    Type = the type of object registered in storage
    locator = locator containing object storage were data is saved.
    data = the actual data saved in storage
    id = the id by which data will be identified
    storageId = identity of storage in locator
**/
auto register(Type, R : Locator!())(R locator, Type data, string id, string storageId = "parameters")
    if (!is(R : Storage!(Object, string))) {
    import aermicioi.aedi.storage.wrapper : Wrapper;

    locator
        .locate!(Storage!(Object, string))(storageId)
        .register!Type(data, id);

    return locator;
}

/**
ditto
**/
auto registerInto(Type, R : Locator!())(R locator, Type data, string storageId = "parameters")
    if (!is(R : Storage!(Object, string))) {
    
    return locator.register!Type(data, name!Type, storageId);
}

/**
ditto
**/
auto register(Interface, Type, R : Locator!())(R storage, Type object, string storageId = "parameters") 
    if (is(Type : Interface) && !is(R : Storage!(Object, string)) && !is(Type == Interface)) {
    return storage.register!Type(object, name!Interface, storageId);
}