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
module aermicioi.aedi.configurer.register.context;

import aermicioi.aedi.configurer.register.configuration_context_factory;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.factory.generic_factory;
import aermicioi.aedi.factory.wrapping_factory;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.storage;
import std.experimental.allocator : RCIAllocator, theAllocator;
import std.traits;
import std.meta : AliasSeq;

@safe:

struct RegistrationContext(Policies...)
    if (Policies.length > 1) {
    /**
    Storage into which to store components;
    **/
    Storage!(ObjectFactory, string) storage;

    /**
    Locator used for fetching components dependencies;
    **/
    Locator!(Object, string) locator;

    /**
    Allocator used for registered components.
    **/
    RCIAllocator allocator;

    alias ConfigurableFactoryType(T) = ConfigurableFactory!(T, FactoryPolicyExtractor!Policies);

    ref typeof(this) initialize() {
        static foreach (Policy; Policies) {
            Policy.initialize(storage, locator, allocator);
        }

        return this;
    }

    /**
    Register a component of type T by identity, type, or interface it implements.

    Register a component of type T by identity, type, or interface it implements.

    Params:
        Interface = interface of registered component that it implements
        T = type of registered component
        identity = identity by which component is stored in storage

    Returns:
        GenericFactory!T factory for component for further configuration
    **/
    ConfigurableFactoryType!T register(T, string file = __FILE__, size_t line = __LINE__)(string identity) {
        ConfigurableFactoryType!T factory = new ConfigurableFactoryType!T();
        static if (is(typeof(factory) : Class!(ComponentType, FactoryPolicies), alias Class, ComponentType, FactoryPolicies...)) {
            static foreach (FactoryPolicy; FactoryPolicies) {
                static if (__traits(isSame, FactoryPolicy, StoragePolicy)) {
                    factory.storage = storage;
                    factory.identity = identity;
                }

                static if (__traits(isSame, FactoryPolicy, DecoratingFactoryPolicy)) {
                    factory.locator = locator;
                    factory.allocator = allocator;
                }

                static if (__traits(isSame, FactoryPolicy, RegistrationStorePolicy)) {
                    factory.file = file;
                    factory.line = line;
                }
            }
        }

        static foreach (Policy; Policies) {
            Policy.apply(factory);
        }

        return factory;
    }

    /**
    ditto
    **/
    ConfigurableFactoryType!T register(T, string file = __FILE__, size_t line = __LINE__)() {
        return register!(T, file, line)(fullyQualifiedName!T);
    }

    /**
    ditto
    **/
    ConfigurableFactoryType!T register(Interface, T : Interface, string file = __FILE__, size_t line = __LINE__)()
        if (!is(T == Interface)) {
        return register!(T, file, line)(fullyQualifiedName!Interface);
    }

    /**
    Register a component of type T by identity, type, or interface it implements with a default value.

    Register a component of type T by identity, type, or interface it implements with a default value.

    Params:
        Interface = interface of registered component that it implements
        T = type of registered component
        identity = identity by which component is stored in storage
        value = initial value of component;

    Returns:
        GenericFactory!T factory for component for further configuration
    **/
    ConfigurableFactoryType!T register(T, string file = __FILE__, size_t line = __LINE__)(auto ref T value, string identity) {
        import aermicioi.aedi.configurer.register.factory_configurer : val = value;

        ConfigurableFactoryType!T factory = register!(T, file, line)(identity);

        factory.val(value);

        return factory;
    }

    /**
    ditto
    **/
    ConfigurableFactoryType!T register(T, string file = __FILE__, size_t line = __LINE__)(auto ref T value)
        if (!is(T == string)) {

        return register!(T, file, line)(value, fullyQualifiedName!T);
    }

    /**
    ditto
    **/
    ConfigurableFactoryType!T register(Interface, T : Interface, string file = __FILE__, size_t line = __LINE__)(auto ref T value)
        if (!is(T == Interface)) {

        return register!(T, file, line)(value, fullyQualifiedName!Interface);
    }
}

/**
Policy responsible for creation of generic factory that will create component T.
**/
struct GenericFactoryPolicy {

    alias FactoryPolicy = DecoratingFactoryPolicy;

    static void initialize(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator) {

    }

    static void apply(Z : ConfigurableFactory!(T, Policies), T, Policies...)(Z factory) {
        factory.decorated = new GenericFactoryImpl!T(factory.locator);
        factory.decorated.allocator = factory.allocator;
    }
}

/**
Policy responsible for creation of factory wrapper suitable for storing into storage.
**/
struct WrappingFactoryPolicy {

    alias FactoryPolicy = WrapperStorePolicy;

    static void initialize(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator) {

    }

    static void apply(Z : ConfigurableFactory!(T, Policies), T, Policies...)(Z factory) {
        factory.wrapper = new WrappingFactory!(Factory!T)(factory);
    }
}

/**
Policy responsible for persisting wrapper into storage by some identity.
**/
struct PersistingFactoryPolicy {

    alias FactoryPolicy = StoragePolicy;

    static void initialize(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator) {

    }

    static void apply(Z : ConfigurableFactory!(T, Policies), T, Policies...)(Z factory) {
        factory.storage.set(factory.wrapper, factory.identity);
    }
}

/**
Start registering components using a storage and a locator.

Start registering components using a storage and a locator.

Params:
	storage = store registered components into it.
	locator = locator of dependencies for registered components
    allocator = default allocation strategy for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
RegistrationContext!Policies configure(Policies...)
    (Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator = theAllocator)
    if (Policies.length > 0) {
    return RegistrationContext!(Policies)(storage, locator, allocator).initialize();
}

/**
ditto
**/
RegistrationContext!Policies configure(Policies...)
    (Locator!(Object, string) locator, Storage!(ObjectFactory, string) storage, RCIAllocator allocator = theAllocator)
    if (Policies.length > 0) {
    return RegistrationContext!(Policies)(storage, locator, allocator).initialize();
}

/**
ditto
**/
RegistrationContext!(
    GenericFactoryPolicy,
    WrappingFactoryPolicy,
    DeferredFactoryPolicy,
    RegistrationAwarePolicy,
    PersistingFactoryPolicy
) configure(
        Storage!(ObjectFactory, string) storage,
        Locator!(Object, string) locator,
        RCIAllocator allocator = theAllocator)
{
    return storage.configure!(
        GenericFactoryPolicy,
        WrappingFactoryPolicy,
        DeferredFactoryPolicy,
        RegistrationAwarePolicy,
        PersistingFactoryPolicy)(locator, allocator);
}

/**
ditto
**/
RegistrationContext!(
    GenericFactoryPolicy,
    WrappingFactoryPolicy,
    DeferredFactoryPolicy,
    RegistrationAwarePolicy,
    PersistingFactoryPolicy
) configure(
        Locator!(Object, string) locator,
        Storage!(ObjectFactory, string) storage,
        RCIAllocator allocator = theAllocator)
{
    return storage.configure!(
        GenericFactoryPolicy,
        WrappingFactoryPolicy,
        DeferredFactoryPolicy,
        RegistrationAwarePolicy,
        PersistingFactoryPolicy)(locator, allocator);
}

/**
Start registering components using a container.

Start registering components using a container.

Params:
	container = storage and locator of components.
    allocator = default allocation strategy for registered components

Returns:
	RegistrationContext context with registration interface used to register components.
**/
auto configure(T)(T container, RCIAllocator allocator = theAllocator)
    if (is(T : Storage!(ObjectFactory, string)) && is(T : Locator!(Object, string))) {

    return configure(cast(Storage!(ObjectFactory, string)) container, container, allocator);
}

/**
Start registering components using a storage and a locator.

Start registering components using a storage and a locator.

Params:
	storage = identity of a storage located in locator used by registration context to store components.
	locator = locator of dependencies for registered components
    allocator = default allocation strategy for registered components

Returns:
	RegistrationContext!Policies context with registration interface used to register components.
**/
RegistrationContext!Policies configure(Policies...)(Locator!(Object, string) locator, string storage, RCIAllocator allocator = theAllocator)
    if (Policies.length > 1) {
    return configure!Policies(locator, locator.locate!(Storage!(ObjectFactory, string))(storage), allocator);
}

auto configure(Locator!(Object, string) locator, string storage, RCIAllocator allocator = theAllocator) {
    return configure(locator, locator.locate!(Storage!(ObjectFactory, string))(storage), allocator);
}

/**
Use locator/storage/allocator as basis for registering components.

Use locator/storage/allocator as basis for registering components.

Params:
    context = context for which to set new configured storage, or used locator
	storage = store registered components into it.
	locator = locator of dependencies for registered components
    allocator = allocator used as default allocation strategy for components.

Returns:
	RegistrationContext!Policies context with registration interface used to register components.
**/
RegistrationContext!Policies along(Policies...)(RegistrationContext!Policies context, Storage!(ObjectFactory, string) storage) {
    context.storage = storage;

    return context.initialize;
}

/**
ditto
**/
RegistrationContext!Policies along(Policies...)(RegistrationContext!Policies context, Locator!(Object, string) locator) {
    context.locator = locator;

    return context.initialize;
}

/**
ditto
**/
RegistrationContext!Policies along(Policies...)(RegistrationContext!Policies context, RCIAllocator allocator) {
    context.allocator = allocator;

    return context.initialize;
}

/**
Use storage as basis for registering components.

Use storage as basis for registering components.

Params:
    context = context for which to set new configured storage, or used locator
	storage = identity of a storage located in locator that should be used by registrationContext to store components.

Returns:
	RegistrationContext context with registration interface used to register components.
**/
RegistrationContext!Policies along(Policies...)(RegistrationContext!Policies context, string storage) {
    import aermicioi.aedi.exception.invalid_cast_exception : InvalidCastException;

    context.storage = context.locator.locate!(Storage!(ObjectFactory, string))(storage);

    return context.initialize;
}

/**
Apply a policy after existing policies in a registration context, or at a position if specified.

Params:
    context = context to which add a new policy
    at = position at whicht to apply policy
    Policy = new policy to inject into registration context

Returns:
    RegistrationContext!(Policies, Policy)
**/
RegistrationContext!(Policies, Policy) applying(Policy, Policies...)(RegistrationContext!Policies context) {
    return RegistrationContext!(Policies, Policy)(context.storage, context.locator, context.allocator).initialize;
}

/**
ditto
**/
RegistrationContext!(Policies[0 .. at], Policy, Policies[at .. $]) applying(size_t at, Policy, Policies...)(RegistrationContext!Policies context) {
    return RegistrationContext!(Policies[0 .. at], Policy, Policies[at .. $])(context.storage, context.locator, context.allocator).initialize;
}

/**
A registration interface for components already created.

Value registration context, provides a nice registration
api over Object containers, to store already instantiated
components into container.
**/
struct ValueRegistrationContext {

    public {
        /**
        Storage for already instantiated components.
        **/
        Storage!(Object, string) storage;

        /**
        Locator used for configuration purposes of features outside value container, yet related to the managed components.
        **/
        Locator!() locator;

        /**
        Register a component into value container by identity, type or interface.

        Register a component into value container by identity, type or interface.

        Params:
        	value = component to be registered in container
        	identity = identity of component in container
        	T = type of component
        	Interface = interface that T component implements

        Returns:
        	ValueRegistrationContext
        **/
        ValueContext register(T)(auto ref T value, string identity) {
            static if (is(T : Object)) {
                storage.set(value, identity);
            } else {
                import aermicioi.aedi.storage.wrapper : WrapperImpl;

                storage.set(new WrapperImpl!T(value), identity);
            }

            return ValueContext(identity, storage, locator);
        }

        /**
        ditto
        **/
        ValueContext register(T)(auto ref T value) {
            return register!T(value, fullyQualifiedName!T);
        }

        /**
        ditto
        **/
        ValueContext register(Interface, T : Interface)(auto ref T value) {
            return register!T(value, fullyQualifiedName!Interface);
        }
    }

    /**
    Value context useable for further configuration of container
    **/
    static struct ValueContext {

        /**
        Identity of managed component
        **/
        string identity;

        /**
        Storage of component
        **/
        Storage!(Object, string) storage;

        /**
        Locator of components. Used for configuration of features not directly related to value container.
        **/
        Locator!() locator;
    }
}

/**
Start registering instantiated components into a value container.

Start registering instantiated components into a value container.
Description

Params:
	storage = value container used to store instantiated components

Returns:
	ValueRegistrationContext context that provides register api, using storage to store registered components.
**/
ValueRegistrationContext configure(Storage!(Object, string) storage) {
    return ValueRegistrationContext(storage);
}

/**
Start registering instantiated components into a value container.

Start registering instantiated components into a value container.
Description

Params:
    locator = container that has the storage
	storage = identity of storage to use

Returns:
	ValueRegistrationContext context that provides register api, using storage to store registered components.
**/
ValueRegistrationContext configureValueContainer(Locator!() locator, string storage) {
    return ValueRegistrationContext(locator.locate!(Storage!(Object, string))(storage), locator);
}

/**
Adds registration location information in component's factory for easier debugging.

Params:
    context = original preconfigured registration context to use as basis.
**/
struct RegistrationAwarePolicy {

    alias FactoryPolicy = RegistrationStorePolicy;

    static void initialize(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator) {

    }

    static void apply(Z : ConfigurableFactory!(T, Policies), T, Policies...)(Z factory) {
        import aermicioi.aedi.factory.decorating_factory : RegistrationAwareDecoratingFactory;
        RegistrationAwareDecoratingFactory!Object wrapper = new RegistrationAwareDecoratingFactory!Object();
        wrapper.file = factory.file;
        wrapper.line = factory.line;

        wrapper.decorated = factory.wrapper;
        factory.wrapper = wrapper;
    }
}

struct DeferredFactoryPolicy {
    import aermicioi.aedi.factory.deferring_factory : DeferralContext;

    alias FactoryPolicy = AliasSeq!();

    static void initialize(Storage!(ObjectFactory, string) storage, Locator!(Object, string) locator, RCIAllocator allocator)
    in (storage !is null, "Storage is required for initialization of deferred policy.")
    in (locator !is null, "Locator is required for initialization of deferred policy.")
    in (!allocator.isNull, "Allocator is required for initialization of deferred policy.") {

    }

    static void apply(Z : ConfigurableFactory!(T, Policies), T, Policies...)(Z factory) {
        import aermicioi.aedi.exception.not_found_exception : NotFoundException;
        import aermicioi.aedi.factory.deferring_factory;
        import aermicioi.aedi.util.typecons : optional;
        import aermicioi.aedi.factory.reference : lref;

        if (factory.locator.has(fullyQualifiedName!DeferralContext)) {
            DeferringFactory!T deferring = new DeferringFactory!T(factory.decorated, factory.locator.locate!DeferralContext);
            factory.decorated = deferring;
        }
    }
}

private template FactoryPolicyExtractor(Policies...) {

    static if (Policies.length > 1) {
        alias FactoryPolicyExtractor = AliasSeq!(Policies[0].FactoryPolicy, FactoryPolicyExtractor!(Policies[1 .. $]));
    } else {
        alias FactoryPolicyExtractor = Policies[0].FactoryPolicy;
    }
}