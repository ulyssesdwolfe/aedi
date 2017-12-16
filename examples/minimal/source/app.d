/**
Aedi, a dependency injection framework.

Aedi is a dependency injection framework. It does provide a set of containers that do
IoC, and an interface to configure application components (structs, objects, etc.) managed by framework.

Aim:
The aim of library is to provide a dependency injection solution that is
feature rich, easy to use, easy to learn, and easy to extend up to your needs.

Usage:
The process of configuring components using Aedi consists of following steps:

$(UL
    $(LI Create a container )
    $(LI Register an application component. Any data (struct, object, union, etc) is treated as application component. )
    $(LI Write a wiring configuration )
    $(LI Repeat process for other components. )
    $(LI Boot container )
)

Following code example shows the fastest way to create and use an IoC container.

-------------------
import aermicioi.aedi;
import std.stdio;

/++
A struct that should be managed by container.
++/
struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

/++
Size of a car.
++/
struct Size {

    ulong width;
    ulong height;
    ulong length;
}

/++
A class representing a car.
++/
class Car {

    public {
        Color color; // Car color
        Size size; // Car size
    }
}

void print(Car car) {
    "You bought a new car with following specs:".writeln;
    writeln("Size:\t", car.size;
    writeln("Color:\t", car.color);
}

void main() {
    SingletonContainer container = singleton(); // 1. Create a container.
    scope(exit) container.terminate(); // 6. Finish and cleanup container. Always call it at the end of application.

    with (container.configure) {

        register!Car // 2. Register an application component.
            .construct(lref!Size) // 3. Bind dependencies to it.
            .set!"color"(lref!Color);

        register!Color // 4. Repeat process for other components.
            .set!"r"(cast(ubyte) 0)
            .set!"g"(cast(ubyte) 255)
            .set!"b"(cast(ubyte) 0);

        register!Size
            .set!"width"(200UL)
            .set!"height"(150UL)
            .set!"length"(500UL);
    }

    container.instantiate(); // 5. Boot container.

    container.locate!Car.print; // 5. Start using registered components.
}
-------------------

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
module app;

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

void print(Color color) {
    writeln("Color is:\t", color);
}

void main() {
    SingletonContainer container = singleton(); // Creating container that will manage a color
    scope(exit) container.terminate(); // Destruction and deallocation of components managed by container.

    with (container.configure) {

        register!Color // Register color into container.
            .set!"r"(cast(ubyte) 250) // Set red color to 250
            .set!"g"(cast(ubyte) 210) // Set green color to 210
            .set!"b"(cast(ubyte) 255); // Set blue color to 255
    }

    container.instantiate(); // Boot container (or prepare managed code/data).

    container.locate!Color.print; // Get color from container and print it.
}