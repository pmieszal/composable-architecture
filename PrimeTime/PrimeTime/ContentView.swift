import Combine
import SwiftUI
import ComposableArchitecture
import FavoritePrimes
import Counter
import PrimeModal

struct AppState {
    var count = 0
    var favoritePrimes = [Int]()
    var activityFeed: [Activity] = []
    var loggedInUser: User?
    
    struct Activity {
        let timestamp: Date
        let type: ActivityType

        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }
    }

    struct User {
        let id: Int
        let name: String
        let bio: String
    }
}

enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)

    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }

    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }

    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }
}

extension AppState {
    var primeModal: PrimeModalState {
        get {
            PrimeModalState(count: count, favoritePrimes: favoritePrimes)
            
        }
        set {
            count = newValue.count
            favoritePrimes = newValue.favoritePrimes
        }
    }
}

let appReducer: (inout AppState, AppAction) -> Void = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.primeModal, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)

func activityFeed(
    _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {
    return { state, action in
        switch action {
        case .counter:
            break
        case .primeModal(.removeFavoritePrimeTapped):
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
        case .primeModal(.saveFavoritePrimeTapped):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
        case let .favoritePrimes(.deleteFavoritePrinmes(indexSet)):
            for index in indexSet {
                let prime = state.favoritePrimes[index]
                state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
            }
        }
        
        reducer(&state, action)
    }
}

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CounterView(store: store)) {
                    Text("Counter demo")
                }
                NavigationLink(destination: FavoritePrimesView(store: store)) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State management")
        }
    }
}

struct CounterView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    @State var isPrimeModalShown = false
    @State var alertNthPrime: Int?
    @State var isNthPrimeButtonDisabled = false
    
    var body: some View {
        VStack {
            HStack {
                Button("-") { store.send(.counter(.decrTapped)) }
                Text("\(store.value.count)")
                Button("+") { store.send(.counter(.incrTapped)) }
            }
            
            Button("Is this prime?") {
                isPrimeModalShown = true
            }
            
            Button("What is the \(ordinal(store.value.count)) prime?", action: nthPrimeButtonAction)
                .disabled(isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: $isPrimeModalShown) {
            IsPrimeModalView(store: store)
        }
        .alert(item: $alertNthPrime) { (prime) -> Alert in
            Alert(
                title: Text("The \(ordinal(store.value.count)) prime is \(prime)"),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func nthPrimeButtonAction() {
        isNthPrimeButtonDisabled = true
        nthPrime(store.value.count) { prime in
            alertNthPrime = prime
            isNthPrimeButtonDisabled = false
        }
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    
    var body: some View {
        VStack {
            if isPrime(store.value.count) {
                Text("\(store.value.count) is prime 🎉")
                
                if store.value.favoritePrimes.contains(store.value.count) {
                    Button("Remove from favorite primes") {
                        store.send(.primeModal(.removeFavoritePrimeTapped))
                    }
                } else {
                    Button("Add to favorite primes") {
                        store.send(.primeModal(.saveFavoritePrimeTapped))
                    }
                }
            } else {
                Text("\(store.value.count) is not prime :(")
            }
        }
    }
}

struct FavoritePrimesView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    
    var body: some View {
        List {
            ForEach(store.value.favoritePrimes) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                store.send(.favoritePrimes(.deleteFavoritePrinmes(indexSet)))
            }
        }
        .navigationTitle("Favorite Primes")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialValue: AppState(),
                reducer: with(
                    appReducer,
                    compose(
                        logging, activityFeed
                    )
                )
            )
        )
    }
}
