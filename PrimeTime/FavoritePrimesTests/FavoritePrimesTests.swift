import XCTest
@testable import FavoritePrimes

class FavoritePrimesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        Current = .mock
    }
    
    func testDeleteFavoritePrimes() throws {
        var state = [2, 3, 5, 7]
        let effects = favoritePrimesReducer(state: &state, action: FavoritePrimesAction.deleteFavoritePrimes([2]))
        
        XCTAssertEqual(state, [2, 3, 7])
        XCTAssert(effects.isEmpty)
    }
    
    func testSaveButtonTapped() throws {
        var didSave = false
        
        Current.fileClient.save = { _, _ in
            .fireAndForget {
                didSave = true
            }
        }
        
        var state = [2, 3, 5, 7]
        let effects = favoritePrimesReducer(state: &state, action: FavoritePrimesAction.saveButtonTapped)
        
        XCTAssertEqual(state, [2, 3, 5, 7])
        XCTAssertEqual(effects.count, 1)
        
        effects[0].sink { _ in XCTFail() }
        
        XCTAssert(didSave)
    }
    
    func testLoadFavoritePrimesFlow() throws {
        Current.fileClient.load = { _ in
            .sync { try! JSONEncoder().encode([2, 31]) }
        }
        
        var state = [2, 3, 5, 7]
        var effects = favoritePrimesReducer(state: &state, action: FavoritePrimesAction.loadButtonTapped)
        
        XCTAssertEqual(state, [2, 3, 5, 7])
        XCTAssertEqual(effects.count, 1)
        
        var nextAction: FavoritePrimesAction!
        let receivedCompletion = expectation(description: "receivedCompletion")
        
        effects[0].sink(
            receiveCompletion: { _ in
                receivedCompletion.fulfill()
            },
            receiveValue: { action in
                XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
                nextAction = action
            })
        
        wait(for: [receivedCompletion], timeout: 0)
        
        effects = favoritePrimesReducer(state: &state, action: nextAction)
        
        XCTAssertEqual(state, [2, 31])
        XCTAssert(effects.isEmpty)
    }
}
