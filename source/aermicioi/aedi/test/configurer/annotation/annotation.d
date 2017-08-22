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

module aermicioi.aedi.test.configurer.annotation;

import aermicioi.aedi.test.fixture;
import aermicioi.aedi;

unittest {
    auto container = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);

    container.componentScan!Company(parameters, "company.custom");
    container.componentScan!Employee(parameters);
    container.componentScan!Job();
    container.componentScan!Person();
    container.componentScan!Company();
    container.componentScan!(Identifiable!ulong, Person)();
    container.componentScan!StructFixtureFactory;
    
    container.instantiate();
    
    assert(container.locate!Company("company.custom") !is null);
    assert(container.locate!Employee !is null);
    assert(container.locate!Job() !is null);
    assert(container.locate!(Person)(name!(Identifiable!ulong)) !is null);
    
    assert(container.locate!StructFixtureFactory.job is container.locate!Job);
    assert(container.locate!StructFixtureFactory.person is container.locate!Person);
    assert(container.locate!StructFixtureFactory.employee is container.locate!Employee);
}

unittest {
    auto container = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);

    container.componentScan!Company(parameters);
    container.componentScan!Employee(parameters);
    container.componentScan!Person(parameters);
    
    container.instantiate();
}

unittest {
    auto first = new SingletonContainer;
    auto second = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    
    first.componentScan!(Company, Employee, Job, Person, Identifiable!ulong, Person)(parameters);
    second.componentScan!(Company, Employee, Job, Person, Identifiable!ulong, Person)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
}

unittest {
    
    auto first = new SingletonContainer;
    auto second = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);
    
    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
}

unittest {
    
    auto first = new SingletonContainer;
    auto second = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    import fixture_second = aermicioi.aedi.test.fixture_second;
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new fixture_second.Employee("Zack", cast(ubyte) 20));
    parameters.register(new fixture_second.Job("Magician", fixture_second.Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new fixture_second.Company);
    parameters.register(new fixture_second.Person);
    parameters.register(new Company);
    parameters.register(new Person);
    
    first.componentScan!(aermicioi.aedi.test.fixture, aermicioi.aedi.test.fixture_second)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture, aermicioi.aedi.test.fixture_second)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job != second.locate!Employee.job);
    assert(first.locate!Company.employees != second.locate!Company.employees);
    assert(first.locate!(fixture_second.Employee).job != second.locate!(fixture_second.Employee).job);
    assert(first.locate!(fixture_second.Company).employees != second.locate!(fixture_second.Company).employees);
}

unittest {
    auto first = new SingletonContainer;
    auto second = new SingletonContainer;
    auto parameters = new ObjectStorage!();
    
    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);
    
    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture)();
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!Employee.job != parameters.locate!Job);
}

unittest {
    auto container = new ApplicationContainer;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);

    container.componentScan!(Company)("company.custom");
    container.componentScan!(Identifiable!ulong, Employee);
    container.componentScan!(Employee)(parameters, "employee.custom"); 
    container.componentScan!Company(parameters);
    container.componentScan!Employee;
    container.componentScan!Job;
    
    container.instantiate();
    
    assert(container.locate!Company("company.custom").employees[0] != parameters.locate!Employee);
    assert(container.locate!Employee(name!(Identifiable!ulong)) != parameters.locate!Employee);
    assert(container.locate!Employee("employee.custom").job == parameters.locate!Job);
    assert(container.locate!Company.employees[0] == parameters.locate!Employee);
    assert(container.locate!Employee.job == container.locate!Job);
}

unittest {
    auto first = new ApplicationContainer;
    auto second = new ApplicationContainer;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);
    
    first.componentScan!(Identifiable!ulong, Employee)(parameters);
    first.componentScan!(Job);
    second.componentScan!(Identifiable!ulong, Company);
    second.componentScan!(Employee);
    second.componentScan!(Job);
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!Employee(name!(Identifiable!ulong)).job == parameters.locate!Job);
    assert(second.locate!Company(name!(Identifiable!ulong)).employees[0] != parameters.locate!Employee);
}

unittest {
    auto first = new ApplicationContainer;
    auto second = new ApplicationContainer;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);
    
    first.componentScan!(Company, Employee, Job, Identifiable!ulong, Company)(parameters);
    second.componentScan!(Company, Employee, Job, Identifiable!ulong, Company);
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(first.locate!Company != first.locate!Company(name!(Identifiable!ulong)));
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!Company != second.locate!Company(name!(Identifiable!ulong)));
}

unittest {
    auto first = new ApplicationContainer;
    auto second = new ApplicationContainer;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new Company);
    parameters.register(new Person);

    first.componentScan!(aermicioi.aedi.test.fixture)(parameters);
    second.componentScan!(aermicioi.aedi.test.fixture);
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
}


unittest {
    import s = aermicioi.aedi.test.fixture_second;

    auto first = new ApplicationContainer;
    auto second = new ApplicationContainer;
    auto parameters = new ObjectStorage!();

    parameters.register(new Employee("Zack", cast(ubyte) 20));
    parameters.register(new Job("Magician", Currency(49)));
    parameters.register("Simple name");
    parameters.register!ubyte(30);
    parameters.register(new s.Employee("Zack", cast(ubyte) 20));
    parameters.register(new s.Job("Magician", s.Currency(49)));
    parameters.register(new Company);
    parameters.register(new Person);
    parameters.register(new s.Company);
    parameters.register(new s.Person);
    
    first.componentScan!(
        aermicioi.aedi.test.fixture,
        aermicioi.aedi.test.fixture_second
    )(parameters);
    
    second.componentScan!(
        aermicioi.aedi.test.fixture,
        aermicioi.aedi.test.fixture_second
    );
    
    first.instantiate();
    second.instantiate();
    
    assert(first.locate!(Company).employees[0] == parameters.locate!Employee);
    assert(first.locate!Employee.job == parameters.locate!Job);
    assert(first.locate!(s.Company).employees[0] == parameters.locate!(s.Employee));
    assert(first.locate!(s.Employee).job == parameters.locate!(s.Job));
    
    assert(second.locate!(Company).employees[0] != second.locate!Employee);
    assert(second.locate!Employee.job == second.locate!Job);
    assert(second.locate!(s.Company).employees[0] == second.locate!(s.Employee));
    assert(second.locate!(s.Employee).job == second.locate!(s.Job));
}