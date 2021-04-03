import ComposableArchitecture
import PlaygroundSupport
import SwiftUI
@testable import Counter

Current = .mock
Current.nthPrime = { _ in .sync { 231237129837 } }

PlaygroundPage.current.liveView = UIHostingController(
    rootView: NavigationView {
        CounterView(
            store: Store<CounterViewState, CounterViewAction>(
                initialValue: CounterViewState(
                    alertNthPrime: nil,
                    count: 0,
                    favoritePrimes: [],
                    isNthPrimeButtonDisabled: false),
                reducer: logging(counterViewReducer)))
    })
