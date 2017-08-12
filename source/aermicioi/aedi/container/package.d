/**
Defines interface for objects that are able to instantiate and manage lifetime for
instantiated objects. Provides a singleton, and prototype implementation of defined
interface.

The main task of an container container, is to manage the lifetime of 
objects contained in them. Therefore they can manage when an object registered
is created, how much it lives, and when it dies. This package provides containers 
for managed objects (singleton, and prototype for now). Singleton container
instantiates all registered objects at once, and keeps them alive until it itself
is destroyed/collected by garbage collector. Prototype on other hand, just creates
them and leave management of created objects to the rest of application.

See:
$(UL
    $(LI container.d -> contains the interfaces for containers. )
    )

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
	Alexandru Ermicioi
**/
module aermicioi.aedi.container;

public import aermicioi.aedi.container.container;
public import aermicioi.aedi.container.prototype_container;
public import aermicioi.aedi.container.singleton_container;
public import aermicioi.aedi.container.type_based_container;
public import aermicioi.aedi.container.switchable_container;
public import aermicioi.aedi.container.application_container;
public import aermicioi.aedi.container.subscribable_container;
public import aermicioi.aedi.container.value_container;
public import aermicioi.aedi.container.tuple_container;
public import aermicioi.aedi.container.aliasing_container;
