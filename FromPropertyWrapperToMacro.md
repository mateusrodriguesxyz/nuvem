#  From Property Wrapper to Macro

## Property Wrapper Version

### Type Declaration

```swift
@propertyWrapper
class Wrapper<T> {
    var value: T
    var wrappedValue: T {
        get {
            print(self, "get")
            return value
        }
        set {
            print(self, "set")
            value = newValue
        }
    }
    var projectedValue: Wrapper<T> { self }
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
```

### Usage

```swift
struct Model {
    @Wrapper var count: Int
}
```

## Macro Version

The type implementation should not change.

The macro should just init the `_` prefixed wrapper variable, set/get `wrappedValue` and get `projectedValue`.

### Type Declaration

```swift
class Wrapper<T> {
    var value: T
    var wrappedValue: T {
        get {
            print(self, "get")
            return value
        }
        set {
            print(self, "set")
            value = newValue
        }
    }
    var projectedValue: Wrapper<T> { self }
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
```

### Usage

```swift
struct Model {
    @Wrapper var count: Int
}
```

### Expanded Macro

```swift
struct Model {
    let _count = Wrapper<Int>(wrappedValue: 0)
    var count: Int {
        @storageRestrictions(initializes: _count)
        init {
            self._count = Wrapper<Int>(wrappedValue: newValue)
        }
        get {
            _count.wrappedValue
        }
        set {
            _count.wrappedValue = newValue
        }
    }
    var $count: Wrapper<Int> {
        _count.projectedValue
    }
}
```

### Implementation Reference

https://raw.githubusercontent.com/apple/swift-temporal-sdk/24583a970d87c6398e601da7bb7ef8fa66542450/Sources/TemporalMacros/WorkflowStateMacro.swift