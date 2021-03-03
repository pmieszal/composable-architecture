import Foundation

public enum FavoritePrimesAction {
    case deleteFavoritePrinmes(IndexSet)
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) {
    switch action {
    case let .deleteFavoritePrinmes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}
