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
module aermicioi.aedi.test.factory.generic_factory;

import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.exception.di_exception;
import aermicioi.aedi.exception.instance_factory_exception;
import aermicioi.aedi.exception.property_configurer_exception;
import aermicioi.aedi.factory.reference;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.wrapper;
import std.exception;
import std.experimental.allocator : theAllocator;

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!MockObject factory = new GenericFactoryImpl!MockObject(storage);

    assert(factory.locator() is storage);
    assert(factory.type() is typeid(MockObject));

    factory.setInstanceFactory(new DefaultInstanceFactory!MockObject);
    assert(factory.factory().classinfo is typeid(MockObject));
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    MockObject obj = new MockObject;
    auto smethod = methodConfigurer!("method", MockObject)(20, 10).locator(new MockLocator);
    auto rmethod = methodConfigurer!("method", MockObject)(new LocatorReference("int"), 10).locator(storage);
    auto emethod = methodConfigurer!("nasty", MockObject)().locator(new MockLocator);

    storage.set(new WrapperImpl!int(10), "int");

    smethod.configure(obj);
    assert(obj.property == 30);
    rmethod.configure(obj);
    assert(obj.property == 20);
    assertThrown(emethod.configure(obj));
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    MockObject obj = new MockObject;
    auto sproperty = fieldConfigurer!("property", MockObject)(10).locator(new MockLocator);
    auto rproperty = fieldConfigurer!("property", MockObject)(new LocatorReference("int")).locator(storage);
    auto eproperty = fieldConfigurer!("property", MockObject)(new LocatorReference("unknown")).locator(storage);


    storage.set(new WrapperImpl!int(20), "int");

    sproperty.configure(obj);
    assert(obj.property == 10);
    rproperty.configure(obj);
    assert(obj.property == 20);
    assertThrown(eproperty.configure(obj));
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    DefaultInstanceFactory!MockObject cfactory = new DefaultInstanceFactory!MockObject()
        .allocator(theAllocator);
    DefaultInstanceFactory!MockStruct sfactory = new DefaultInstanceFactory!MockStruct()
        .allocator(theAllocator);
    assert(cfactory.factory !is null);
    assert(sfactory.factory == MockStruct.init);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    auto csfactory = constructorBasedFactory!MockObject(cast(int) 10)
        .allocator(theAllocator)
        .locator(new MockLocator);
    auto crfactory = constructorBasedFactory!MockObject(new LocatorReference("int"))
        .locator(storage)
        .allocator(theAllocator);
    auto cefactory = constructorBasedFactory!MockObject(new LocatorReference("unknown"))
        .locator(storage)
        .allocator(theAllocator);

    storage.set(new WrapperImpl!int(20), "int");

    assert(csfactory.factory.property == 10);
    assert(crfactory.factory.property == 20);
    assertThrown!InstanceFactoryException(cefactory.factory);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    auto scsfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryObject")(10).locator(new MockLocator);
    auto scrfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryObject")(new LocatorReference("int"))
        .locator(storage);
    auto scefactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryObject")(new LocatorReference("unknown"))
        .locator(storage);
    auto sssfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryStruct")(10).locator(new MockLocator);
    auto ssrfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryStruct")(new LocatorReference("int"))
        .locator(storage);
    auto ssefactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "staticFactoryStruct")(new LocatorReference("unknown"))
        .locator(storage);

    auto cfactory = new MockObjectFactoryMethod;
    auto sfactory = new MockObjectFactoryMethod;

    cfactory.property = 10;
    sfactory.property = 11;
    storage.set(new MockObjectFactoryMethod, "dfactory");

    auto dcsfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryObject")(cfactory).locator(new MockLocator);
    auto dcrfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryObject")(new LocatorReference("dfactory"))
        .locator(storage);
    auto dcefactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryObject")(new LocatorReference("unknown"))
        .locator(storage);
    auto dssfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryStruct")(sfactory).locator(new MockLocator);
    auto dsrfactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryStruct")(new LocatorReference("dfactory"))
        .locator(storage);
    auto dsefactory = factoryMethodBasedFactory!(MockObjectFactoryMethod, "factoryStruct")(new LocatorReference("unknown"))
        .locator(storage);

    storage.set(new WrapperImpl!int(20), "int");

    assert(scsfactory.factory.property == 10);
    assert(scrfactory.factory.property == 20);
    assertThrown!InstanceFactoryException(scefactory.factory);

    assert(sssfactory.factory.property == 10);
    assert(ssrfactory.factory.property == 20);
    assertThrown!InstanceFactoryException(ssefactory.factory);

    assert(dcsfactory.factory.property == 10);
    assert(dcrfactory.factory.property == 0);
    assertThrown!InstanceFactoryException(dcefactory.factory);

    assert(dssfactory.factory.property == 11);
    assert(dsrfactory.factory.property == 0);
    assertThrown!InstanceFactoryException(dsefactory.factory);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    auto csfactory = callbackFactory!MockObject(function (RCIAllocator alloc, Locator!() loc, int i) {
        return alloc.make!MockObject(i);
    }, cast(int) 10)
        .locator(new MockLocator)
        .allocator(theAllocator);
    auto crfactory = callbackFactory!MockObject(delegate (RCIAllocator alloc, Locator!() loc, LocatorReference i) {
        return alloc.make!MockObject(i.resolve!int(loc));
    }, new LocatorReference("int"))
        .locator(storage)
        .allocator(theAllocator);
    auto cefactory = callbackFactory!MockObject(function MockObject(RCIAllocator alloc, Locator!() loc, int i) {
        throw new Exception("Not going to instantiate");
    }, cast(int) 10)
        .locator(new MockLocator)
        .allocator(theAllocator);

    storage.set(new WrapperImpl!int(20), "int");

    assert(csfactory.factory.property == 10);
    assert(crfactory.factory.property == 20);
    assertThrown!InstanceFactoryException(cefactory.factory);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    MockObject obj = new MockObject;
    MockStruct str = MockStruct();
    auto cscallback = callbackConfigurer!MockObject(function (Locator!() loc, MockObject obj, int i) {
        obj.property = i;
    }, 10).locator(new MockLocator);

    auto crcallback = callbackConfigurer!MockObject(delegate (Locator!() loc, MockObject obj, LocatorReference i) {
        obj.property = i.resolve!int(loc);
    }, new LocatorReference("int"))
        .locator(storage);

    auto cecallback = callbackConfigurer!MockObject(function (Locator!() loc, MockObject obj, LocatorReference i) {
        obj.property = i.resolve!int(loc);
    }, new LocatorReference("unk"))
        .locator(storage);

    auto sscallback = callbackConfigurer!MockStruct(function (Locator!() loc, ref MockStruct obj, int i) {
        obj.property = i;
    }, 10).locator(new MockLocator);

    auto srcallback = callbackConfigurer!MockStruct(delegate (Locator!() loc, ref MockStruct obj, LocatorReference i) {
        obj.property = i.resolve!int(loc);
    }, new LocatorReference("int"))
        .locator(storage);

    auto secallback = callbackConfigurer!MockStruct(function (Locator!() loc, ref MockStruct obj, LocatorReference i) {
        obj.property = i.resolve!int(loc);
    }, new LocatorReference("unk"))
        .locator(storage);

    storage.set(new WrapperImpl!int(20), "int");

    cscallback.configure(obj);
    assert(obj.property == 10);
    crcallback.configure(obj);
    assert(obj.property == 20);
    assertThrown!PropertyConfigurerException(cecallback.configure(obj));

    sscallback.configure(str);
    assert(str.property == 10);
    srcallback.configure(str);
    assert(str.property == 20);
    assertThrown!PropertyConfigurerException(secallback.configure(str));
}

unittest {
    GenericFactory!MockObject factory = new GenericFactoryImpl!MockObject(new MockLocator);
    MockObject obj = new MockObject;

    factory.setInstanceFactory(new ValueInstanceFactory!MockObject(obj));

    assert(factory.factory() is obj);
}

unittest {
    GenericFactory!MockInterface factory = new GenericFactoryImpl!MockInterface(new MockLocator);
    MockValueFactory!MockObject pfact = new MockValueFactory!MockObject();
    DelegatingInstanceFactory!(MockInterface, MockObject) ifact = new DelegatingInstanceFactory!(MockInterface, MockObject)(pfact);

    factory.setInstanceFactory(ifact);

    assert(factory.factory() !is null);
    assert(ifact.decorated is pfact);
}



unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    GenericFactory!MockObject factory = new GenericFactoryImpl!MockObject(storage);

    assert(factory.locator() is storage);
    assert(factory.type() is typeid(MockObject));

    auto object = factory.factory;

    factory.destruct(object);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();
    bool destroyed = false;
    auto destructor = callbackInstanceDestructor!MockObject((RCIAllocator allocator, ref MockObject obj) {
        destroyed = true;
        allocator.dispose(obj);
    });

    GenericFactory!MockObject factory = new GenericFactoryImpl!MockObject(storage);
    factory.setInstanceDestructor(destructor);

    assert(factory.locator() is storage);
    assert(factory.type() is typeid(MockObject));

    auto object = factory.factory;

    factory.destruct(object);

    assert(destroyed == true);
}

unittest {
    ObjectStorage!() storage = new ObjectStorage!();

    auto scsfactory = factoryMethodInstanceDestructor!(MockObject, "staticDestructObject", MockObjectFactoryMethod)();
    auto sssfactory = factoryMethodInstanceDestructor!(MockStruct, "staticDestructStruct", MockObjectFactoryMethod)();

    auto cfactory = new MockObjectFactoryMethod;
    auto sfactory = new MockObjectFactoryMethod;

    cfactory.property = 10;
    sfactory.property = 11;
    storage.set(new MockObjectFactoryMethod, "dfactory");

    auto dcsfactory = factoryMethodInstanceDestructor!(MockObject, "destructObject", MockObjectFactoryMethod)(cfactory);
    auto dssfactory = factoryMethodInstanceDestructor!(MockStruct, "destructStruct", MockObjectFactoryMethod)(sfactory);

    storage.set(new WrapperImpl!int(20), "int");

    auto scs = cfactory.staticFactoryObject(10);
    auto sss = sfactory.staticFactoryStruct(20);
    auto dcs = cfactory.factoryObject;
    auto dss = sfactory.factoryStruct;

    scsfactory.destruct(scs);
    sssfactory.destruct(sss);
    dcsfactory.destruct(dcs);
    dssfactory.destruct(dss);

    assert(scs.property == 3);
    assert(sss.property == 4);
    assert(dcs.property == 1);
    assert(dss.property == 2);
}