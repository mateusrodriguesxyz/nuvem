# Nuvem

## Declaring Models

```swift
struct Todo: CKModel {
    
    var record: CKRecord!
    
    @CKTimestamp(.creation)
    var creationDate: Date?
    
    @CKTimestamp(.modification)
    var modificationDate: Date?
    
    @CKField("text")
    var text: String
    
    @CKField("tags", default: [])
    var tags: [String]
    
    @CKField("isCompleted")
    var isCompleted: Bool
    
    init() { }
    
}
```

## Saving

```swift

let database = CKContainer.default().publicCloudDatabase

try await todo.save(on: database)

```

## Deleting

```swift
try await todo.delete(on: database)
```

## Querying

```swift
try await Todo.query(on: database).all()

try await Todo.query(on: database).first()

try await Todo.query(on: database).limit(10)
```

### Filtering

```swift
try await Todo.query(on: database)
    .filter(\.$isCompleted == true)
    .all()
```

### Sorting

```swift
try await Todo.query(on: database)
    .sort(\.$creationDate, order: .descending)
    .all()
```

### Specifying Desired/Undesired Fields

```swift
@CKModel
struct Post {
    
    @CKField("text")
    var text: String?
    
    @CKField("likes", default: 0)
    var likes: Int
    
    @CKAssetField("picture")
    var picture: UIImage?
    
    @CKReferenceField("author")
    var author: User?

}
```

```swift
try await Todo.query(on: database)
    .field(\.$text, \.$likes, \.$author)
    .all()
```

```swift
try await Todo.query(on: database)
    .field(exclude: \.$picture)
    .all()
```

### Eager Loading Reference

```swift
try await Todo.query(on: database)
    .with(\.$user)
    .all()
```

### Manually Loading Fields

```swift
var post = try await Post.query(on: database)
    .field(exclude: \.$picture)
    .first()!

try await post.$author.load(on: database)

try await post.$picture.load(on: database)
```

### Querying Batched Records

```swift
let query = Post.query(on: database)
    .sort(\.$creationDate, order: .descending)
    .batched()

if let batch = try await query.next(10) {
    
}
```
