import Combine
import SwiftUI
import PlaygroundSupport

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

            var addedFavoritePrime: Int? {
                get {
                    guard case let .addedFavoritePrime(value) = self else { return nil }
                    return value
                }
                set {
                    guard case .addedFavoritePrime = self, let newValue = newValue else { return }
                    self = .addedFavoritePrime(newValue)
                }
            }

            var removedFavoritePrime: Int? {
                get {
                    guard case let .removedFavoritePrime(value) = self else { return nil }
                    return value
                }
                set {
                    guard case .removedFavoritePrime = self, let newValue = newValue else { return }
                    self = .removedFavoritePrime(newValue)
                }
            }
        }
    }

    struct User {
        let id: Int
        let name: String
        let bio: String
    }
}

enum CounterAction {
    case decrTapped
    case incrTapped
}

enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

enum FavoritePrimesAction {
    case deleteFavoritePrinmes(IndexSet)

    var deleteFavoritePrinmes: IndexSet? {
        get {
            guard case let .deleteFavoritePrinmes(value) = self else { return nil }
            return value
        }
        set {
            guard case .deleteFavoritePrinmes = self, let newValue = newValue else { return }
            self = .deleteFavoritePrinmes(newValue)
        }
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

func counterReducer(state: inout Int, action: CounterAction) {
    switch action {
    case .decrTapped:
        state -= 1
    case .incrTapped:
        state += 1
    }
}

func primeModalReducer(state: inout AppState, action: PrimeModalAction) {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
        
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll { $0 == state.count }
    }
}

func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) {
    switch action {
    case let .deleteFavoritePrinmes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}

final class Store<Value, Action>: ObservableObject {
    @Published private(set) var value: Value
    
    let reducer: (inout Value, Action) -> Void
    
    init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        value = initialValue
        self.reducer = reducer
    }
    
    func send(_ action: Action) {
        reducer(&value, action)
    }
}

func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
)
    -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

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

func logging<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { value, action in
        reducer(&value, action)
        print("Action: \(action)")
        print("State:")
        dump(value)
        print("---")
    }
}

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.self, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)

let appReducer = pullback(_appReducer, value: \.self, action: \.self)

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

PlaygroundPage.current.liveView = UIHostingController(
    rootView: ContentView(
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
)
