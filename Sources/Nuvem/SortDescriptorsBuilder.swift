import Foundation

final class SortDescriptorsBuilder<Model: CKModel> {
    
    var sorts: [CKSort<Model>] = []
    
    func add(_ sort: CKSort<Model>) {
        sorts.append(sort)
    }
    
    func build() -> [NSSortDescriptor] {
        return sorts.map(\.descriptor)
    }
    
}
