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
module aermicioi.aedi.container.proxy_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.container.decorating_mixin;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.factory.proxy_factory;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.factory.factory;
import std.range;
import std.typecons;
import std.meta;
import std.traits;
import aermicioi.util.traits;

/**
TODO: Add description of what this is and why it was designed as such.
**/
@safe interface ProxyContainer : Container, Storage!(ProxyObjectFactory, string),
    Decorator!(Locator!())
{

}

/**
Templated switchable container.

Templated switchable container. This container will
decorate another container, and add switching logic
to it. Depending in which state (on/off) the switching
container is. It will instantiate if the container is on,
and not if container is in off mode. This container will
inherit following interfaces only and only if the
T also implements them:
    $(OL
        $(LI Storage!(ObjectFactory, string))
        $(LI Container)
        $(LI AliasAware!string)
    )

Params:
    T = The container that switchable container will decorate.

**/
template ProxyContainerImpl(T)
{
    /**
    Set which the switchable container will decorate for T. By default
    Locator!() and Switchable is included.
    **/
    alias InheritanceSet =
        NoDuplicates!(
            Filter!(
                templateOr!(
                    partialSuffixed!(
                        isDerived,
                        Storage!(ObjectFactory,
                        string)
                    ),
                    partialSuffixed!(
                        isDerived,
                        AliasAware!string
                    ),
                    partialSuffixed!(
                        isDerived,
                        FactoryLocator!ObjectFactory
                    )
                ),
                InterfacesTuple!T
            ),
            ProxyContainer,
            MutableDecorator!T,
            Decorator!Container
        );

    /**
    Templated proxy container.
    **/
    @safe class ProxyContainerImpl : InheritanceSet
    {
        private
        {
            T decorated_;

            ObjectStorage!(ProxyObjectFactory, string) proxyFactories;
            ObjectStorage!(Object, string) proxies;
        }

        public
        {

            /**
             * Default constructor for ProxyContainerImpl
            **/
            this() {

                this.proxyFactories = new ObjectStorage!(ProxyObjectFactory, string);
                this.proxies = new ObjectStorage!(Object, string);
            }

            mixin MutableDecoratorMixin!T;

            /**
            * Set object factory
            *
            * Params:
            * 	factory = factory for a object that is to be managed by prototype container.
            *   identity = identity by which a factory is identified
            * Returns:
            * 	typeof(this)
            **/
            ProxyContainerImpl set(ProxyObjectFactory factory, string identity)
            {
                this.proxyFactories.set(factory, identity);

                return this;
            }

            static if (is(T : Container))
            {

                /**
                Prepare container to be used.

                Prepare container to be used.

                Returns:
                	ProxyContainer decorating container
                **/
                ProxyContainerImpl instantiate()
                {
                    decorated.instantiate();

                    return this;
                }

                /**
                Destruct all managed components.

                Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
                by it.
                **/
                ProxyContainerImpl terminate() {

                    foreach (pair; this.proxies.contents.byKeyValue) {
                        this.proxyFactories.get(pair.key).destruct(pair.value);
                    }

                    (() @trusted scope => this.proxies.contents.clear)();

                    return this;
                }
            }

            static if (is(T : Storage!(ObjectFactory, string)))
            {
                /**
        		Set factory in container by identity.

        		Params:
        			identity = identity of factory.
        			element = factory that is to be saved in container.

        		Return:
        			ProxyContainer decorating container.
        		**/
                ProxyContainerImpl set(ObjectFactory element, string identity)
                {
                    decorated.set(element, identity);

                    return this;
                }

                /**
                Remove factory from container with identity.

                Remove factory from container with identity.

                Params:
                	identity = the identity of factory to be removed.

            	Return:
            		ProxyContainer decorating container
                **/
                ProxyContainerImpl remove(string identity)
                {
                    if (this.proxies.has(identity)) {
                        auto temporary = this.proxies.get(identity);
                        this.proxyFactories.get(identity).destruct(temporary);
                        this.proxies.remove(identity);
                    }

                    this.decorated.remove(identity);
                    this.proxyFactories.remove(identity);

                    return this;
                }
            }
            else
            {
                /**
                Remove factory from container with identity.

                Remove factory from container with identity.

                Params:
                	identity = the identity of factory to be removed.

            	Return:
            		ProxyContainer decorating container
                **/
                ProxyContainerImpl remove(string identity)
                {
                    if (this.proxies.has(identity)) {
                        auto temporary = this.proxies.get(identity);
                        this.proxyFactories.get(identity).destruct(temporary);
                        this.proxies.remove(identity);
                    }

                    this.proxyFactories.remove(identity);

                    return this;
                }
            }

            static if (is(T : AliasAware!string))
            {
                /**
                Alias identity to an alias_.

                Params:
                	identity = originial identity which is to be aliased.
                	alias_ = alias of identity.

        		Returns:
        			ProxyContainer decorating container
                **/
                ProxyContainerImpl link(string identity, string alias_)
                {
                    this.decorated.link(identity, alias_);
                    this.proxyFactories.link(identity, alias_);

                    return this;
                }

                /**
                Removes alias.

                Params:
                	alias_ = alias to remove.

                Returns:
                    ProxyContainer decorating container
                **/
                ProxyContainerImpl unlink(string alias_)
                {
                    this.decorated.unlink(alias_);
                    this.proxyFactories.unlink(alias_);

                    return this;
                }

                /**
                Resolve an alias to original identity, if possible.

                Params:
                	alias_ = alias of original identity

                Returns:
                	const(string) the last identity in alias chain if container is enabled, or alias_ when not.

                **/
                const(string) resolve(in string alias_) const
                {
                    return this.proxyFactories.resolve(alias_);
                }
            }

            static if (is(T : FactoryLocator!ObjectFactory))
            {
                mixin FactoryLocatorMixin!(typeof(this));
            }

            /**
    		Get object that is associated with identity.

    		Params:
    			identity = the object identity.

    		Throws:
    			NotFoundException in case if the object wasn't found or container is not enabled.

    		Returns:
    			Object if it is available.
    		**/
            Object get(string identity)
            {
                this.proxies.set(proxyFactories.get(identity).factory(), identity);

                return this.proxies.get(identity);
            }

            /**
            Check if object is present in ProxyContainer by key identity.

            Note:
            	This check should be done for elements that locator actually contains, and
            	not in chained locator (when locator is also a DelegatingLocator) for example.
            Params:
            	identity = identity of object.

        	Returns:
        		bool true if container is enabled and has object by identity.
            **/
            bool has(in string identity) inout
            {
                return proxyFactories.has(identity);
            }
        }
    }
}
