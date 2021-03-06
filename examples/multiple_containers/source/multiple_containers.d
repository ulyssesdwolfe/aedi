/**
Aedi, a dependency injection library.

Aedi is a dependency injection library. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.)

Aim:

The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

In most simple applications, a single container, like singleton or prototype one might be enough,
for using. Having a set of singletons constructed on behalf of a developer is convenient, yet there
are occurences a single container is not enough. For example when, a set of components rely on a
particular dependency, and more specifically, the dependency they rely upon, should not be shared
across reliant components. In another case, a set of components are stored in a database, in serialized
form, and they are used as dependencies for other components from application.

In such cases use of a single container like singleton or prototype is not enough, since one set
of components should be created by using normal frameworks means, and another set needs to be
fetched from a database, or should not be shared to all dependent components. To solve this problem,
AEDI framework, allows container to be joined and used together, for creation of components. A
component in such a joint container, having a dependency on a prototype component, will have it’s
requirement fullfilled without a problem.

Using as an example car simulation app, the company decided to add a set ”tires” to simulated
cars. For a particular car, each tire installed in it has same properties as other installed in same car.
Registering 4 times same tire is not cost effective. Instead of it, it is better to register component
into a prototype container and use component to supply 4 instances of a tire to a particular car.
Example below shows how two or more containers can be joined together, configured with components,
and used to instantiate required components.
----------------
auto container = aggregate( // Create a joint container hosting other two containers
        singleton(), "singleton", // Create singleton container, and store it in joint container by "singleton" identity
        prototype(), "prototype" // Create prototype container, and store it in joint container by "prototype" identity
    );

with (container.configure("singleton")) { // Configure singleton container

    // ...

    register!Car
        .autowire
        .autowire!"color"
        .set!"frontLeft"(lref!Tire)
        .set!"frontRight"(lref!Tire)
        .set!"backLeft"(lref!Tire)
        .set!"backRight"(lref!Tire);
}

with (container.configure("prototype")) { // Configure prototype container

    register!Tire // Registering Tire into "prototype" container used by aggregate container
        .set!"size"(17)
        .set!"pressure"(3.0)
        .set!"vendor"("divine tire");
}

//...
----------------
To join one or more containers together, an aggregate container must be created that will host
both of them under the hood. Once aggregate container has all of joint containers registered in it,
the process of registering components takes place.
To register components in joint container, pass the identity of subcontainer (container in joint container)
to $(D_INLINECODE configure) as an argument, and register components for selected subcontainer.
The $(D_INLINECODE configure) function applied to joint container in $(D_INLINECODE with ()) statement
creates a configuration context, that stores the container where components are stored, and
container from which dependencies for those components should be fetched.
In case of joint container, and singleton subcontainer, singleton subcontainer acts as storage while
joint container is used as source for dependencies of registered components.

In the result, the car simulator will be able to use a car, that has 4 different instances of a tire.
Output below shows the constructed car by joint containers.
-----------------
Uuh, what a nice car, Electric car with following specs:
Size:	Size(200, 150, 300)
Color:	Color(0, 0, 0)
Engine:	app.ElectricEngine
Tire front left:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31180
Tire front right:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C311C0
Tire back left: 	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31200
Tire back right:	Tire(17 inch, 3 atm, divine tire)	 located at memory 7FB560C31240
-----------------

Notice that each tire is a different object, hence everything is working as we
expected!

Try this example, modify it, play with it to understand how compositing can
help in designing your application.

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

module multiple_containers;

import aermicioi.aedi;
import std.stdio;

/**
A struct that should be managed by container.
**/
struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

/**
Size of a car.
**/
struct Size {

    ulong width;
    ulong height;
    ulong length;
}

/**
Interface for engines.

An engine should implement it, in order to be installable in a car.
**/
interface Engine {

    public {

        void turnOn();
        void run();
        void turnOff();
    }
}

/**
A concrete implementation of Engine that uses gasoline for propelling.
**/
class GasolineEngine : Engine {

    public {

        void turnOn() {
            writeln("pururukVrooomVrrr");

        }

        void run() {
            writeln("vrooom");
        }

        void turnOff() {
            writeln("vrrrPrrft");
        }
    }
}

/**
A concrete implementation of Engine that uses diesel for propelling.
**/
class DieselEngine : Engine {

    public {

        void turnOn() {
            writeln("pururukVruumVrrr");

        }

        void run() {
            writeln("vruum");
        }

        void turnOff() {
            writeln("vrrrPft");
        }
    }
}

/**
A concrete implementation of Engine that uses electricity for propelling.
**/
class ElectricEngine : Engine {
    public {

        void turnOn() {
            writeln("pzt");

        }

        void run() {
            writeln("vvvvvvvvv");
        }

        void turnOff() {
            writeln("tzp");
        }
    }
}

/**
Tire, what it can represent else?
**/
class Tire {
    private {
        int size_;
        float pressure_;
        string vendor_;
    }

    public @property {
        Tire size(int size) @safe nothrow {
        	this.size_ = size;

        	return this;
        }

        int size() @safe nothrow {
        	return this.size_;
        }

        Tire pressure(float pressure) @safe nothrow {
        	this.pressure_ = pressure;

        	return this;
        }

        float pressure() @safe nothrow {
        	return this.pressure_;
        }

        Tire vendor(string vendor) @safe nothrow {
        	this.vendor_ = vendor;

        	return this;
        }

        string vendor() @safe nothrow {
        	return this.vendor_;
        }
    }

    public override string toString() {
        import std.algorithm;
        import std.range;
        import std.conv;
        import std.utf;

        return only("Tire(", this.size.to!string, " inch, ", this.pressure.to!string, " atm, ", this.vendor, ")")
            .joiner
            .byChar
            .array;
    }
}

/**
A class representing a car.
**/
class Car {

    private {
        Color color_; // Car color
        Size size_; // Car size
        Engine engine_; // Car engine

        Tire frontLeft_;
        Tire frontRight_;
        Tire backLeft_;
        Tire backRight_;
    }

    public {

        /**
        Constructor of car.

        Constructs a car with a set of sizes. A car cannot of course have
        undefined sizes, so we should provide it during construction.

        Params:
            size = size of a car.
        **/
        this(Size size, Engine engine) {
            this.size_ = size;
            this.engine = engine;
        }

        @property {

            /**
            Set color of car

            Set color of car. A car can live with undefined color (physics allow it).

            Params:
            	color = color of a car.

            Returns:
            	Car
            **/
            Car color(Color color) @safe nothrow {
            	this.color_ = color;

            	return this;
            }

            Color color() @safe nothrow {
            	return this.color_;
            }

            Size size() @safe nothrow {
            	return this.size_;
            }

            /**
            Set engine used in car.

            Params:
            	engine = engine used in car to propel it.

            Returns:
            	Car
            **/
            Car engine(Engine engine) @safe nothrow {
            	this.engine_ = engine;

            	return this;
            }

            Engine engine() @safe nothrow {
            	return this.engine_;
            }

            Car frontLeft(Tire frontLeft) @safe nothrow {
            	this.frontLeft_ = frontLeft;

            	return this;
            }

            Tire frontLeft() @safe nothrow {
            	return this.frontLeft_;
            }

            Car frontRight(Tire frontRight) @safe nothrow {
            	this.frontRight_ = frontRight;

            	return this;
            }

            Tire frontRight() @safe nothrow {
            	return this.frontRight_;
            }

            Car backLeft(Tire backLeft) @safe nothrow {
            	this.backLeft_ = backLeft;

            	return this;
            }

            Tire backLeft() @safe nothrow {
            	return this.backLeft_;
            }

            Car backRight(Tire backRight) @safe nothrow {
            	this.backRight_ = backRight;

            	return this;
            }

            Tire backRight() @safe nothrow {
            	return this.backRight_;
            }

        }

        void start() {
            engine.turnOn();
        }

        void run() {
            engine.run();
        }

        void stop() {
            engine.turnOff();
        }
    }
}

/**
A manufacturer of cars.
**/
class CarManufacturer {

    public {
        Car manufacture(Size size) {
            return new Car(size, new DieselEngine()); // Manufacture a car.
        }
    }
}

void drive(Car car, string name) {
    writeln("Uuh, what a nice car, ", name," with following specs:");
    writeln("Size:\t", car.size());
    writeln("Color:\t", car.color());
    writeln("Engine:\t", car.engine());
    writeln("Tire front left:\t", car.frontLeft(), "\t located at memory ", cast(void*) car.frontLeft());
    writeln("Tire front right:\t", car.frontRight(), "\t located at memory ", cast(void*) car.frontRight());
    writeln("Tire back left: \t", car.backLeft(), "\t located at memory ", cast(void*) car.backLeft());
    writeln("Tire back right:\t", car.backRight(), "\t located at memory ", cast(void*) car.backRight());
}

void main() {
    auto container = aggregate( // Create a joint container hosting other two containers
        singleton(), "singleton", // Create singleton container, and store it in joint container by "singleton" identity
        prototype(), "prototype" // Create prototype container, and store it in joint container by "prototype" identity
    );

    scope(exit) container.terminate();

    with (container.configure("singleton")) { // Configure singleton container
        register!Color; // Let's register a default implementation of Color

        register!Color("color.green") // Register "green" color into container.
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);

        register!Size // Let's register default implementation of a Size
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(300UL);

        register!Size("size.sedan") // Register a size of a generic "sedan" into container
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(500UL);

        register!(Engine, ElectricEngine);

        register!Car
            .autowire
            .autowire!"color"
            .set!"frontLeft"(lref!Tire)
            .set!"frontRight"(lref!Tire)
            .set!"backLeft"(lref!Tire)
            .set!"backRight"(lref!Tire);
    }

    with (container.configure("prototype")) { // Configure prototype container

        register!Tire // Registering Tire into "prototype" container used by aggregate container
            .set!"size"(17)
            .set!"pressure"(3.0)
            .set!"vendor"("divine tire");
    }

    container.instantiate(); // Boot container (or prepare managed code/data).

    container.locate!Car.drive("Electric car");
}