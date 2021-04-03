import ComposableArchitecture
import PrimeModal
import SwiftUI
import Combine

public enum CounterAction: Equatable {
    case decrTapped
    case incrTapped
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case alertDismissTapped
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeButtonDisabled: Bool)

public func counterReducer(state: inout CounterState, action: CounterAction) -> [Effect<CounterAction>] {
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
            Current.nthPrime(state.count)
                .map(CounterAction.nthPrimeResponse)
                .receive(on: DispatchQueue.main)
                .eraseToEffect(),
        ]
        
    case let .nthPrimeResponse(prime):
        state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        state.isNthPrimeButtonDisabled = false
        
        return []
        
    case .alertDismissTapped:
        state.alertNthPrime = nil
        
        return []
    }
}

struct CounterEnvironment {
    var nthPrime: (Int) -> Effect<Int?>
}

extension CounterEnvironment {
    static let live = CounterEnvironment(nthPrime: Counter.nthPrime)
}

extension CounterEnvironment {
    static let mock = CounterEnvironment(nthPrime: { _ in .sync { 17 } })
}

var Current = CounterEnvironment.live

public let counterViewReducer = combine(
    pullback(counterReducer, value: \CounterViewState.counter, action: \CounterViewAction.counter),
    pullback(primeModalReducer, value: \CounterViewState.primeModal, action: \CounterViewAction.primeModal))

public struct CounterViewState: Equatable {
    public var alertNthPrime: PrimeAlert?,
        count: Int,
        favoritePrimes: [Int],
        isNthPrimeButtonDisabled: Bool
    
    public init(
        alertNthPrime: PrimeAlert? = nil,
        count: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeButtonDisabled: Bool = false) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }
    
    var counter: CounterState {
        get { (alertNthPrime, count, isNthPrimeButtonDisabled) }
        set {
            (alertNthPrime, count, isNthPrimeButtonDisabled) = newValue
        }
    }
    
    var primeModal: PrimeModalState {
        get { (count, favoritePrimes) }
        set {
            (count, favoritePrimes) = newValue
        }
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

public struct PrimeAlert: Identifiable, Equatable {
    let prime: Int
    public var id: Int { prime }
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    @State var isPrimeModalShown = false
    
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
                .disabled(store.value.isNthPrimeButtonDisabled)
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
        .alert(item: .constant(store.value.alertNthPrime)) { (alert) -> Alert in
            Alert(
                title: Text("The \(ordinal(store.value.count)) prime is \(alert.prime)"),
                dismissButton: .default(Text("OK")) {
                    store.send(.counter(.alertDismissTapped))
                })
        }
    }
    
    func nthPrimeButtonAction() {
        store.send(.counter(.nthPrimeButtonTapped))
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
                    reducer: counterViewReducer))
        }
    }
}
