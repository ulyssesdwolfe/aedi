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
import std.experimental.allocator;
import std.experimental.allocator.gc_allocator;
import std.experimental.allocator.mmap_allocator;
import std.experimental.allocator.mallocator;

@safe:

/**
Check if T is instance of ComponentAnnotation
**/
enum bool isComponentAnnotation(T) = is(T : ComponentAnnotation);

/**
ditto
**/
enum bool isComponentAnnotation(alias T) = isComponentAnnotation!(toType!T);

/**
Annotation used to denote a component that should be stored into an container.
**/
struct ComponentAnnotation {

}

/**
ditto
**/
alias component = ComponentAnnotation;

/**
Check if T is instance of ValueAnnotation
**/
enum bool isValueAnnotation(T) = is(T : ValueAnnotation!Value, Value);

/**
ditto
**/
enum bool isValueAnnotation(alias T) = isValueAnnotation!(toType!T);

/**
Construct the instance using value provided in annotation

Params:
    value = value that should be component created with

**/
struct ValueAnnotation(Value) {

    Value value;
}

/**
ditto
**/
ValueAnnotation!T value(T)(T value) {
    return ValueAnnotation!T(value);
}

/**
Check if T is instance of AllocatorAnnotation
**/
enum bool isAllocatorAnnotation(T) = is(T : AllocatorAnnotation!X, X);

/**
ditto
**/
enum bool isAllocatorAnnotation(alias T) = isAllocatorAnnotation!(toType!T);

/**
Use allocator to allocate component.

Params:
    allocator = allocator used to allocate the component
**/
struct AllocatorAnnotation(T = RCIAllocator)
    if (!hasStaticMember!(T, "instance")) {

    T allocator;

    /**
    Get iallocator

    Returns:
        RCIAllocator
    **/
    RCIAllocator iallocator() {
        return this.allocator.allocatorObject;
    }
}

struct AllocatorAnnotation(T)
    if (hasStaticMember!(T, "instance")) {

    T allocator;

    /**
    Get iallocator

    Returns:
        RCIAllocator
    **/
    RCIAllocator iallocator() @trusted {
        return T.instance.allocatorObject;
    }
}

/**
ditto
**/
AllocatorAnnotation!T allocator(T)(T allocator) {
    return AllocatorAnnotation!T(allocator);
}

/**
ditto
**/
AllocatorAnnotation!T allocator(T : GCAllocator)() {
    return AllocatorAnnotation!T();
}

/**
ditto
**/
AllocatorAnnotation!T allocator(T : MmapAllocator)() {
    return AllocatorAnnotation!T();
}

/**
ditto
**/
AllocatorAnnotation!T allocator(T : Mallocator)() {
    return AllocatorAnnotation!T();
}

/**
Check if T is instance of ConstructorAnnotation
**/
enum bool isConstructorAnnotation(T) = is(T : ConstructorAnnotation!Z, Z...);

/**
ditto
**/
enum bool isConstructorAnnotation(alias T) = isConstructorAnnotation!(toType!T);
/**
Annotation used to mark a constructor to be used for component instantiation.

Params:
    Args = tuple of argument types for arguments to be passed into a constructor.
**/
struct ConstructorAnnotation(Args...) {
    Tuple!Args args;

    /**
    Constructor accepting a list of arguments, that will be passed to constructor.

    Params:
    	args = arguments passed to component's constructor
    **/
    this(Args args) {
        this.args = args;
    }
}

/**
ditto
**/
auto constructor(Args...)(Args args) {
    return ConstructorAnnotation!Args(args);
}

/**
Check if T is instance of SetterAnnotation
**/
enum bool isSetterAnnotation(T) = is(T : SetterAnnotation!Z, Z...);

/**
ditto
**/
enum bool isSetterAnnotation(alias T) = isSetterAnnotation!(toType!T);
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
    	args = arguments passed to component's constructor
    **/
    this(Args args) {
        this.args = args;
    }
}

/**
ditto
**/
auto setter(Args...)(Args args) {
    return SetterAnnotation!Args(args);
}

/**
Check if T is instance of CallbackFactoryAnnotation
**/
enum bool isCallbackFactoryAnnotation(T) = is(T : CallbackFactoryAnnotation!Z, Z...);

/**
ditto
**/
enum bool isCallbackFactoryAnnotation(alias T) = isCallbackFactoryAnnotation!(toType!T);
/**
Annotation that specifies a delegate to be used to instantiate component.

Params:
	Z = the type of component that will be returned by the delegate
	Args = type tuple of args that can be passed to delegate.
**/
struct CallbackFactoryAnnotation(Z, Dg, Args...)
    if ((is(Dg == Z delegate (RCIAllocator, Locator!(), Args)) || is(Dg == Z function (RCIAllocator, Locator!(), Args)))) {
    Tuple!Args args;
    Dg dg;

    /**
    Constructor accepting a factory delegate, and it's arguments.

    Params:
    	dg = delegate that will factory a component
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
    }
}

/**
ditto
**/
auto fact(T, Args...)(T delegate(RCIAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T delegate(RCIAllocator, Locator!(), Args), Args)(dg, args);
}

/**
ditto
**/
auto fact(T, Args...)(T function(RCIAllocator, Locator!(), Args) dg, Args args) {
    return CallbackFactoryAnnotation!(T, T function(RCIAllocator, Locator!(), Args), Args)(dg, args);
}

/**
Check if T is instance of CallbackConfigurerAnnotation
**/
enum bool isCallbackConfigurerAnnotation(T) = is(T : CallbackConfigurerAnnotation!Z, Z...);

/**
ditto
**/
enum bool isCallbackConfigurerAnnotation(alias T) = isCallbackConfigurerAnnotation!(toType!T);
/**
Annotation that specifies a delegate to be used to configure component somehow.

Params:
	Z = the type of component that will be returned by the delegate
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
    	dg = delegate that will be used to configure a component
    	args = list of arguments passed to delegate.
    **/
    this(Dg dg, ref Args args) {
        this.dg = dg;
        this.args = tuple(args);
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
Check if T is instance of AutowiredAnnotation
**/
enum bool isAutowiredAnnotation(T) = is(T : AutowiredAnnotation);

/**
ditto
**/
enum bool isAutowiredAnnotation(alias T) = isAutowiredAnnotation!(toType!T);

/**
Annotation used to mark constructor or method for auto wiring.

Marking a method/constructor with autowired annotation will make container to call it with arguments fetched from
locator by types of them.

Note: even if a method/constructor from an overloaded set is marked with autowired annotation, the first method from overload set
will be used. Due to that autowired annotation is recommended to use on methods/constrcutors that are not overloaded.

**/
struct AutowiredAnnotation {

}

/**
ditto
**/
alias autowired = AutowiredAnnotation;

/**
Check if T is instance of QualifierAnnotation
**/
enum bool isQualifierAnnotation(T) = is(T : QualifierAnnotation);

/**
ditto
**/
enum bool isQualifierAnnotation(alias T) = isQualifierAnnotation!(toType!T);
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
Check if T is instance of ContainedAnnotation
**/
enum bool isContainedAnnotation(T) = is(T : ContainedAnnotation);

/**
ditto
**/
enum bool isContainedAnnotation(alias T) = isContainedAnnotation!(toType!T);
/**
When objects are registered into a component container, this annotation marks in which sub-container it is required to store.
**/
struct ContainedAnnotation {
    string id;
}

/**
When objects are registered into a component container, this annotation marks in which sub-container it is required to store.

This function is a convenince function to automatically infer required types for underlying annotation.

Params:
    id = identity of container where to store the object.
**/
auto contained(string id) {
    return ContainedAnnotation(id);
}

/**
Check if T is instance of CallbackDestructor
**/
enum bool isCallbackDestructor(T) = is(T) && is(T == DefaultDestructor);

/**
ditto
**/
enum bool isCallbackDestructor(alias T) = is(typeof(T));

/**
Use callback stored in annotation to destroy a component of type T

Params:
    dg = callback used to destroy the component
    args = arguments passed to callback to destroy the component
**/
struct CallbackDestructor(T, Dg : void delegate(RCIAllocator, ref T destructable, Args), Args...) {
    Dg dg;
    Args args;
}

/**
ditto
**/
CallbackDestructor callbackDestructor(T, Dg : void delegate(RCIAllocator, ref T destructable, Args), Args...)(Dg dg, Args args) {
    return CallbackDestructor(dg, args);
}

/**
Check if T is instance of DestructorMethod
**/
enum bool isDestructorMethod(T) = is(T) && is(T == DefaultDestructor);

/**
ditto
**/
enum bool isDestructorMethod(alias T) = is(typeof(T));

/**
Use method from instance of type T to destroy a component of type Z

Params:
    method = method used to destroy component of type Z

**/
struct DestructorMethod(string method, T, Z, Args...) {
    Dg dg;
    Args args;
}

/**
ditto
**/
CallbackDestructor destructorMethod(string method, T, Z, Args...)() {
    return DestructorMethod(dg, args);
}