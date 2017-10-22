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
module aermicioi.aedi.test.container.switchable_container;

import aermicioi.aedi.container.switchable_container;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.container.container;
import aermicioi.aedi.exception.circular_reference_exception;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.storage.locator;
import std.algorithm;
import std.typecons;
import std.exception;

unittest {
    import std.range;
    import std.conv;
    import std.traits;
    
    {
        SingletonContainer singleton = new SingletonContainer;
        
        singleton.set(new MockFactory!MockObject(), "mockObject");
        singleton.set(new MockFactory!MockObject(), "mockObject1");
        singleton.set(new MockFactory!MockObject(), "mockObject2");
        singleton.set(new CircularFactoryMock!MockObject().locator(singleton), "mock");
        
        {
            SwitchableContainer!(Locator!()) switchable = new SwitchableContainer!(Locator!());
            switchable.decorated = singleton;

            switchable.enabled = false;
            
            assertThrown!NotFoundException(switchable.get("mockObject2"));
            
            switchable.enabled = true;
            assertNotThrown!NotFoundException(switchable.get("mockObject2"));
        }
        
        {
            SwitchableContainer!(ConfigurableContainer) switchable = new SwitchableContainer!(ConfigurableContainer);
            scope(exit) switchable.terminate;
            switchable.decorated = singleton;

            switchable.enabled = false;
            switchable.set(new MockFactory!MockObject, "mockObject3");
            assertThrown!NotFoundException(switchable.get("mockObject3"));
            
            switchable.enabled = true;
            assertNotThrown!NotFoundException(switchable.get("mockObject3"));
            
            switchable.remove("mockObject3");
            assert(!switchable.has("mockObject3"));
            assertThrown!NotFoundException(switchable.get("mockObject3"));
            
            assert(switchable.getFactories().map!(
                    a => a[1].among(
                            "mockObject",
                            "mockObject1",
                            "mockObject2",
                            "mock"
                    ) && (a[0] !is null)
                ).fold!((a, b) => (a == true) && (b > 0))(true));
            
            switchable.remove("mockObject1");
            assert(!switchable.has("mockObject1"));
            
            assert(switchable.getFactory("mockObject") !is null);
        }
        
        {
            SwitchableContainer!(Container) switchable = new SwitchableContainer!(Container);
            scope(exit) switchable.terminate;
            switchable.decorated = singleton;

            switchable.enabled = false;
            assertNotThrown!CircularReferenceException(switchable.instantiate);
            
            switchable.enabled = true;
            assertThrown!CircularReferenceException(switchable.instantiate);
        }
        
        {
            SwitchableContainer!(ConfigurableContainer) switchable = new SwitchableContainer!(ConfigurableContainer);
            scope(exit) switchable.terminate;
            switchable.decorated = singleton;
            
            switchable.enabled = false;
            switchable.link("mockObject2", "mockObject3");
            assert(switchable.resolve("mockObject3") == "mockObject3");

            switchable.enabled = true;
            assert(switchable.resolve("mockObject3") == "mockObject2");
            switchable.unlink("mockObject3");
            assert(switchable.resolve("mockObject3") == "mockObject3");
        }
    }
}