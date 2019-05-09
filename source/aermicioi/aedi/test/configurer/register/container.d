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
    Alexandru Ermicioi
**/
module aermicioi.aedi.test.configurer.register.container;

import aermicioi.aedi.configurer.register.container;
import aermicioi.aedi.container;

unittest
{
    auto container = singleton();

    assert(typeid(container) is typeid(SingletonContainer));
}

unittest
{
    auto container = prototype();

    assert(typeid(container) is typeid(PrototypeContainer));
}

unittest
{
    auto container = values();

    assert(typeid(container) is typeid(ValueContainer));
}

unittest
{
    auto container = switchable(values());

    assert(typeid(container) is typeid(SwitchableContainer!(ValueContainer)));
}

unittest
{
    auto container = subscribable(values());

    assert(typeid(container) is typeid(SubscribableContainer!ValueContainer));
}

unittest
{
    auto container = typed(singleton());

    assert(typeid(container) is typeid(TypeBasedContainer!SingletonContainer));
}

unittest
{
    auto container = aliasing(values());

    assert(typeid(container) is typeid(AliasingContainer!ValueContainer));
}

unittest
{
    auto container = deffered(singleton());

    assert(typeid(container) is typeid(DefferedContainer!SingletonContainer));
}

unittest
{
    auto container = gcRegistered(singleton());

    assert(typeid(container) is typeid(GcRegisteringContainer!SingletonContainer));
}

unittest
{
    import aermicioi.aedi.storage.locator : locate;
    import aermicioi.aedi.factory.generic_factory : DefferredExecutioner;
    auto container = deffered(singleton(), "deff");

    assert(container.locate!DefferredExecutioner("deff") is container.executioner);
}

unittest
{
    auto container = container(values(), values());

    assert(typeid(container) is typeid(TupleContainer!(ValueContainer, ValueContainer)));
}

unittest
{
    auto container = aggregate(values(), "first.one", values(), "second.one");

    assert(typeid(container) is typeid(AggregateContainer));
}

unittest
{
    auto container = singleton().describing();

    assert(typeid(container) is typeid(DescribingContainer!SingletonContainer));
}