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
module aermicioi.aedi.test.fixture_second;

import aermicioi.aedi.configurer.annotation;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.allocator_aware;

interface Identifiable(T) {
    public @property {
        T id();
    }
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
class Employee : Person {
    private {
        Company company_;
        Job job_;
    }

    public {
        this() {

        }

        @constructor("No autowired, sad", cast(ubyte) 01)
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
class Person : Identifiable!ulong {
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
class Job : Identifiable!ulong {
    private {
        string name_;
        Currency payment_;
        ulong id_;
    }

    public {
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

    }
}

@component
@fact(function (RCIAllocator alloc, Locator!() loc, Job job) {
    return new FixtureFactory(job);
}, new Job("Tested name", Currency(2000)))
@callback(function (Locator!() loc, FixtureFactory fact, Employee e) {
    fact.employee = e;
}, new Employee("Ahmad Akbenov", 20))
class FixtureFactory {
    private {
        static Company company_;
        Job job_;
    }

    public {
        static this() {
            company = new Company(20);
        }

        @fact(function (RCIAllocator alloc, Locator!() loc, Job job) {
            return new FixtureFactory(job);
        }, new Job("Tested name", Currency(2000)))
        this(Job job) {
            this.job = job;
            person = new Person("Ali Armen", 30);
        }

        @autowired
        Employee employee;

        @setter(lref!Person)
        Person person;

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
//Delegates that have no context, cannot exist, so do not attempt to use @fact with a delegate.
//@fact(delegate (Locator!() loc) {
//    return StructFixtureFactory(new Job("Tested name", Currency(2000)));
//})
@fact(function (RCIAllocator alloc, Locator!() loc) {
    return StructFixtureFactory(new Job("Tested name", Currency(2000)));
})
@callback(function (Locator!() loc, ref StructFixtureFactory fact, Currency c) {
    fact.currency = c;
}, Currency(200))
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
//        Delegates that have context of a class, cannot exist, so do not attempt to use @fact with a delegate.
//        @fact(delegate (Locator!() loc) {
//            return StructFixtureFactory(new Job("Tested name", Currency(2000)));
//        })
        @fact(function (RCIAllocator alloc, Locator!() loc) {
            return StructFixtureFactory(new Job("Tested name", Currency(2000)));
        })
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
struct Currency {
    private {
        ptrdiff_t amount_;
    }

    public {
        this(ptrdiff_t amount) {
            this.amount = amount;
        }

        @property {
            ref Currency amount(ptrdiff_t amount) @safe nothrow return scope {
            	this.amount_ = amount;

            	return this;
            }

            ptrdiff_t amount() @safe nothrow {
            	return this.amount_;
            }
        }
    }
}