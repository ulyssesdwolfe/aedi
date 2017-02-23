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
module aermicioi.aedi.container.singleton_container;

import aermicioi.aedi.container.container;
import aermicioi.aedi.storage.object_storage;
import aermicioi.aedi.storage.locator_aware;
import aermicioi.aedi.storage.locator;
import aermicioi.aedi.factory.factory;
import aermicioi.aedi.exception;
import aermicioi.aedi.container.factory;

import std.range.interfaces;
import std.typecons;

/**
 Singleton container.
 
 It creates objects from ObjectFactory implementations and sets them as long as it lives in application.
**/
class SingletonContainer : ConfigurableContainer {
    
    private {
        
        ObjectStorage!() singletons;
        ObjectStorage!(ObjectFactory, string) factories;
    }
    
    public {
        
        this() {
            this.singletons = new ObjectStorage!();
            this.factories = new ObjectStorage!(ObjectFactory, string);
        }
        
        SingletonContainer set(ObjectFactory object, string key) {
            this.factories.set(new ExceptionChainingObjectFactory(new InProcessObjectFactoryDecorator(object), key), key);
            
            return this;
        }
        
        SingletonContainer remove(string key) {
            this.factories.remove(key);
            this.singletons.remove(key);
            
            return this;
        }
        
        Object get(string key) {
            
            if (!this.singletons.has(key)) {
                if (!this.factories.has(key)) {
                    throw new NotFoundException("Object with id " ~ key ~ " not found.");
                }
                
                this.singletons.set( 
                    this.factories.get(key).factory(),
                    this.resolve(key),
                );
            }
            
            return this.singletons.get(key);
        }
        
        bool has(in string key) inout {
            return this.factories.has(key);
        }
        
        SingletonContainer instantiate() {
            import std.algorithm : filter;
            foreach (pair; this.factories.contents.byKeyValue.filter!((pair) => pair.key !in this.singletons.contents)) {
                this.singletons.set(
                    pair.value.factory,
                    pair.key,
                );
            }
            
            return this;
        }
        
        SingletonContainer link(string key, string alias_) {
            this.singletons.link(key, alias_);
            this.factories.link(key, alias_);
            
            return this;
        }
        
        SingletonContainer unlink(string alias_) {
            this.singletons.unlink(alias_);
            this.factories.unlink(alias_);
            
            return this;
        }
        
        const(string) resolve(in string key) const {
            return this.factories.resolve(key);
        }
        
        
        ObjectFactory getFactory(string identity) {
            return this.factories.get(identity);
        }
        
        InputRange!(Tuple!(ObjectFactory, string)) getFactories() {
            import std.algorithm;
            
            return this.factories.contents.byKeyValue.map!(
                a => tuple(a.value, a.key)
            ).inputRangeObject;
        }
    }
}