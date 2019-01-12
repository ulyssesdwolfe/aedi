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
module aermicioi.aedi.container.aliasing_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.storage.alias_aware;

import std.range.interfaces;
import std.typecons;

/**
Decorating container adding ability to alias contained element a new identity.
**/
template AliasingContainer(T) {
    import std.meta;
    import std.traits;
    import aermicioi.aedi.util.traits;

    /**
    Set which the aliasing decorated will decorate for T. By default
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
                FactoryLocator!ObjectFactory
            ),
            partialSuffixed!(
                isDerived,
                Container
            )
        ),
        InterfacesTuple!T),
        Locator!(),
        AliasAware!string,
        Decorator!Container
    );

    /**
    Templated aliasing decorated.
    **/
    @safe class AliasingContainer : InheritanceSet {
        private {
            string[const(string)] aliasings;
        }

        public {
            import aermicioi.aedi.storage.decorator : MutableDecoratorMixin;
            mixin MutableDecoratorMixin!T;

            alias decorated this;

            static if (is(T : Container)) {
                import aermicioi.aedi.container.decorating_mixin : ContainerMixin;
                mixin ContainerMixin!(typeof(this));
            }

            static if (is(T : Storage!(ObjectFactory, string))) {
                /**
        		Set factory in decorated by identity.

        		Params:
        			identity = identity of factory.
        			element = factory that is to be saved in decorated.

        		Return:
        			AliasingContainer!T decorating decorated.
        		**/
                AliasingContainer!T set(ObjectFactory element, string identity) {
                    decorated.set(element, identity);

                    return this;
                }

                /**
                Remove factory from decorated with identity.

                Remove factory from decorated with identity.

                Params:
                	identity = the identity of factory to be removed.

            	Return:
            		AliasingContainer!T decorating decorated
                **/
                AliasingContainer!T remove(string identity) {
                    decorated.remove(identity);

                    return this;
                }
            }

            /**
            Alias an identity with alias_/

            Params:
            	identity = identity which will be aliased
            	alias_ = the new alias of identity.

            Returns:
            	AliasingContainer
            **/
            AliasingContainer link(string identity, string alias_) {

                this.aliasings[alias_] = identity;

                return this;
            }

            /**
            Removes alias.

            Params:
            	alias_ = alias to remove.

            Returns:
                this

            **/
            AliasingContainer unlink(string alias_) {
                this.aliasings.remove(alias_);

                return this;
            }

            /**
            Resolve the alias to an element identity.

            Params:
            	alias_ = the alias to an identity.
            Returns:
            	string the last found identity in alias chain.
            **/
            const(string) resolve(in string alias_) const {
                import std.typecons : Rebindable;
                Rebindable!(const(string)) aliased = alias_;

                while ((aliased in this.aliasings) !is null) {
                    aliased = this.aliasings[aliased];
                }

                return aliased;
            }

            static if (is(T : FactoryLocator!ObjectFactory)) {

                /**
                Get factory for constructed component identified by identity.

                Get factory for constructed component identified by identity.
                Params:
                	identity = the identity of component that factory constructs.

                Throws:
                	NotFoundException when factory for it is not found.

                Returns:
                	T the factory for constructed component.
                **/
                ObjectFactory getFactory(string identity) {
                    return this.decorated.getFactory(this.resolve(identity));
                }

                /**
                Get all factories available in container.

                Get all factories available in container.

                Returns:
                	InputRange!(Tuple!(T, string)) a tuple of factory => identity.
                **/
                InputRange!(Tuple!(ObjectFactory, string)) getFactories() {
                    return this.decorated.getFactories();
                }
            }

            /**
    		Get an Object that is associated with key.

    		Params:
    			identity = the element id.

    		Throws:
    			NotFoundException in case if the element wasn't found.

    		Returns:
    			Object element if it is available.
    		**/
            Object get(string identity) {
                return decorated.get(this.resolve(identity));
            }

            /**
            Check if an element is present in Locator by key id.

            Note:
            	This check should be done for elements that locator actually contains, and
            	not in chained locator.
            Params:
            	identity = identity of element.

        	Returns:
        		bool true if an element by key is present in Locator.
            **/
            bool has(in string identity) inout {
                return decorated_.has(this.resolve(identity));
            }

        }
    }
}
