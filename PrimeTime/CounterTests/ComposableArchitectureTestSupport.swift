import ComposableArchitecture
import XCTest

enum StepType {
    case send
    case receive
}

struct Step<Value: Equatable, Action> {
    let type: StepType,
        action: Action,
        update: (inout Value) -> (),
        file: StaticString,
        line: UInt
    
    init(_ type: StepType,
         _ action: Action,
         _ update: @escaping (inout Value) -> (),
         file: StaticString = #file,
         line: UInt = #line) {
        self.type = type
        self.action = action
        self.update = update
        self.file = file
        self.line = line
    }
}

func assert<Value: Equatable, Action: Equatable, Environment>(
    initialValue: Value,
    reducer: Reducer<Value, Action, Environment>,
    environment: Environment,
    steps: Step<Value, Action>...,
    file: StaticString = #file,
    line: UInt = #line
) {
    var state = initialValue
    var effects: [Effect<Action>] = []
    
    steps.forEach { step in
        var expected = state
        
        switch step.type {
        case .send:
            if effects.isEmpty == false {
                XCTFail("Action sent before handling \(effects.count) pending effect(s)", file: step.file, line: step.line)
            }
            effects.append(contentsOf: reducer(&state, step.action, environment))
            
        case .receive:
            guard effects.isEmpty == false else {
                XCTFail("No pending effects to receive from", file: step.file, line: step.line)
                break
            }
            
            let effect = effects.removeFirst()
            var action: Action!
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
            
            let cancellable = effect.sink(
                receiveCompletion: { _ in
                    receivedCompletion.fulfill()
                },
                receiveValue: { action = $0 })
            
            if XCTWaiter.wait(for: [receivedCompletion], timeout: 0.01) != .completed {
                XCTFail("Timed out waiting for the effect to complete", file: step.file, line: step.line)
            }
            
            XCTAssertEqual(action, step.action, file: step.file, line: step.line)
            
            effects.append(contentsOf: reducer(&state, action, environment))
        }
        
        step.update(&expected)
        
        XCTAssertEqual(state, expected, file: step.file, line: step.line)
    }
    
    if effects.isEmpty == false {
        XCTFail("Assertion failed to handle \(effects.count) pending effect(s)", file: file, line: line)
    }
}
