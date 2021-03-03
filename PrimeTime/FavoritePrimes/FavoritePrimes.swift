import ComposableArchitecture
import SwiftUI

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

public struct FavoritePrimesView: View {
    @ObservedObject var store: Store<[Int], FavoritePrimesAction>
    
    public init(store: Store<[Int], FavoritePrimesAction>) {
        self.store = store
    }
    
     public var body: some View {
        List {
            ForEach(store.value, id: \.self) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                store.send(.deleteFavoritePrinmes(indexSet))
            }
        }
        .navigationTitle("Favorite Primes")
    }
}
