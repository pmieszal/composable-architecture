import Combine
import SwiftUI
import ComposableArchitecture
import FavoritePrimes
import Counter

struct AppState {
    var count = 0
    var favoritePrimes = [Int]()
    var activityFeed: [Activity] = []
    var loggedInUser: User?
    var alertNthPrime: PrimeAlert?
    var isNthPrimeButtonDisabled = false
    var isPrimeModalShown = false
    
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

extension AppState {
    var counterView: CounterViewState {
        get {
            CounterViewState(
                alertNthPrime: alertNthPrime,
                count: count,
                favoritePrimes: favoritePrimes,
                isNthPrimeButtonDisabled: isNthPrimeButtonDisabled,
                isPrimeModalShown: isPrimeModalShown)
        }
        set {
            alertNthPrime = newValue.alertNthPrime
            count = newValue.count
            favoritePrimes = newValue.favoritePrimes
            isNthPrimeButtonDisabled = newValue.isNthPrimeButtonDisabled
            isPrimeModalShown = newValue.isPrimeModalShown
        }
    }
}

enum AppAction {
    case counterView(CounterViewAction)
    case favoritePrimes(FavoritePrimesAction)
    

    var counterView: CounterViewAction? {
        get {
            guard case let .counterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
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

typealias AppEnvironment = (
    fileClient: FileClient,
    nthPrime: (Int) -> Effect<Int?>
)

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
    pullback(
        counterViewReducer,
        value: \.counterView,
        action: \.counterView,
        environment: { $0.nthPrime }
    ),
    pullback(
        favoritePrimesReducer,
        value: \.favoritePrimes,
        action: \.favoritePrimes,
        environment: { $0.fileClient }
    )
)

func activityFeed(
    _ reducer: @escaping Reducer<AppState, AppAction, AppEnvironment>
) -> Reducer<AppState, AppAction, AppEnvironment> {
    return { state, action, environment in
        switch action {
        case .counterView(.counter),
             .favoritePrimes(.loadedFavoritePrimes),
             .favoritePrimes(.saveButtonTapped),
             .favoritePrimes(.loadButtonTapped):
            break
        case .counterView(.primeModal(.removeFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
        case .counterView(.primeModal(.saveFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
        case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
            for index in indexSet {
                let prime = state.favoritePrimes[index]
                state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
            }
        }
        
        return reducer(&state, action, environment)
    }
}

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: CounterView(
                        store: store.view(
                            value: { $0.counterView },
                            action: { .counterView($0) }))) {
                    Text("Counter demo")
                }
                NavigationLink(
                    destination: FavoritePrimesView(
                        store: store.view(
                            value: { $0.favoritePrimes },
                            action: { .favoritePrimes($0) }))) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State management")
        }
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
                ),
                environment: AppEnvironment(
                    fileClient: .live,
                    nthPrime: nthPrime
                )
            )
        )
    }
}
