import SwiftUI
import ComposableArchitecture
@testable import Counter

@main
struct PrimeTimeApp: App {
    var body: some Scene {
        WindowGroup {
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
}
