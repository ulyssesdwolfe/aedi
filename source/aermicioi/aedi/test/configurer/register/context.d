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
module aermicioi.aedi.test.configurer.register.context;

import aermicioi.aedi.configurer.register.context;
import aermicioi.aedi.configurer.register.factory_configurer;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.container.application_container;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.test.fixture;
import std.traits;

unittest {
    SingletonContainer container = new SingletonContainer;

    with (container.configure) {
        
        register!MockObject("identity");
        register!MockObject();
        register!(MockInterface, MockObject)();
        
        assert(container.locate!MockObject("identity") !is null);
        assert(container.locate!MockObject() !is null);
        assert(container.locate!MockObject(fullyQualifiedName!MockObject) !is null);
    }
}

unittest {
    SingletonContainer container = new SingletonContainer;

    with (container.configure) {
        
        register(10UL, "a.long");
        register(20UL);
        register!MockInterface(new MockObject);
        
        assert(container.locate!ulong("a.long") == 10UL);
        assert(container.locate!ulong == 20UL);
        assert(container.locate!MockObject(fullyQualifiedName!MockInterface) !is null);
    }
}

unittest {
    Storage!(ObjectFactory, string) storage = new SingletonContainer;
    Locator!() locator = new ApplicationContainer;
    
    RegistrationContext!() context;
    
    context = storage.configure(locator);
    
    assert(context.storage is storage);
    assert(context.locator is locator);
    context = RegistrationContext!()();
    
    context = locator.configure(storage);
    
    assert(context.storage is storage);
    assert(context.locator is locator);
    context = RegistrationContext!()();
    
    context = locator.configure("singleton");
    
    assert(context.storage is locator.locate!(Storage!(ObjectFactory, string))("singleton"));
    assert(context.locator is locator);
    context = RegistrationContext!()();
    
    context = storage.configure(null).along(locator);
    
    assert(context.storage is storage);
    assert(context.locator is locator);
    context = RegistrationContext!()();
    
    context = locator.configure(cast(Storage!(ObjectFactory, string)) null).along(storage);
    
    assert(context.storage is storage);
    assert(context.locator is locator);
    context = RegistrationContext!()();
    
    context = locator.configure(cast(Storage!(ObjectFactory, string)) null).along("singleton");
    
    assert(context.storage is locator.locate!(Storage!(ObjectFactory, string))("singleton"));
    assert(context.locator is locator);
    context = RegistrationContext!()();
}

unittest {
    ObjectStorage!() container = new ObjectStorage!();

    with (container.configure) {
        
        register(10UL, "a.long");
        register(20UL);
        register!MockInterface(new MockObject);
        
        assert(container.locate!ulong("a.long") == 10UL);
        assert(container.locate!ulong == 20UL);
        assert(container.locate!MockObject(fullyQualifiedName!MockInterface) !is null);
    }
}