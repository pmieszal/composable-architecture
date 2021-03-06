import Combine
import ComposableArchitecture
import Counter
import FavoritePrimes
import PlaygroundSupport
import PrimeModal
import SwiftUI

PlaygroundPage.current.liveView = UIHostingController(
    rootView: NavigationView {
        CounterView(
            store: Store<CounterViewState, CounterViewAction>(
                initialValue: CounterViewState(
                    alertNthPrime: nil,
                    count: 2,
                    favoritePrimes: [],
                    isNthPrimeButtonDisabled: false),
                reducer: logging(counterViewReducer)))
    })

// PlaygroundPage.current.liveView = UIHostingController(
//    rootView: IsPrimeModalView(
//        store: Store<PrimeModalState, PrimeModalAction>(
//            initialValue: PrimeModalState(count: 2, favoritePrimes: [2, 3]),
//            reducer: primeModalReducer)))

// PlaygroundPage.current.liveView = UIHostingController(
//    rootView: FavoritePrimesView(
//        store: Store<[Int], FavoritePrimesAction>(
//            initialValue: [2, 3, 5, 7, 11],
//            reducer: favoritePrimesReducer)))

// let store = Store<Int, ()>(initialValue: 0, reducer: { count, _ in count += 1 })
//
// store.send(())
// store.send(())
// store.send(())
// store.send(())
// store.send(())
//
// store.value
//
// let newStore = store.view { $0 }
//
// newStore.value
// newStore.send(())
// newStore.send(())
// newStore.send(())
// newStore.value
//
// store.value
//
// store.send(())
// store.send(())
// store.send(())
//
// newStore.value
// store.value
