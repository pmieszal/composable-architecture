import ComposableArchitecture
import SwiftUI
import Combine

public enum FavoritePrimesAction: Equatable {
    case deleteFavoritePrimes(IndexSet)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) -> [Effect<FavoritePrimesAction>] {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
        
        return []
    case let .loadedFavoritePrimes(primes):
        state = primes
        
        return []
    case .saveButtonTapped:
        return [
            Current
                .fileClient
                .save("favorites-primes.json", try! JSONEncoder().encode(state))
                .fireAndForget()
        ]
        
    case .loadButtonTapped:
        return [
            Current
                .fileClient
                .load("favorites-primes.json")
                .compactMap { $0 }
                .decode(type: [Int].self, decoder: JSONDecoder())
                .catch { error in Empty(completeImmediately: true) }
                .map(FavoritePrimesAction.loadedFavoritePrimes)
                .eraseToEffect()
        ]
    }
}

struct FileClient {
    var load: (String) -> Effect<Data?>
    var save: (String, Data) -> Effect<Never>
}

extension FileClient {
    static let live = FileClient(
        load: { filename -> Effect<Data?> in
            Effect.sync {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let documentsUrl = URL(fileURLWithPath: documentsPath)
                let favoritePrimesUrl = documentsUrl.appendingPathComponent(filename)
                return try? Data(contentsOf: favoritePrimesUrl)
            }
        },
        save: { filename, data -> Effect<Never> in
            .fireAndForget {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let documentsUrl = URL(fileURLWithPath: documentsPath)
                let favoritePrimesUrl = documentsUrl.appendingPathComponent(filename)
                try! data.write(to: favoritePrimesUrl)
            }
        })
}

struct FavoritePrimesEnvironment {
    var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
    static let live = FavoritePrimesEnvironment(fileClient: .live)
}

#if DEBUG
extension FavoritePrimesEnvironment {
    static let mock = FavoritePrimesEnvironment(
        fileClient: FileClient(
            load: { _ in Effect<Data?>.sync {
                try! JSONEncoder().encode([2, 31])
            } },
            save: { _, _ in .fireAndForget {} }
        )
    )
}
#endif

var Current = FavoritePrimesEnvironment.live

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
                store.send(.deleteFavoritePrimes(indexSet))
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
