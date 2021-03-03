import SwiftUI
import ComposableArchitecture

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
                    )
                )
            )
        }
    }
}
