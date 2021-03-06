import Combine
import ComposableArchitecture
import Counter
import Dispatch
import FavoritePrimes
import PlaygroundSupport
import PrimeModal
import SwiftUI

struct Effect<A> {
    let run: (@escaping (A) -> ()) -> ()
    
    func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
        return Effect<B> { callback in run { a in callback(f(a)) } }
    }
}

let anIntInTwoSeconds = Effect<Int> { callback in
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        callback(42)
    }
}

// anIntInTwoSeconds.run { int in print(int) }
// anIntInTwoSeconds.map { $0 * $0 }.run { int in print(int) }

let aFutureInt = Deferred {
    Future<Int, Never>.init { promise in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Hello from the future")
            promise(.success(42))
        }
    }
}

// aFutureInt.subscribe(
//    AnySubscriber<Int, Never>(
//        receiveSubscription: { (subscription) in
//            print("subscription")
//            subscription.cancel()
//            subscription.request(.unlimited)
//        },
//        receiveValue: { (value) -> Subscribers.Demand in
//            print("value", value)
//            return .unlimited
//        },
//        receiveCompletion: { (completion) in
//            print("completion")
//        }))

//let cancellable = aFutureInt.sink { value in
//    print(value)
//}

//cancellable.cancel()

let passthrough = PassthroughSubject<Int, Never>.init()
let currentValue = CurrentValueSubject<Int, Never>.init(2)

let c1 = passthrough.sink { (value) in
    print("passthrough", value)
}

let c2 = currentValue.sink { (value) in
    print("currentValue", value)
}

passthrough.send(42)
currentValue.send(1729)
passthrough.send(42)
currentValue.send(1729)

// PlaygroundPage.current.liveView = UIHostingController(
//    rootView: NavigationView {
//        CounterView(
//            store: Store<CounterViewState, CounterViewAction>(
//                initialValue: CounterViewState(
//                    alertNthPrime: nil,
//                    count: 2,
//                    favoritePrimes: [],
//                    isNthPrimeButtonDisabled: false),
//                reducer: logging(counterViewReducer)))
//    })

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
