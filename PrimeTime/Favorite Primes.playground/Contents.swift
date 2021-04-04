import ComposableArchitecture
import PlaygroundSupport
import SwiftUI
@testable import FavoritePrimes

var environment = FavoritePrimesEnvironment.mock
environment.fileClient.load = { _ in
    Effect.sync {
        try! JSONEncoder().encode(Array(1...1000))
    }
}

PlaygroundPage.current.liveView = UIHostingController(
    rootView: NavigationView {
        FavoritePrimesView(
            store: Store<[Int], FavoritePrimesAction>(
                initialValue: [2, 3, 5, 7, 11],
                reducer: favoritePrimesReducer,
                environment: environment))
    })
