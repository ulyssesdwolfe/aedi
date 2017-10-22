/**
This module implements annotation based configuration of containers.

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
module aermicioi.aedi.configurer.annotation.annotation;

public import aermicioi.aedi.factory.reference : lref, anonymous;

import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.allocator_aware;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.wrapper;
import aermicioi.aedi.container.container;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.reference;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.exception;
import aermicioi.util.traits;

import std.traits;
import std.meta;
import std.typecons;
import std.conv : to;
import std.algorithm;

/**
Annotation used to denote an aggregate that should be stored into an container.
**/
struct ComponentAnnotation {

    /**
    Constructs a factory for aggregate of type T

    Params:
    	T = the aggregate type
    	locator = locator used to extract needed dependencies for T

    Returns:
    	GenericFactory!T for objects
    	GenericFactory!(Wrapper!T) for structs
    **/
    GenericFactory!T factory(T)(Locator!() locator) {
        return new GenericFactoryImpl!(T)(locator);
    }
}

/**
ditto
**/
alias component = ComponentAnnotation;

/**
Annotation used to mark a constructor to be used for aggregate instantiation.

Params:
    Args = tuple of argument types for arguments to be passed into a constructor.
**/
struct ConstructorAnnotation(Args...) {
    Tuple!Args args;

    /**
    Constructor accepting a list of arguments, that will be passed to constructor.

    Params:
    	args = arguments passed to aggregate's constructor
    **/
    this(Args args) {
        this.args = args;
    }

    /**
    Constructs a constructor based factory for aggregate of type T

    Params:
    	T = the aggregate type
    	locator = locator used to extract needed dependencies for T

    Returns:
    	InstanceFactory!T for objects
    	InstanceFactory!(Wrapper!T) for structs
    **/
    InstanceFactory!T factoryContainer(T, string property)(Locator!() locator) {
        auto constructor = new ConstructorBasedFactory!(T, Args)(args.expand);
        constructor.locator = locator;

        return constructor;
    }
}

/**
ditto
**/
auto constructor(Args...)(Args args) {
    return ConstructorAnnotation!Args(args);
}

/**
Annotation used to mark a member to be called or set (in case of fields), with args passed to setter.

Note: if an overloaded method is annotated with Setter, the method from overload set that matches argument list in Setter annotation
will be called.

Params:
    Args = the argument types of arguments passed to method
**/
struct SetterAnnotation(Args...) {
    Tuple!Args args;

    /**
    Constructor accepting a list of arguments, that will be passed to method, or set to a field.

    Params:
    	args = arguments passed to aggregate's constructor
    **/
    this(Args args) {
        this.args = args;
    }

    /**
    Constructs a configurer that will call or set a member for aggregate of type T.

    Constructs a configurer that will call or set a member for aggregate of type T.
    In case when member is a method, it will be called with passed arguments.
    If method is an overload set, the method that matches argument list will be called.
    In case when member is a field, it will be set to first argument from Args list.

    Params:
    	T = the aggregate type
    	method = the member which setter will call or set.
    	locator = locator used to extract needed dependencies for T

    Returns:
    	PropertyConfigurer!T for objects
    	PropertyConfigurer!(Wrapper!T) for structs
    **/
    PropertyConfigurer!T factoryConfigurer(T, string method)(Locator!() locator)
        if (
            !isField!(T, method)
        ) {
        mixin assertObjectMethodCompatible!(T, method, Args);

        auto method = new MethodConfigurer!(T, method, Args)(args.expand);
        method.locator = locator;

        return method;
    }

    /**
    ditto
    **/
    PropertyConfigurer!T factoryConfigurer(T, string method)(Locator!() locator)
        if (
            isField!(T, method) &&
            (Args.length == 1)
        ) {
        mixin assertFieldCompatible!(T, method, Args);

        auto method = new FieldConfigurer!(T, method, Args[0])(args[0]);
        method.locator = locator;

        return method;
    }
}

/**
ditto
**/
auto setter(Args...)(Args args) {
    return SetterAnnotation!Args(args);
}

/**
Annotation that specifies a delegate to be used to instantiate aggregate.

Params:
	Z = the type of aggregate that will be returned by the delegate
	Args = type tuple of args that can be passed to delegate.
**/
struct CallbackFactoryAnnotation(Z, Dg, Args...)
    if ((is(Dg == Z delegate (IAllocator, Locator!(), Args)) || is(Dg == Z function (IAllocator, Locator!(), Args)))) {
    Tuple!Args args;
    Dg dg;

    /**
    Constructor accepting a factory delegate, and it's arguments.

    Params:
    	dg = delegate that will factory an aggregate
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
    }

    /**
    Constructs a factory that uses delegate to instantiate an aggregate of type T.

    Params:
    	T = the aggregate type
    	locator = locator used to extract needed dependencies for T, it is also passed to delegate as first argument.

    Returns:
    	InstanceFactory!T for objects
    	InstanceFactory!(Wrapper!T) for structs
    **/
    InstanceFactory!T factoryContainer(T, string p = "")(Locator!() locator)
        if (is(Z : T)) {
        auto callback = new CallbackFactory!(T, Dg, Args)(dg, args.expand);
        callback.locator = locator;

        return callback;
    }
}

/**
ditto
**/
auto fact(T, Args...)(T delegate(IAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T delegate(IAllocator, Locator!(), Args), Args)(dg, args);
}

/**
ditto
**/
auto fact(T, Args...)(T function(IAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T function(IAllocator, Locator!(), Args), Args)(dg, args);
}

/**
Annotation that specifies a delegate to be used to configure aggregate somehow.

Params:
	Z = the type of aggregate that will be returned by the delegate
	Args = type tuple of args that can be passed to delegate.
**/
struct CallbackConfigurerAnnotation(Z, Dg, Args...)
    if (
        is(Dg == void delegate (Locator!(), Z, Args)) ||
        is(Dg == void function (Locator!(), Z, Args)) ||
        is(Dg == void delegate (Locator!(), ref Z, Args)) ||
        is(Dg == void function (Locator!(), ref Z, Args))
    ){
    Tuple!Args args;
    Dg dg;

    /**
    Constructor accepting a configurer delegate, and it's arguments.

    Params:
    	dg = delegate that will be used to configure an aggregate
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
    }

    /**
    Constructs a configurer that uses delegate to configure an aggregate of type T.

    Params:
    	T = the aggregate type
    	locator = locator that can be used by delegate to extract some custom data.

    Returns:
    	PropertyConfigurer!T for objects
    	PropertyConfigurer!(Wrapper!T) for structs
    **/
    PropertyConfigurer!T factoryConfigurer(T, string p = "")(Locator!() locator)
        if (is(T : Z)) {
        auto callback = new CallbackConfigurer!(T, Dg, Args)(dg, args.expand);
        callback.locator = locator;

        return callback;
    }
}

/**
ditto
**/
auto callback(T, Args...)(void delegate (Locator!(), ref T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void delegate (Locator!(), ref T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void function (Locator!(), ref T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void function (Locator!(), ref T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void delegate (Locator!(), T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void delegate (Locator!(), T, Args), Args)(dg, args);
}

/**
ditto
**/
auto callback(T, Args...)(void function (Locator!(), T, Args) dg, Args args) {
    return CallbackConfigurerAnnotation!(T, void function (Locator!(), T, Args), Args)(dg, args);
}

/**
Annotation used to mark constructor or method for auto wiring.

Marking a method/constructor with autowired annotation will make container to call it with arguments fetched from
locator by types of them.

Note: even if a method/constructor from an overloaded set is marked with autowired annotation, the first method from overload set
will be used. Due to that autowired annotation is recommended to use on methods/constrcutors that are not overloaded.

**/
struct AutowiredAnnotation {
    PropertyConfigurer!T factoryConfigurer(T, string method)(Locator!() locator)
        if (
            !isField!(T, method) &&
            isSomeFunction!(getMember!(T, method))
        ) {

        alias params = Parameters!(__traits(getOverloads, T, method)[0]);
        auto references = tuple(staticMap!(toLref, params));

        auto method = new MethodConfigurer!(T, method, staticMap!(toLrefType, params))(references.expand);
        method.locator = locator;

        return method;
    }

    PropertyConfigurer!T factoryConfigurer(T, string property)(Locator!() locator)
        if (
            isField!(T, property)
        ) {

        alias paramType = typeof(getMember!(T, property));

        auto lref = toLref!paramType;
        auto method = new FieldConfigurer!(T, property, toLrefType!paramType)(lref);
        method.locator = locator;

        return method;
    }

    InstanceFactory!T factoryContainer(T, string property)(Locator!() locator) {
        alias params = Parameters!(__traits(getOverloads, T, "__ctor")[0]);
        auto references = tuple(staticMap!(toLref, params));

        auto method = new ConstructorBasedFactory!(T, staticMap!(toLrefType, params))(references.expand);
        method.locator = locator;

        return method;
    }
}

/**
ditto
**/
alias autowired = AutowiredAnnotation;

/**
An annotation used to provide custom identity for an object in container.
**/
struct QualifierAnnotation {
    string id;
}

/**
An annotation used to provide custom identity for an object in container.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    id = identity of object in container
**/
auto qualifier(string id) {
    return QualifierAnnotation(id);
}

/**
ditto
**/
QualifierAnnotation qualifier(string id)() {
    return QualifierAnnotation(id);
}

/**
An annotation used to provide custom identity for an object in container by some interface.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    I = identity of object in container
**/
QualifierAnnotation qualifier(I)() {
    return QualifierAnnotation(name!I);
}

/**
When objects are registered into an aggregate container, this annotation marks in which sub-container it is required to store.
**/
struct ContainedAnnotation {
    string id;
}

/**
When objects are registered into an aggregate container, this annotation marks in which sub-container it is required to store.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    id = identity of container where to store the object.
**/
auto contained(string id) {
    return ContainedAnnotation(id);
}
