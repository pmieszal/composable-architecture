import ComposableArchitecture
import SwiftUI

public typealias PrimeModalState = (count: Int, favoritePrimes: [Int])

public enum PrimeModalAction: Equatable {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> [Effect<PrimeModalAction>] {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
        
        return []
        
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll { $0 == state.count }
        
        return []
    }
}

public struct IsPrimeModalView: View {
    @ObservedObject var store: Store<PrimeModalState, PrimeModalAction>
    
    public init(store: Store<PrimeModalState, PrimeModalAction>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            if isPrime(store.value.count) {
                Text("\(store.value.count) is prime 🎉")
                
                if store.value.favoritePrimes.contains(store.value.count) {
                    Button("Remove from favorite primes") {
                        store.send(.removeFavoritePrimeTapped)
                    }
                } else {
                    Button("Add to favorite primes") {
                        store.send(.saveFavoritePrimeTapped)
                    }
                }
            } else {
                Text("\(store.value.count) is not prime :(")
            }
        }
    }
}

func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2 ... Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IsPrimeModalView(
                store: Store(
                    initialValue: (count: 2, favoritePrimes: [0]),
                    reducer: primeModalReducer))
        }
    }
}

