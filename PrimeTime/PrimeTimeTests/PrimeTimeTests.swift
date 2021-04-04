import ComposableArchitecture
import XCTest
@testable import Counter
@testable import FavoritePrimes
@testable import PrimeModal
@testable import PrimeTime

class PrimeTimeTests: XCTestCase {
    func testIntergration() {
        Counter.Current = .mock
        FavoritePrimes.Current = .mock
    }
}
