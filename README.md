# Nuvem

## CloudKit Models

To define a model that represents a CloudKit `CKRecord`, annotate it with `@CKModel` macro and use `@CKField` property wrapper to define the properties that are mapped to record fields.

```swift
@CKModel
struct Post {  
    @CKField("text")
    var text: String?
    
    @CKField("likes", default: 0)
    var likes: Int
}
```

> [!CAUTION]
> If a `@CKField` property is **non-optional**, has **no default value**, and the corresponding field is **missing from the CloudKit record**, accessing the property will trigger a **runtime crash** (`fatalError`). Provide a default value (`default:`) or make the property optional (`?`) to safely handle missing field data.


## Assets

Use `@CKAssetField` to map a field that contains a `CKAssset`  to `Data` or `UIImage`.

```swift
@CKModel
struct Post {  
    
    ...
    
    @CKAssetField("picture")
    var picture: UIImage?
}
```

Use `@CKAssetListField` to map `[CKAssset]` to `[Data]` or `[UIImage]`.

```swift
@CKModel
struct Post {  
    
    ...
    
    @CKAssetField("pictures", default: [])
    var pictures: [UIImage]
}
```

## References

Use `@CKReferenceField` to map a field that contains a `CKReference` to a `CKModel`.

```swift
@CKModel
struct Post {
    
    ...

    @CKReferenceField("author")
    var author: User?

}

@CKModel
struct Author {
    @CKField("name")
    var name: String
    @CKAssetField("photo")
    var photo: Data?
}
```

Use `@CKReferenceListField` to map `[CKReference]` to `[CKModel]`.

```swift
@CKModel
struct Todo {
    
    @CKField("text", default: "")
    var text: String
    
    @CKField("isCompleted", default: false)
    var isCompleted: Bool
    
    @CKReferenceListField("tags", default: [])
    var tags: [Tag]
    
}

@CKModel
struct Tag {
    @CKField("name")
    var name: String
}
```

## Saving

To save a model record to CloudKit, use `save(on:)` method.

```swift
let post = Post(text: "Hello, world!")

let database = CKContainer.default().publicCloudDatabase

try await post.save(on: database)
```

## Deleting

To delete a model record from CloudKit, use `delete(on:)` method.

```swift
try await post.delete(on: database)
```

## Querying

To query all records of a `CKModel` from CloudKit, build a query using `query(on:)` static method and run it using `all()`.

```swift
try await Post.query(on: database).all()
```

> [!IMPORTANT]
> You must add a **QUERYABLE** index to the `recordName` metadata field of the corresponding record type.

### Batched Records

You can batch records with `batched()` and fetch them using `next(_:)`.

```swift
let query = Post.query(on: database).batched()

if let batch = try await query.next(10) {
    
}
```

### Filtering

You can filter results using the `filter(_:)` method with `$` keypath-based predicates.

```swift
try await Todo.query(on: database)
    .filter(\.$isCompleted == true)
    .all()
```

> [!IMPORTANT]
> You must add a **QUERYABLE** index to filter target fields.

### Sorting

You can sort results by fields in ascending or descending order.

```swift
try await Todo.query(on: database)
    .sort(\.$creationDate, order: .descending)
    .all()
```

> [!IMPORTANT]
> You must add a **SORTABLE** index to sort target fields.


### Specifying Desired/Undesired Fields

For models with many fields you may want to fetch only a subset of fields to reduce payload size.

Use `field(_:)` to specify exactly which fields to include, or `field(exclude:)` to exclude specific ones.

```swift
try await Post.query(on: database)
    .field(\.$text, \.$likes)
    .all()
```

```swift
try await Post.query(on: database)
    .field(exclude: \.$picture)
    .all()
```

### Eager Loading References

When your model contains `@CKReferenceField` properties, you can eagerly load the referenced records in the same query using `.with(_:)`. This avoids multiple round-trips to the database.

```swift
try await Post.query(on: database)
    .with(\.$user)
    .all()
```

### Manually Loading Fields

If you excluded certain fields from a query — such as heavy asset fields — you can load them individually later. Each `@CKField`, `@CKAssetField`, and `@CKReferenceField` property exposes a `load(on:)` method to fetch its value on demand.

```swift
var post = try await Post.query(on: database)
    .field(exclude: \.$picture)
    .first()!

try await post.$author.load(on: database)

try await post.$picture.load(on: database)
```
