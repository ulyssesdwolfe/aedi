/**
This module provides fluent api based configuration of components with custom
configuration errors.

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
module aermicioi.aedi.configurer.register.factory_configurer;


import aermicioi.aedi.configurer.register.configuration_context_factory;
import aermicioi.aedi.container.container;
import aermicioi.aedi.container.proxy_container;
import aermicioi.aedi.exception;
import aermicioi.aedi.factory;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.storage;
import aermicioi.util.traits;
public import aermicioi.aedi.factory.reference : lref, anonymous;

import std.meta;
import std.traits;

/**
Construct component using args.

Constructs component using args, that are passed to function.
The function will attempt to find at least one construct that
can accept passed argument list. If it fails, compiler will
produce error, with respective problems.
The argument list can contain beside simple values, references
to other components in locator. Arguments that are references to other components
won't be type checked.

Params:
	factory = the factory which will call constructor with passed arguments.
	args = a list of arguments that will be passed to constructor.

Returns:
	Z.
**/

auto construct(Z : InstanceFactoryAware!T, T, Args...)(Z factory, auto ref Args args) {
    factory.setInstanceFactory(constructorBasedFactory!T(args));

    return factory;
}

/**
Invoke T's method to create component of type X.

Configures component's factory to call method of factoryMethod with args,
in order to create component of type X.
In case when method is not a static member, the function requires to
pass a instance of factoryMethod or a reference to it.
The algorithm will check for args compatiblity with parameters of
factory method. No type check is done for arguments that are references
at compile time.

Params:
    factory = component's factory that is configured to call factoryMethod methods to spawn component
    factoryMethod = instance of factory method that will be used to instantiate component
    args = a list of arguments passed to factory method
    T = type of factoryMethod
    method = the method that is called from T to instantiate component
    W = either LocatorReference or T
    X = the return type of T.method member
**/
Z factoryMethod(T, string method, Z : InstanceFactoryAware!X, X, W, Args...)(Z factory, auto ref W factoryMethod, auto ref Args args)
    if (
        isNonStaticMethodCompatible!(T, method, Args) &&
        (is(W : T) || is(W : RuntimeReference))
    ) {
    factory.setInstanceFactory(factoryMethodBasedFactory!(T, method)(factoryMethod, args));

    return factory;
}

/**
ditto
**/
Z factoryMethod(T, string method, Z : InstanceFactoryAware!X, X, Args...)(Z factory, auto ref Args args)
    if (
        isStaticMethodCompatible!(T, method, Args)
    ) {

    factory.setInstanceFactory(factoryMethodBasedFactory!(T, method)(args));
    return factory;
}

/**
Invoke component's method with supplied args.

Configures component's factory to call specified method with passed args.
The function will check if the arguments passed to it are compatible with at
least one method from possible overload set.
The args list can contain references to other objects in locator as well, though
no type compatibility checks will be performed at compile time.

Params:
	factory = the factory which will be configured to invoke method.
	args = the arguments that will be used to invoke method on the new object.

Returns:
	Z.
**/
auto set(string property, Z : PropertyConfigurersAware!T, T, Args...)(Z factory, auto ref Args args)
    if (!isField!(T, property)) {
    mixin assertObjectMethodCompatible!(T, property, Args);

    factory.addPropertyConfigurer(methodConfigurer!(property, T)(args));

    return factory;
}

/**
Set component's public field to passed arg.

Configures component's factory to set specified field to passed arg.
The function will check if passed argument is type compatible with specified field.
The argument can be a reference as well. In case of argument being reference to another component
in container, no type compatiblity checking will be done.

Params
    factory = the factory which will be configured to set property.
	arg = the value of property to be set, or reference to component in container.

Returns:
	Z.
**/
auto set(string property, Z : PropertyConfigurersAware!T, T, Arg)(Z factory, auto ref Arg arg)
    if (isField!(T, property)) {
    mixin assertFieldCompatible!(T, property, Arg);

    factory.addPropertyConfigurer(fieldConfigurer!(property, T)(arg));

    return factory;
}

/**
Construct component using a delegate.

Constructs component using a delegate, and a list of arguments passed to delegate.

Params:
	factory = the factory which will use delegate to construct component.
	dg = the delegate that is responsible for creating component, given a list of arguments.
	args = the arguments that will be used by delegate to construct component.

Returns:
	Z.
**/
auto callback(Z : InstanceFactoryAware!T, T, Args...)(Z factory, T delegate(RCIAllocator, Locator!(), Args) dg, auto ref Args args) {
    factory.setInstanceFactory(callbackFactory!T(dg, args));

    return factory;
}

/**
ditto
**/
auto callback(Z : InstanceFactoryAware!T, T, Args...)(Z factory, T function(RCIAllocator, Locator!(), Args) dg, auto ref Args args) {
    factory.setInstanceFactory(callbackFactory!T(dg, args));

    return factory;
}

/**
Call dg on a component that is in configuration phase.

Call dg on component to perform some modifications, using args as input.

Params:
    factory = factory which will call dg with args.
    dg = delegate that will perform some modifications on component using passed args.
    args = a list of arguments passed to dg.

Returns:
    Z
**/
auto callback(Z : PropertyConfigurersAware!T, T, Args...)(Z factory, void delegate(Locator!(), T, Args) dg, auto ref Args args) {
    factory.addPropertyConfigurer(callbackConfigurer!T(dg, args));

    return factory;
}

/**
ditto
**/
auto callback(Z : PropertyConfigurersAware!T, T, Args...)(Z factory, void function(Locator!(), T, Args) dg, auto ref Args args) {
    factory.addPropertyConfigurer(callbackConfigurer!T(dg, args));

    return factory;
}

/**
ditto
**/
auto callback(Z : PropertyConfigurersAware!T, T, Args...)(Z factory, void delegate(Locator!(), ref T, Args) dg, auto ref Args args) {
    factory.addPropertyConfigurer(callbackConfigurer!T(dg, args));

    return factory;
}

/**
ditto
**/
auto callback(Z : PropertyConfigurersAware!T, T, Args...)(Z factory, void function(Locator!(), ref T, Args) dg, auto ref Args args) {
    factory.addPropertyConfigurer(callbackConfigurer!T(dg, args));

    return factory;
}

/**
Autowire a constructor, field or a method.

Autowire a constructor, field or a method.
A constructor is autowired only when no member is passed as argument.
When a member is passed as argument, it will be called with
a list of references (where args are identified by their type FQN) in
case when member is a function, or it will set the member to the
value that is located in container by it's type FQN.
Note: In case of constructors as well as methods that are overloaded,
the first constructor or method from overload set is selected to be autowired.

Params:
    T = the component type
    member = field or method of component T
    factory = ConfigurationContextFactory where to inject the constructor or method configurer

Returns:
    Z
**/
auto autowire(Z : InstanceFactoryAware!T, T)(Z factory)
    if (getMembersWithProtection!(T, "__ctor", "public").length > 0) {
    return factory.construct(staticMap!(toLref, Parameters!(getMembersWithProtection!(T, "__ctor", "public")[0])));
}

/**
ditto
**/
auto autowire(string member, Z : PropertyConfigurersAware!T, T)(Z factory)
    if (getMembersWithProtection!(T, member, "public").length > 0) {
    return factory.set!(member)(staticMap!(toLref, Parameters!(getMembersWithProtection!(T, member, "public")[0])));
}

/**
ditto
**/
auto autowire(string member, Z : PropertyConfigurersAware!T, T)(Z factory)
    if (isField!(T, member)) {
    return factory.set!(member)(lref!(typeof(getMember!(T, member))));
}

/**
Instantiates a component using a value as basis.

Instantiates a component using a value as basis.
As a consequence, any reference based type will
point to same content when it is instantiated
multiple times.

Params:
    T = the component type
    factory = ConfigurationContextFactory where to inject the constructor or method configurer
    value = default value used to instantiate component
**/
auto value(Z : InstanceFactoryAware!T, T)(Z factory, auto ref T value) {
    return factory.setInstanceFactory(new ValueInstanceFactory!T(value));
}

/**
Instantiates a component using as basis some third party factory.

Params:
    T = the type of component that is to be configured
    factory = factory that uses the parent factory for component instantiation
    delegated = the factory used by factory to instantiate an object.
**/
auto parent(Z : InstanceFactoryAware!T, T, X : Factory!W, W : T)(Z factory, X delegated) {
    return factory.setInstanceFactory(new DelegatingInstanceFactory!(T, W)(delegated));
}
/**
Tag constructed component with some information.

Tag constructed component with some information.
Description

Params:
	factory = factory for constructed component
	tag = tag with which to tag factory.

Returns:
	factory
**/
auto tag(W : ConfigurationContextFactory!T, T, Z)(W factory, auto ref Z tag) {

    auto taggable = findDecorator!(Taggable!Z, ObjectFactoryDecorator)(factory.wrapper);

    if (taggable is null) {
        auto taggableDecorator = new TaggableFactoryDecorator!(Object, Z);
        taggableDecorator.decorated = factory.wrapper;
        factory.wrapper = taggableDecorator;

        taggable = taggableDecorator;
        factory.storage.set(factory.wrapper, factory.identity);
    }

    taggable.tag(tag);

    return factory;
}

/**
Mark constructed object to be provided through a proxy instead of directly doing so.
Object will be proxied only in case when the storage where it is stored support
storing of proxy object factories.

Params:
	factory = factory for constructed object

Returns:
	factory
**/
auto proxy(Z : ConfigurationContextFactory!T, T)(Z factory) {
    import aermicioi.aedi.factory.proxy_factory : ProxyFactory, ProxyObjectFactory;
    import aermicioi.aedi.container.proxy_container : ProxyContainer;

    auto proxyAware = cast(ProxyContainer) factory.storage;
    if (proxyAware !is null) {
        proxyAware.set(
            new ProxyObjectWrappingFactory!T(
                new ProxyFactory!T(factory.identity, proxyAware.decorated)
            ),
            factory.identity,
        );
    }

    return factory;
}

/**
Use delegate T for destruction of component.

Params:
    factory = component factory which will use delegate to destroy component
    dg = destruction delegate
    args = optional arguments to delegate

Returns:
    factory
**/
auto destructor(Z : InstanceDestructorAware!T, T, Args...)(
    Z factory,
    void delegate(RCIAllocator, ref T, Args) dg,
    Args args
) {
    factory.setInstanceDestructor(callbackInstanceDestructor!T(dg, args));

    return factory;
}

/**
Use method of destructor to destroy component.

Use method of destructor to destroy component. By convention it is assumed that first argument is destroyed compnent followed by
optional arguments.

Params:
    method = destructor's method used to destroy component
    factory = component factory
    destructor = actual destructor that will destroy object
    args = arguments passed to destructor
Returns:
    factory
**/
auto destructor(string method, X, Z : InstanceDestructorAware!T, T, Args...)(
    Z factory,
    X destructor,
    Args args
) {
    factory.setInstanceDestructor(factoryMethodInstanceDestructor!(T, method, X, Args)(destructor, args));

    return factory;
}

/**
ditto
**/
auto destructor(string method, X, Z : InstanceDestructorAware!T, T, Args...)(
    Z factory,
    Args args
) {
    factory.setInstanceDestructor(factoryMethodInstanceDestructor!(T, method, X, Args)(args));

    return factory;
}

/**
Configure factory to defer configuration for later time using deffered executioner stored in locator by defferedExecutionerIdentity or
by DefferedExecutioner interface.

Configure factory to defer configuration for later time using deffered executioner stored in locator by defferedExecutionerIdentity.
Factory has to implement DefferredExecutionerAware interface in order for it to be configured with deffered executioner, otherwise
the factory will be ignored.

Params:
    factory = factory that will defer configuration.
    defferedExecutionerIdentity = identity of executioner that will execute deffered actions.

Returns:
    factory
**/
auto defferredConfiguration(Z : ConfigurationContextFactory!T, T)(Z factory, string defferedExecutionerIdentity) {
    auto defferedExecutioinerAware = cast(DefferredExecutionerAware) factory.decorated;
    if ((defferedExecutioinerAware !is null) && (factory.locator.has(defferedExecutionerIdentity))) {

        defferedExecutioinerAware.executioner = factory.locator.locate!DefferredExecutioner(defferedExecutionerIdentity);
    }

    return factory;
}

/**
ditto
**/
auto defferedConfiguration(Z : ConfigurationContextFactory!T, T)(Z factory) {
    return factory.defferredConfiguration(fullyQualifiedName!DefferredExecutioner);
}

/**
Configure factory to defer construction for later time using deffered executioner stored in locator by defferedExecutionerIdentity or
by DefferedExecutioner interface.

Configure factory to defer construction for later time using deffered executioner stored in locator by defferedExecutionerIdentity or
by DefferedExecutioner interface. Any factory will be wrapped in DefferedProxyWrapper factory that will supply proxy component instead of
original and defer construction of component, in case when component is possible to construct.

Params:
    factory = factory that will defer construction.
    defferedExecutionerIdentity = identity of executioner that will execute deffered actions.

Returns:
    factory
**/
auto defferredConstruction(Z : ConfigurationContextFactory!T, T : Object)(Z factory, string defferedExecutionerIdentity) {
    if (factory.locator.has(defferedExecutionerIdentity)) {

        auto proxy = new DefferedProxyWrapper!(Factory!T)(factory.decorated);
        factory.wrapper.decorated = proxy;
        proxy.executioner = factory.locator.locate!DefferredExecutioner;
    }

    return factory;
}

/**
ditto
**/
auto defferredConstruction(Z : ConfigurationContextFactory!T, T)(Z factory) {
    return factory.defferredConfiguration(fullyQualifiedName!DefferredExecutioner);
}

/**
ditto
**/
auto defferredConstruction(Z : ConfigurationContextFactory!T, T)(Z factory, string defferedExecutionerIdentity) {

    return factory;
}