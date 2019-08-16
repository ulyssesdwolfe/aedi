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
module aermicioi.aedi.test.fixture;

import aermicioi.aedi.configurer.annotation;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory.factory;

interface MockInterface {
    int imethod(int arg1, int arg2);
}

interface MockTotallyNotInheritedInterface {
    int iNot(int iPain);
}

class CircularMockObject : MockInterface {

    int property;

    CircularMockObject circularDependency_;

    int imethod(int arg1, int arg2) {
        property = arg1 - arg2;

        return property;
    }

    /**
    Set circularDependency

    Params:
        circularDependency = the triggering dependency.

    Returns:
        typeof(this)
    **/
    typeof(this) circularDependency(CircularMockObject circularDependency) @safe nothrow pure {
        this.circularDependency_ = circularDependency;

        return this;
    }

    /**
    Get circularDependency

    Returns:
        CircularMockObject
    **/
    CircularMockObject circularDependency() @safe nothrow pure {
        return this.circularDependency_;
    }
}

class MockCircularConstructionObject {
    Object dependency_;

    this(Object dependency) {
        this.dependency = dependency;
    }

    @property {
        /**
        Set dependency

        Params:
            dependency = the circular dependency

        Returns:
            typeof(this)
        **/
        typeof(this) dependency(Object dependency) @safe nothrow pure {
            this.dependency_ = dependency;

            return this;
        }

        /**
        Get dependency

        Returns:
            Object
        **/
        Object dependency() @safe nothrow pure {
            return this.dependency_;
        }
    }
}

class MockObject : MockInterface {

    int property;

    int imethod(int arg1, int arg2) {
        property = arg1 - arg2;

        return property;
    }

    int method(int arg1, int arg3) {
        property = arg1 + arg3;

        return property;
    }

    int propertino(int property) {
        return this.property = property;
    }

    int nasty() {
        throw new Exception("Something bad occurred");
    }

    this() {

    }

    this(int property) {
        this.property = property;
    }
}

extern(C++) {

    interface MockExternInterface {
        int imethod(int arg1, int arg2);
    }

    class MockExternObject : MockExternInterface {
        int property;

        int imethod(int arg1, int arg2) {
            property = arg1 - arg2;

            return property;
        }

        int method(int arg1, int arg2) {
            property = arg1 + arg2;

            return property;
        }

        int nasty() {
            throw new Exception("Something bad occurred");
        }

        this() {

        }

        this(int property) {
            this.property = property;
        }
    }
}

struct MockStruct {

    int property;

    int method(int arg1, int arg2) {
        property = arg1 + arg2;

        return property;
    }

    int nasty() {
        throw new Exception("Something bad occurred");
    }
}

class MockObjectFactoryMethod {

    int property;

    MockObject factoryObject() {
        return new MockObject(property);
    }

    MockStruct factoryStruct() {
        return MockStruct(property);
    }

    static MockObject staticFactoryObject(int property) {
        return new MockObject(property);
    }

    static MockStruct staticFactoryStruct(int property) {
        return MockStruct(property);
    }

    void destructObject(MockObject object) {
        object.property = 1;
    }

    void destructStruct(ref MockStruct strct) {
        strct.property = 2;
        // HAHA destroy a struct, so funny, so funny. Nope, here should lie code responsible for preparint struct for destruction.
        // Resource deallocation and so on.
    }

    static void staticDestructObject(MockObject object) {
        object.property = 3;
    }

    static void staticDestructStruct(ref MockStruct strct) {
        strct.property = 4;

        // HAHA destroy a struct, so funny, so funny. Nope, here should lie code responsible for preparint struct for destruction.
        // Resource deallocation and so on.
    }
}

@safe class MockFactory(T) : ObjectFactory {
    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin;
    mixin AllocatorAwareMixin!(typeof(this));

    public {
        Locator!() locator_;
    }

    public {
        this() {
            this.allocator = theAllocator;
        }

        Object factory() @trusted {

            return this.allocator.make!T();
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref Object component) @trusted {
            destroy(component);
        }

        @property {
            TypeInfo type() @safe nothrow const {
            	return typeid(T);
            }

            MockFactory!T locator(Locator!() loc) {
                this.locator_ = loc;

                return this;
            }
        }
    }
}

@safe class MockFailingFactory(T) : ObjectFactory {
    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin;
    mixin AllocatorAwareMixin!(typeof(this));

    public {
        Locator!() locator_;
    }

    public {
        Object factory() @safe {
            import aermicioi.aedi.exception.di_exception;
            throw new AediException("Well, I'll just fail everything.", null);
        }

        void destruct(ref Object destruct) @trusted {
            destroy(destruct);
        }

        @property {
            TypeInfo type() @safe nothrow const {
            	return typeid(T);
            }

            MockFailingFactory!T locator(Locator!() loc) {
                this.locator_ = loc;

                return this;
            }
        }
    }
}

@safe class MockValueFactory(T) : Factory!T {
    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin;
    mixin AllocatorAwareMixin!(typeof(this));

    public {
        Locator!() locator_;
    }

    public {
        T factory() @trusted {
            static if (is(T : Object)) {
                return new T();
            } else {
                return T();
            }
        }

        /**
        Destructs a component of type T.

        Params:
            component = component that is to ve destroyed.

        Returns:

        **/
        void destruct(ref T component) @trusted {
            static if (is(T : Object)) {
                destroy(component);
            }
        }

        @property {
            TypeInfo type() @safe nothrow const {
            	return typeid(T);
            }

            MockValueFactory!T locator(Locator!() loc) {
                this.locator_ = loc;

                return this;
            }
        }
    }
}

@safe class CircularFactoryMock(T) : MockFactory!T, Factory!T {
    import std.experimental.allocator : RCIAllocator;

    Object fetched;
    string referenced = "mock";

    public {
        override T factory() @trusted {
            auto t = new T;
            this.fetched = this.locator_.get(this.referenced);

            return t;
        }

        void destruct(ref T component) @safe {
            Object obj = component;
            super.destruct(obj);
        }

        alias destruct = MockFactory!T.destruct;

        override TypeInfo type() @safe nothrow const {
            return typeid(T);
        }

        override CircularFactoryMock!T allocator(RCIAllocator allocator) {
            super.allocator = allocator;

            return this;
        }
    }
}

@safe class MockLocator : Locator!() {
    import aermicioi.aedi.storage.allocator_aware : AllocatorAwareMixin;

    public {
        /**
		Get a Type that is associated with key.

		Params:
			identity = the element id.

		Throws:
			NotFoundException in case if the element wasn't found.

		Returns:
			Type element if it is available.
		**/
        Object get(string identity) {
            return null;
        }

        /**
        Check if an element is present in Locator by key id.

        Note:
        	This check should be done for elements that locator actually contains, and
        	not in chained locator.
        Params:
        	identity = identity of element.

    	Returns:
    		bool true if an element by key is present in Locator.
        **/
        bool has(in string identity) inout {
            return false;
        }
    }
}

//==================fixtures with more sane names================

interface Identifiable(T) {
    public @property {
        T id();
    }
}

interface Nameable {
    string name() @safe nothrow;
}

interface Payable {
    Currency payment();
}

@component
class Company : Identifiable!ulong {
    private {
        Employee[] employees_;
        ulong id_;
    }

    public {

        this() @safe {

        }

        @constructor(20)
        this(ulong id) @safe {
            this.id = id;
        }

        override bool opEquals(Object obj) {
            return super.opEquals(obj);
        }

        bool opEquals(Company company) {
            return
                company.id == this.id;
        }

        @property {
            Company employees(Employee[] employees) {
            	this.employees_ = employees;

            	return this;
            }

            Employee[] employees() {
            	return this.employees_;
            }

        }

        @setter(lref!Employee)
        Company addEmployee(Employee employee) {
            this.employees_ ~= employee;

            return this;
        }

        Company id(ulong id) @safe {
        	this.id_ = id;

        	return this;
        }

        ulong id() @safe {
        	return this.id_;
        }

    }
}

@component
@contained("prototype")
class Employee : Person {
    private {
        Company company_;
        Job job_;
    }

    public {
        this() {

        }

        @constructor("Simple as toad", cast(ubyte) 10)
        this(string name, ubyte age) {
            super(name, age);
        }

        this(string name, ubyte age, Job job) {
            super(name, age);
            this.job = job;
        }

        /**
        A bug is present with getProtection traits, that segfaults
        the compiler, when it is invoked on a method that has an
        overload set imported from parent class.
        **/
        override bool opEquals(Object obj) {
            return super.opEquals(obj);
        }

        override bool opEquals(Person obj) {
            return super.opEquals(obj);
        }

        bool opEquals(Employee employee) {
            return
                (cast(Person) employee == cast(Person) this) &&
                (employee.job == this.job);
        }
    }

    public @property {

        Employee company(Company company) {
        	this.company_ = company;

        	return this;
        }

        Company company() {
        	return this.company_;
        }

        @autowired
        Employee job(Job job) {
        	this.job_ = job;

        	return this;
        }

        Job job() {
        	return this.job_;
        }
    }
}

@component
@contained("prototype")
class Person : Identifiable!ulong, Nameable {
    private {
        ubyte age_;
        string name_;
        string surname_;
        ulong id_;
    }

    public {
        this() {

        }

        this(string name, ubyte age) {
            this.name = name;
            this.age = age;
        }

        override bool opEquals(Object obj) {
            return super.opEquals(obj);
        }

        bool opEquals(Person person) {
            return
                (person.name == this.name) &&
                (person.age == this.age) &&
                (person.id == this.id) &&
                (person.surname == this.surname);
        }
    }

    public @property {
        Person id(ulong id) {
        	this.id_ = id;

        	return this;
        }

        ulong id() {
        	return this.id_;
        }

        @setter(cast(ubyte) 10)
        Person age(ubyte age) {
        	this.age_ = age;

        	return this;
        }

        ubyte age() {
        	return this.age_;
        }

        @setter("A simple name")
        Person name(string name) {
        	this.name_ = name;

        	return this;
        }

        string name() {
        	return this.name_;
        }

        @setter("surname.parameter")
        Person surname(string surname) {
        	this.surname_ = surname;

        	return this;
        }

        string surname() {
        	return this.surname_;
        }

    }
}

@component
class Job : Identifiable!ulong, Nameable, Payable {
    private {
        string name_;
        Currency payment_;
        ulong id_;
    }

    public {
        Company company;

        this() {

        }

        this(string name, Currency payment) {
            this.name = name;
            this.payment = payment;
        }

        override bool opEquals(Object obj) {
            return super.opEquals(obj);
        }

        bool opEquals(Job jb) {
            return
                (jb.name == this.name) &&
                (jb.payment == this.payment);
        }
    }

    public @property {

        Job id(ulong id) {
        	this.id_ = id;

        	return this;
        }

        ulong id() {
        	return this.id_;
        }

        @setter("Simple name")
        Job name(string name) {
        	this.name_ = name;

        	return this;
        }

        string name() {
        	return this.name_;
        }

        @setter(Currency(2000UL))
        Job payment(Currency payment) {
        	this.payment_ = payment;

        	return this;
        }

        Currency payment() {
        	return this.payment_;
        }

        Currency averagePayment;
    }
}

@component
struct Currency {
    import std.traits;
    public {
        ptrdiff_t amount_;

        this(ptrdiff_t amount) {
            this.amount = amount;
        }

        @property {
            @setter(cast(ptrdiff_t) 100)
            ref Currency amount(ptrdiff_t amount) @safe nothrow return scope {
            	this.amount_ = amount;

            	return this;
            }

            ptrdiff_t amount() @safe nothrow {
            	return this.amount_;
            }
        }

        bool opEquals(T)(T amount)
            if (isNumeric!T) {
            return this.amount == amount;
        }

        bool opEquals(Currency currency) {
            return this.amount == currency.amount;
        }
    }
}

@component
class FixtureFactory {
    private {
        static Company company_;
        Job job_;
    }

    public {
        @autowired
        this(Job job) {
            this.job = job;
        }

        @autowired
        Employee employee = new Employee("Andy Dandy", 99);

        @setter(lref!Person)
        Person person = new Person("Ali Armen", 30);

        @autowired
        static void company(Company company) @safe nothrow {
        	company_ = company;
        }

        static Company company() @safe {
            if (company_ is null) {
                company_ = new Company(20);
            }

        	return company_;
        }

        FixtureFactory job(Job job) @safe nothrow {
        	this.job_ = job;

        	return this;
        }

        Job job() @safe nothrow {
        	return this.job_;
        }
    }
}

@component
struct StructFixtureFactory {
    private {
        static Company company_;
        Job job_;
        Currency currency_;
    }

    public {

        @constructor(lref!Job)
        this(Job job) {
            this.job = job;
            person = new Person("Ali Armen", 30);
        }

        @autowired
        Employee employee;

        @setter(lref!Person)
        Person person;

        @setter(lref!Company)
        static void company(Company company) @safe nothrow {
        	company_ = company;
        }

        static Company company() @safe {
            if (company_ is null) {
                company_ = new Company(20);
            }

        	return company_;
        }

        ref StructFixtureFactory job(Job job) @safe nothrow return scope {
        	this.job_ = job;

        	return this;
        }

        Job job() @safe nothrow {
        	return this.job_;
        }

        static Currency basicPayment(ptrdiff_t amount) {
            return Currency(amount);
        }

        ref StructFixtureFactory currency(Currency currency) @safe nothrow return scope {
        	this.currency_ = currency;

        	return this;
        }

        Currency currency() @safe nothrow {
        	return this.currency_;
        }
    }
}

@component
@qualifier!Person() // Be warned, without parantheses, compiler will return instantiated function and not it's return type.
class QualifiedPerson : Person {

}

/**
A simple model that is to be proxied.
Note: Currently autoimplement fails, on objects that are implementing interfaces.
**/
class ProxyablePerson : Identifiable!ulong {
    private {
        ubyte age_;
        string name_;
        string surname_;
        ulong id_;
    }

    public {
        this() {

        }

        this(string name, ubyte age) {
            this.name = name;
            this.age = age;
        }

        override bool opEquals(Object obj) {
            return super.opEquals(obj);
        }

        bool opEquals(Person person) {
            return
                (person.name == this.name) &&
                (person.age == this.age) &&
                (person.id == this.id) &&
                (person.surname == this.surname);
        }
    }

    public @property {
        ProxyablePerson id(ulong id) {
        	this.id_ = id;

        	return this;
        }

        ulong id() {
        	return this.id_;
        }

        @setter(cast(ubyte) 10)
        ProxyablePerson age(ubyte age) {
        	this.age_ = age;

        	return this;
        }

        ubyte age() {
        	return this.age_;
        }

        @setter("A simple name")
        ProxyablePerson name(string name) {
        	this.name_ = name;

        	return this;
        }

        string name() {
        	return this.name_;
        }

        @setter("surname.parameter")
        ProxyablePerson surname(string surname) {
        	this.surname_ = surname;

        	return this;
        }

        string surname() {
        	return this.surname_;
        }

    }
}

union Union {
    ubyte a;
    uint b;
    ulong c;
    float d;
    double e;
    StructFixtureFactory f;
}