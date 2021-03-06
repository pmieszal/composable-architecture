import ComposableArchitecture
import SwiftUI
import Combine

public enum FavoritePrimesAction {
    case deleteFavoritePrinmes(IndexSet)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) -> [Effect<FavoritePrimesAction>] {
    switch action {
    case let .deleteFavoritePrinmes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
        
        return []
    case let .loadedFavoritePrimes(primes):
        state = primes
        
        return []
    case .saveButtonTapped:
        return [saveEffect(favoritePrimes: state)]
        
    case .loadButtonTapped:
        return [
            loadEffect
                .compactMap { $0 }
                .eraseToEffect()
        ]
    }
}

private func saveEffect(favoritePrimes state: [Int]) -> Effect<FavoritePrimesAction> {
    Effect.fireAndForget {
        let data = try! JSONEncoder().encode(state)
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let favoritePrimesUrl = documentsUrl.appendingPathComponent("favorite-primes.json")
        try! data.write(to: favoritePrimesUrl)
    }
}

private let loadEffect = Effect<FavoritePrimesAction?>.sync {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let documentsUrl = URL(fileURLWithPath: documentsPath)
    let favoritePrimesUrl = documentsUrl.appendingPathComponent("favorite-primes.json")
    guard let data = try? Data(contentsOf: favoritePrimesUrl),
          let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data) else {
        return nil
    }
            
    return .loadedFavoritePrimes(favoritePrimes)
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
        .navigationBarItems(
            trailing: HStack {
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
                Button("Load") {
                    store.send(.loadButtonTapped)
                }
            })
    }
}

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritePrimesView(
                store: Store(
                    initialValue: [2, 3, 5],
                    reducer: favoritePrimesReducer))
        }
    }
}
