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
module aermicioi.aedi.test.container.describing_container;

import aermicioi.aedi.container.describing_container;
import aermicioi.aedi.container.singleton_container;
import aermicioi.aedi.test.fixture;
import aermicioi.aedi.exception.circular_reference_exception;
import aermicioi.aedi.exception.not_found_exception;
import std.algorithm;
import std.exception;

unittest {
    IdentityDescriber!() describer = new IdentityDescriber!()();

    describer.register("amy", "a student", "a student at TDD");
    describer.register("dany", "a deliquent", "a deliquent at local gang");

    assert(describer.describe("amy", null) == Description!string("amy", "a student", "a student at TDD"));
    assert(describer.describe("dany", null) == Description!string("dany", "a deliquent", "a deliquent at local gang"));
    assert(describer.describe("ganny", null).isNull);

    describer.register("dany", "an angel", "an angel at local gang");
    assert(describer.describe("dany", null) == Description!string("dany", "an angel", "an angel at local gang"));

    describer.remove("dany");
    assert(describer.describe("dany", null).isNull);
}

unittest {
    auto describer = new TypeDescriber!(long, string)();
    assert(describer.describe("value", 10L) == Description!string("value", "value", "value typeof long"));
}

unittest {
    auto describer = new StaticDescriber!(long, string)("Mammoth manie", "An ordinary mammoth manie");

    assert(describer.describe("value", 10L) == Description!string("value", "Mammoth manie", "An ordinary mammoth manie"));
    assert(describer.describe("Manie", 10L) == Description!string("Manie", "Mammoth manie", "An ordinary mammoth manie"));
}

unittest {
    auto container = new DescribingContainer!SingletonContainer(new SingletonContainer, new IdentityDescriber!());
    scope(exit) container.terminate;

    auto f = new MockFactory!MockObject;
    auto f1 = new MockFactory!MockObject;

    container.set(f, "mock");
    container.set(f1, "mock1");

    assert(container.getFactories().map!(
            a => a.key.among(
                    "mock",
                    "mock1"
            ) && (a.value !is null)
        ).fold!((a, b) => (a == true) && (b > 0))(true));

    container.remove("mock");
    assert(!container.has("mock"));

    assert(container.getFactory("mock1") !is null);
}

unittest {
    import std.range;
    import std.conv;
    auto container = new DescribingContainer!SingletonContainer(new SingletonContainer, new IdentityDescriber!());
    scope(exit) container.terminate;

    container.set(new MockFactory!MockObject(), "mockObject");
    container.set(new MockFactory!MockObject(), "mockObject1");
    container.set(new CircularFactoryMock!MockObject().locator(container), "mock");

    assertThrown!CircularReferenceException(container.instantiate);

    assert(container.get("mockObject") !is null);
    assert(container.get("mockObject") == container.get("mockObject"));
    assert(container.get("mockObject") != container.get("mockObject1"));

    assertThrown!NotFoundException(container.get("unknown"));
}

unittest {
    import std.traits : fullyQualifiedName;
    auto main = new IdentityDescriber!();
    auto fallback = new TypeDescriber!();
    auto containerDescriber = new StaticDescriber!()("singleton", "Singleton container", "A container that instantiates and keeps managed components until it is terminated");

    auto container = new DescribingContainer!SingletonContainer(new SingletonContainer, main, containerDescriber, fallback);
    scope(exit) container.terminate;

    main.register("amy", "a student", "a student at TDD");
    main.register("dany", "a deliquent", "a deliquent at local gang");

    container.set(new MockFactory!MockObject, "amy");
    container.set(new MockFactory!MockObject, "dany");
    container.set(new MockFactory!MockObject, "ganny");

    assert(container.describe("amy", null) == Description!string("amy", "a student", "a student at TDD"));
    assert(container.describe("dany", null) == Description!string("dany", "a deliquent", "a deliquent at local gang"));
    assert(container.describe("ganny", null) == Description!string("ganny", "ganny", "ganny typeof object.Object"));

    main.register("dany", "an angel", "an angel at local gang");
    assert(container.describe("dany", null) == Description!string("dany", "an angel", "an angel at local gang"));

    main.remove("dany");
    assert(container.describe("dany", null) == Description!string("dany", "dany", "dany typeof object.Object"));

    assert(container.describe(null, container) == Description!string("singleton", "Singleton container", "A container that instantiates and keeps managed components until it is terminated"));
    assert(container.describe(null, container.decorated) == Description!string("singleton", "Singleton container", "A container that instantiates and keeps managed components until it is terminated"));

    assert(container.has(typeid(Describer!()).toString));
    assert(container.get(typeid(Describer!()).toString) is container);

    assert(container.has(typeid(IdentityDescriber!()).toString));
    assert(container.get(typeid(IdentityDescriber!()).toString) is main);

    assert(container.has(typeid(TypeDescriber!()).toString));
    assert(container.get(typeid(TypeDescriber!()).toString) is fallback);

    assert(container.has(typeid(StaticDescriber!()).toString));
    assert(container.get(typeid(StaticDescriber!()).toString) is containerDescriber);
}