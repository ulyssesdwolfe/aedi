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
module aermicioi.aedi.container.switchable_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.container.decorating_mixin;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.storage.alias_aware;

import std.range.interfaces;
import std.typecons;

/**
Interface that allows object to be switchable in off and on state.
**/
interface Switchable {

    public @property {

    	/**
    	Get the state of object.

    	Get the state of object. Whether is enabled or not.

    	Returns:
        	bool true if enabled or false if not.
    	**/
    	inout(bool) enabled() @safe nothrow inout;

    	/**
    	Set the state of object.

    	Set the state of object. Whether is enabled or not.

    	Params:
        	enable = true to enable, false to disable.
    	**/
    	Switchable enabled(bool enable) @safe nothrow;
    }
}

/**
Templated switchable decorated.

Templated switchable decorated. This decorated will
decorate another decorated, and add switching logic
to it. Depending in which state (on/off) the switching
decorated is. It will instantiate if the decorated is on,
and not if decorated is in off mode. This decorated will
inherit following interfaces only and only if the
T also implements them:
    $(OL
        $(LI Storage!(ObjectFactory, string))
        $(LI Container)
        $(LI AliasAware!string)
    )
Decorated container must implement following interfaces:
    $(OL
        $(LI Locator!())
        $(LI MutableDecorator!T)
        $(LI Switchable)
    )

Params:
    T = The decorated that switchable decorated will decorate.

**/
template SwitchableContainer(T) {
    import std.meta;
    import std.traits;
    import aermicioi.util.traits;

    /**
    Set which the switchable decorated will decorate for T. By default
    Locator!() and Switchable is included.
    **/
    alias InheritanceSet = NoDuplicates!(Filter!(
        templateOr!(
            partialSuffixed!(
                isDerived,
                Storage!(ObjectFactory, string)
            ),
            partialSuffixed!(
                isDerived,
                AliasAware!string
            ),
            partialSuffixed!(
                isDerived,
                FactoryLocator!ObjectFactory
            ),
            partialSuffixed!(
                isDerived,
                Container
            )
        ),
        InterfacesTuple!T),
        Locator!(),
        MutableDecorator!T,
        Switchable,
    );

    /**
    Templated switchable decorated.
    **/
    class SwitchableContainer : InheritanceSet {
        private {
            T decorated_;

            bool enabled_;
        }

        public {

            /**
        	Set the state of decorated.

        	Set the state of decorated. Whether is enabled or disabled.

        	Params:
            	enabled = true to enable, false to disable.
        	**/
            SwitchableContainer!T enabled(bool enabled) @safe nothrow {
            	this.enabled_ = enabled;

            	return this;
            }

            /**
        	Get the state of decorated (enabled/disabled).

        	Get the state of decorated (enabled/disabled).

        	Returns:
            	bool true if enabled or false if not.
        	**/
            inout(bool) enabled() @safe nothrow inout {
            	return this.enabled_;
            }

            mixin MutableDecoratorMixin!T;

            static if (is(T : Container)) {

                /**
                Prepare decorated to be used.

                Prepare decorated to be used.

                Returns:
                	SwitchableContainer!T decorating decorated
                **/
                SwitchableContainer instantiate() {
                    if (enabled) {
                        decorated.instantiate();
                    }

                    return this;
                }

                /**
                Destruct all managed components.

                Destruct all managed components. The method denotes the end of container lifetime, and therefore destruction of all managed components
                by it.
                **/
                SwitchableContainer terminate() {
                    if (enabled) {
                        decorated.terminate();
                    }

                    return this;
                }
            }

            static if (is(T : Storage!(ObjectFactory, string))) {
                mixin StorageMixin!(typeof(this));
            }

            static if (is(T : AliasAware!string)) {
                /**
                Alias identity to an alias_.

                Params:
                	identity = originial identity which is to be aliased.
                	alias_ = alias of identity.

        		Returns:
        			SwitchableContainer!T decorating decorated
                **/
                SwitchableContainer!T link(string identity, string alias_) {
                    decorated.link(identity, alias_);

                    return this;
                }

                /**
                Removes alias.

                Params:
                	alias_ = alias to remove.

                Returns:
                    SwitchableContainer!T decorating decorated
                **/
                SwitchableContainer!T unlink(string alias_) {
                    decorated.unlink(alias_);

                    return this;
                }

                /**
                Resolve an alias to original identity, if possible.

                Params:
                	alias_ = alias of original identity

                Returns:
                	const(string) the last identity in alias chain if decorated is enabled, or alias_ when not.

                **/
                const(string) resolve(in string alias_) const {
                    if (enabled) {
                        return decorated_.resolve(alias_);
                    }

                    return alias_;
                }
            }

            static if (is(T : FactoryLocator!ObjectFactory)) {
                mixin FactoryLocatorMixin!(typeof(this));
            }

            /**
    		Get object that is associated with identity.

    		Params:
    			identity = the object identity.

    		Throws:
    			NotFoundException in case if the object wasn't found or decorated is not enabled.

    		Returns:
    			Object if it is available.
    		**/
            Object get(string identity) {
                if (enabled) {
                    return decorated.get(identity);
                }

                throw new NotFoundException("Component with id " ~ identity ~ " not found.");
            }

            /**
            Check if object is present in SwitchableContainer!T by key identity.

            Note:
            	This check should be done for elements that locator actually contains, and
            	not in chained locator (when locator is also a DelegatingLocator) for example.
            Params:
            	identity = identity of object.

        	Returns:
        		bool true if decorated is enabled and has object by identity.
            **/
            bool has(in string identity) inout {
                return enabled && decorated_.has(identity);
            }

        }
    }
}
