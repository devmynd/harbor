/**
 Classes conforming to `ComponentType` are a container for a set of dependencies,
 declared in `Modules`, and are the principal mechanism for scoping dependencies
 to particular part of the application.
 
 A `ComponentType` owns modules, which can be registered through the chainable
 method `module`.
*/
public protocol ComponentType: class {
  /**
   The `registry` is used as the component's backing store. Conformance to
   `ComponentType` only requires that the implementer declare storage for and
   construct a registry.
  */
  var registry: Registry { get }
}

// MARK: Parents
public extension ComponentType {
  /**
   Retrieves a registered parent component. If the parent component is not yet
   registerd, this method raises an exception.

   - Returns: A pre-registered parent of type `P`
  */
  func parent<P: ComponentType>() -> P {
    do {
      return try registry.get()
    } catch Error.ComponentNotFound(let type) {
      terminate("failed to find parent: \(type)")
    } catch {
      terminate()
    }
  }

  /**
   Registers a parent component of type `P`. This component can be retrieved through
   the `parent` accessor method.

   - Parameter initializer: A closure called immediately that returns or initializes
     the parent, which is then discarded.

   - Returns: This component for chaining
  */
  func parent<P: ComponentType>(initializer: () -> P) -> Self {
    registry.set(initializer())
    return self
  }
}

// MARK: Modules
public extension ComponentType {
  /**
   Retrieves the module registered for the module type `M`. If no module has been
   registerd for `M`, this method raises an exception.
   
   `M` must decare this component as it's `Owner`.

   - Parameter key: A key used to match the correct module; defaults to `M.self`
   - Returns: A pre-registered module of type `M`
  */
  func module<M: ModuleType where M.Owner == Self>(key: KeyConvertible = Key(M.self)) -> M {
    do {
      return try registry.get(key)
    } catch Error.ModuleNotFound(let type) {
      terminate("failed to find module \(type)")
    } catch {
      terminate()
    }
  }

  /**
   Registers a module of type `M`. This module can be retrieved through the `module`
   accessor method.
   
   - Parameter type: The supertype (or the type itself) of the module to register
   - Parameter initializer: A closure called immediately that returns or initializes
   the module, which is then discarded. Passed this component as its only parameter.

   - Returns: This component for chaining
  */
  func module<M: ModuleType where M.Owner == Self>(type: M.Type, initializer: Self -> M) -> Self {
    return self.module(Key(type), initializer: initializer)
  }

  /**
   Registers a module of type `M`. This module can be retrieved through the `module`
   accessor method.

   - Parameter key: A key used to match the correct module; defaults to the `M.self`
   - Parameter initializer: A closure called immediately that returns or initializes
   the module, which is then discarded. Passed this component as its only parameter.

   - Returns: This component for chaining
  */
  func module<M: ModuleType where M.Owner == Self>(key: KeyConvertible = Key(M.self), initializer: Self -> M) -> Self {
    registry.set(key, value: initializer(self))
    return self
  }
}

// MARK: Generators
public extension ComponentType {
  /**
   Note: should only be used to implement of custom generators.

   Resolves an instance of `T`. The generator used to resolve `T` is lazily evaluated,
   and if none exists the parameterized `generator` is stored for future resolution.

   - Parameter key: A key used to match the correct dependency; defaults to the `T.self`
   - Parameter generator: The generator of `T` to use if none is registered

   - Returns: An instance of `T`
  */
  func resolve<T>(key: KeyConvertible = Key(T.self), generator: Self -> T) -> T {
    return lazyMatchFor(key, generator: generator)(self)
  }
}

extension ComponentType {
  func lazyMatchFor<T>(key: KeyConvertible, generator: Self -> T) -> Self -> T {
    var result: Self -> T

    if let match: Self -> T = registry.get(key) {
      result = match
    } else {
      result = generator
      registry.set(key, value: generator)
    }

    return result
  }
}

// MARK: Overrides
public extension ComponentType {
  /**
   Overrides the registered generator of type `T` to return a single instance.

   - Parameter instance: The instance to return whenever a `T` is injected
   - Returns: This component for chaining
  */
  func override<T>(instance: T) -> Self {
    return override(Key(T.self), instance)
  }

  /**
   Overrides the registered generator of type `T` to return a single instance.

   - Parameter key: A key used to match the correct dependency
   - Parameter instance: The instance to return whenever a `T` is injected

   - Returns: This component for chaining
  */
  func override<T>(key: KeyConvertible, _ instance: T) -> Self {
    return override(key) { _ in instance }
  }

  /**
   Overrides the registered generator of type `T`. Instances are generated by
   calling the `generator`.

   - Parameter key: A key used to match the correct dependency; defaults to the `T.self`
   - Parameter generator: The function to call whenever a `T` is injected

   - Returns: This component for chaining
  */
  func override<T>(key: KeyConvertible = Key(T.self), generator: Self -> T) -> Self {
    registry.set(key, value: generator)
    return self
  }
}

// MARK: Errors
extension ComponentType {
  @noreturn func terminate(message: String = "unknown error") {
    fatalError("[component: \(self)] \(message)")
  }
}