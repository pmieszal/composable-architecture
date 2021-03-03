import ComposableArchitecture
import PrimeModal
import SwiftUI

public enum CounterAction {
    case decrTapped
    case incrTapped
}

public func counterReducer(state: inout Int, action: CounterAction) {
    switch action {
    case .decrTapped:
        state -= 1
    case .incrTapped:
        state += 1
    }
}

public let counterViewReducer = combine(
    pullback(counterReducer, value: \CounterViewState.count, action: \CounterViewAction.counter),
    pullback(primeModalReducer, value: \.self, action: \CounterViewAction.primeModal)
)

public typealias CounterViewState = (count: Int, favoritePrimes: [Int])

public enum CounterViewAction {
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

struct PrimeAlert: Identifiable {
    let prime: Int
    var id: Int { prime }
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    @State var isPrimeModalShown = false
    @State var alertNthPrime: PrimeAlert?
    @State var isNthPrimeButtonDisabled = false
    
    public init(store: Store<CounterViewState, CounterViewAction>) {
        self.store = store
    }
    
    public var body: some View {
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
            IsPrimeModalView(
                store: store.view(
                    value: {
                        PrimeModalState(count: $0.count, favoritePrimes: $0.favoritePrimes)
                    },
                    action: { .primeModal($0) }))
        }
        .alert(item: $alertNthPrime) { (alert) -> Alert in
            Alert(
                title: Text("The \(ordinal(store.value.count)) prime is \(alert.prime)"),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func nthPrimeButtonAction() {
        isNthPrimeButtonDisabled = true
        nthPrime(store.value.count) { prime in
            alertNthPrime = prime.map(PrimeAlert.init(prime:))
            isNthPrimeButtonDisabled = false
        }
    }
}

func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}
