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
module aermicioi.aedi.container.type_based_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.alias_aware;
import aermicioi.aedi.storage.decorator;
import aermicioi.aedi.storage.storage;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.exception.not_found_exception;
import aermicioi.aedi.factory.factory;
import aermicioi.util.traits;

import std.algorithm;
import std.array;
import std.range;
import std.typecons;
import std.traits;
import std.meta;
import std.container.rbtree;

/**
A decorating container that can provide for requested
base class or interface, one implementor of those.
This decorated will inherit following interfaces if
and only if T also implements them:
    $(OL
        $(LI AliasAware!string)
        $(LI FactoryLocator!ObjectFactory)
    )
Decorated container must implement following interfaces:
    $(OL
        $(LI Container)
        $(LI Storage!(ObjectFactory, string))
        $(LI MutableDecorator!T)
        $(LI Decorator!Container)
    )

Params:
    T = The decorated that switchable decorated will decorate.
**/
template TypeBasedContainer(T) {

    /**
    Set which the type based container will decorate for T container.
    **/
    alias InheritanceSet =
        NoDuplicates!(
            Container,
            Storage!(ObjectFactory, string),
            MutableDecorator!T,
            Decorator!Container,
            Filter!(
                templateOr!(
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
            )
        );

    @safe class TypeBasedContainer : InheritanceSet {

        private {
            ObjectStorage!(RedBlackTree!(string), string) candidates;
        }

        public {
            this() {
                this.candidates = new ObjectStorage!(RedBlackTree!string, string);
            }

            mixin MutableDecoratorMixin!T;

            import aermicioi.aedi.container.decorating_mixin : ContainerMixin;
            mixin ContainerMixin!(typeof(this));

            /**
    		Save an object factory in TypeBasedContainer by identity.

    		Save an object factory in TypeBasedContainer by identity.
    		The object factory, and subsequent objects are registered as candidates for use for
    		any interface or base class they implement, when no suitable solution
    		is found in decorated container.

    		Params:
    			identity = identity of object factory in TypeBasedContainer.
    			factory = object factory which is to be saved in TypeBasedContainer.

    		Return:
    			TypeBasedContainer
    		**/
            TypeBasedContainer set(ObjectFactory factory, string identity) {
                decorated.set(factory, identity);

                ClassInfo info = cast(ClassInfo) factory.type;
                if (info !is null) {
                    info.crawlClassInfo(
                        (TypeInfo_Class crawled) @safe {
                            if (!this.candidates.has(crawled.toString())) {
                                this.candidates.set(new RedBlackTree!string, crawled.toString());
                            }

                            this.candidates.get(crawled.toString()).insert(identity);
                        }
                    );
                }

                return this;
            }

            /**
            Remove an object from TypeBasedContainer with identity.

            Remove an object from TypeBasedContainer with identity.
            It will remove the candidate from any interface or base class it
            does implement.

            Params:
            	identity = the identity of object to be removed.

        	Return:
        		TypeBasedContainer
            **/
            TypeBasedContainer remove(string identity) @trusted {
                decorated.remove(identity);

                foreach (pair; this.candidates.contents.byKeyValue.array) {
                    pair.value.removeKey(identity);

                    if (pair.value.empty) {
                        this.candidates.remove(pair.key);
                    }
                }

                return this;
            }

            /**
    		Get an object that is associated with identity.

    		Get an object that is associated with identity.
    		If no object associated by identity in decorated container
    		is found, a search for a solution in list of candidates is
    		done, and if found, first candidate is used as substitution
    		for serving the requested object.

    		Params:
    			identity = object identity in decorated.

    		Throws:
    			NotFoundException in case if no object was found.

    		Returns:
    			Object if it is available.
    		**/
            Object get(string identity) {
                if (this.decorated.has(identity)) {
                    return this.decorated.get(identity);
                }

                if (this.candidates.has(identity)) {
                    return
                    this.decorated.get(
                        this.candidates.get(identity).front
                    );
                }

                throw new NotFoundException("Component with id " ~ identity ~ " not found.");
            }

            /**
            Check if an object is present in TypeBasedContainer by identity.

            Check if an object is present in TypeBasedContainer by identity.
            If no object is available in decorated container, a candidate
            is searched through list of candidates, and if found, true
            is returned.

            Params:
            	identity = identity of object.

        	Returns:
        		bool true if an object by identity is present in TypeBasedContainer.
            **/
            bool has(in string identity) inout {
                if (this.decorated_.has(identity)) {
                    return true;
                }

                return this.candidates.has(identity);
            }

            static if (is(T : AliasAware!string)) {
                /**
                Alias a key to an alias_.

                Params:
                	identity = the originial identity which is to be aliased.
                	alias_ = the alias of identity.

        		Returns:
        			this
                **/
                TypeBasedContainer link(string identity, string alias_) {
                    this.decorated.link(identity, alias_);

                    return this;
                }

                /**
                Removes alias.

                Params:
                	alias_ = alias to remove.

                Returns:
                    this

                **/
                TypeBasedContainer unlink(string alias_) {
                    this.decorated.unlink(alias_);

                    return this;
                }

                /**
                Resolve an alias to original identity, if possible.

                Params:
                	alias_ = alias of original identity

                Returns:
                	Type the last identity in alias chain.

                **/
                const(string) resolve(in string alias_) const {
                    return this.decorated_.resolve(alias_);
                }
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
                	ObjectFactory the factory for constructed component.
                **/
                ObjectFactory getFactory(string identity) {
                    return this.decorated.getFactory(identity);
                }

                /**
                Get all factories available in decorated.

                Get all factories available in decorated.

                Returns:
                	InputRange!(Tuple!(ObjectFactory, string)) a tuple of factory => identity.
                **/
                InputRange!(Tuple!(ObjectFactory, string)) getFactories() {
                    return this.decorated.getFactories();
                }
            }
        }

    }
}

private {
    void crawlClassInfo(TypeInfo_Class class_, void delegate (TypeInfo_Class) @safe dg) @safe {
        dg(class_);

        foreach (iface; class_.interfaces) {
            crawlClassInfo(iface.classinfo, dg);
        }

        if (class_.base !is null) {
            crawlClassInfo(class_.base, dg);
        }
    }


}