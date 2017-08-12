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

class MockObject : MockInterface {
    
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
}

class MockFactory(T) : ObjectFactory {
    
    public {
        Locator!() locator_;
    }
    
    public {
        Object factory() {
            auto t = new T;
            
            return t;
        }
        
        @property {
            TypeInfo type() @safe nothrow {
            	return typeid(T);
            }
            
            MockFactory!T locator(Locator!() loc) {
                this.locator_ = loc;
                
                return this;
            }
        }
    }
}

class MockFailingFactory(T) : ObjectFactory {
    
    public {
        Locator!() locator_;
    }
    
    public {
        Object factory() {
            import aermicioi.aedi.exception.di_exception;
            throw new AediException("Well, I'll just fail everything.");
        }
        
        @property {
            TypeInfo type() @safe nothrow {
            	return typeid(T);
            }
            
            MockFailingFactory!T locator(Locator!() loc) {
                this.locator_ = loc;
                
                return this;
            }
        }
    }
}

class MockValueFactory(T) : Factory!T {
    public {
        Locator!() locator_;
    }
    
    public {
        T factory() {
            static if (is(T : Object)) {
                return new T();
            } else {
                return T();
            }
        }
        
        @property {
            TypeInfo type() @safe nothrow {
            	return typeid(T);
            }
            
            MockValueFactory!T locator(Locator!() loc) {
                this.locator_ = loc;
                
                return this;
            }
        }
    }
}

class CircularFactoryMock(T) : MockFactory!T {
    
    public {
        override Object factory() {
            auto t = new T;
            this.locator_.get("mock");
            
            return t;
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
        
        this() {
            
        }
        
        @constructor(20)
        this(ulong id) {
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
        
        Company id(ulong id) {
        	this.id_ = id;
        
        	return this;
        }
        
        ulong id() {
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
        
        @autowired
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
            ref Currency amount(ptrdiff_t amount) @safe nothrow {
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
        static this() {
            company = new Company(20);
        }
        
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
        
        static Company company() @safe nothrow {
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
        static this() {
            company = new Company(20);
        }
        
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
        
        static Company company() @safe nothrow {
        	return company_;
        }
        
        ref StructFixtureFactory job(Job job) @safe nothrow {
        	this.job_ = job;
        
        	return this;
        }
        
        Job job() @safe nothrow {
        	return this.job_;
        }
        
        static Currency basicPayment(ptrdiff_t amount) {
            return Currency(amount);
        }
        
        ref StructFixtureFactory currency(Currency currency) @safe nothrow {
        	this.currency_ = currency;
        
        	return this;
        }
        
        Currency currency() @safe nothrow {
        	return this.currency_;
        }
    }
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