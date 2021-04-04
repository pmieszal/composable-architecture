import Combine
import ComposableArchitecture
import PrimeModal
import SwiftUI

public enum CounterAction: Equatable {
    case decrTapped
    case incrTapped
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case alertDismissButtonTapped
    case isPrimeButtonTapped
    case primeModalDismissed
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeButtonDisabled: Bool,
    isPrimeModalShown: Bool)

public func counterReducer(
    state: inout CounterState,
    action: CounterAction,
    environment: CounterEnvironment
) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state.count -= 1
        return []

    case .incrTapped:
        state.count += 1
        return []

    case .nthPrimeButtonTapped:
        state.isNthPrimeButtonDisabled = true
        return [
            environment(state.count)
                .map(CounterAction.nthPrimeResponse)
                .receive(on: DispatchQueue.main)
                .eraseToEffect(),
        ]

    case let .nthPrimeResponse(prime):
        state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        state.isNthPrimeButtonDisabled = false
        
        return []

    case .alertDismissButtonTapped:
        state.alertNthPrime = nil
        return []

    case .isPrimeButtonTapped:
        state.isPrimeModalShown = true
        return []

    case .primeModalDismissed:
        state.isPrimeModalShown = false
        return []
    }
}

public typealias CounterEnvironment = (Int) -> Effect<Int?>

public let counterViewReducer: Reducer<CounterViewState, CounterViewAction, CounterEnvironment> = combine(
    pullback(
        counterReducer,
        value: \CounterViewState.counter,
        action: \CounterViewAction.counter,
        environment: { $0 }
    ),
    pullback(
        primeModalReducer,
        value: \.primeModal,
        action: \.primeModal,
        environment: { _ in return }
    )
)

public struct PrimeAlert: Equatable, Identifiable {
    let prime: Int
    public var id: Int { prime }
}

public struct CounterViewState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var count: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeButtonDisabled: Bool
    public var isPrimeModalShown: Bool

    public init(alertNthPrime: PrimeAlert? = nil,
                count: Int = 0,
                favoritePrimes: [Int] = [],
                isNthPrimeButtonDisabled: Bool = false,
                isPrimeModalShown: Bool = false) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
        self.isPrimeModalShown = isPrimeModalShown
    }

    var counter: CounterState {
        get { (alertNthPrime, count, isNthPrimeButtonDisabled, isPrimeModalShown) }
        set { (alertNthPrime, count, isNthPrimeButtonDisabled, isPrimeModalShown) = newValue }
    }

    var primeModal: PrimeModalState {
        get { (count, favoritePrimes) }
        set { (count, favoritePrimes) = newValue }
    }
}

public enum CounterViewAction: Equatable {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)

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
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>

    public init(store: Store<CounterViewState, CounterViewAction>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            HStack {
                Button("-") { self.store.send(.counter(.decrTapped)) }
                Text("\(self.store.value.count)")
                Button("+") { self.store.send(.counter(.incrTapped)) }
            }
            Button("Is this prime?") { self.store.send(.counter(.isPrimeButtonTapped)) }
            Button("What is the \(ordinal(self.store.value.count)) prime?") {
                self.store.send(.counter(.nthPrimeButtonTapped))
            }
            .disabled(self.store.value.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationBarTitle("Counter demo")
        .sheet(
            isPresented: .constant(self.store.value.isPrimeModalShown),
            onDismiss: { self.store.send(.counter(.primeModalDismissed)) }) {
                IsPrimeModalView(
                    store: self.store.view(
                        value: { ($0.count, $0.favoritePrimes) },
                        action: { .primeModal($0) }))
        }
        .alert(
            item: .constant(self.store.value.alertNthPrime)) { alert in
                Alert(
                    title: Text("The \(ordinal(self.store.value.count)) prime is \(alert.prime)"),
                    dismissButton: .default(Text("Ok")) {
                        self.store.send(.counter(.alertDismissButtonTapped))
                    })
        }
    }
}

func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CounterView(
                store: Store(
                    initialValue: CounterViewState(
                        alertNthPrime: nil,
                        count: 2,
                        favoritePrimes: [],
                        isNthPrimeButtonDisabled: false),
                    reducer: counterViewReducer,
                    environment: nthPrime))
        }
    }
}
