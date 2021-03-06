import SwiftUI
import Combine

public struct Effect<Output>: Publisher {
    public typealias Failure = Never
    
    let publisher: AnyPublisher<Output, Failure>
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        publisher.receive(subscriber: subscriber)
    }
}

public extension Publisher where Failure == Never {
    func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: eraseToAnyPublisher())
    }
}

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

public final class Store<Value, Action>: ObservableObject {
    @Published private(set) public var value: Value
    
    private let reducer: Reducer<Value, Action>
    private var viewCancellable: Cancellable?
    private var effectCancellables: Set<AnyCancellable> = []
    
    public init(initialValue: Value,
                reducer: @escaping Reducer<Value, Action>) {
        value = initialValue
        self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        let effects = reducer(&value, action)
        effects.forEach { (effect) in
            var effectCancellable: AnyCancellable?
            var didComplete = false
            
            effectCancellable = effect.sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    guard let effectCancellable = effectCancellable else {
                        return
                    }
                    
                    self?.effectCancellables.remove(effectCancellable)
                },
                receiveValue: send)
            
            if didComplete == false, let effectCancellable = effectCancellable {
                effectCancellables.insert(
                    effectCancellable
                )
            }
        }
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                
                return []
            }
        )
        
        localStore.viewCancellable = self.$value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        
        return localStore
    }
}

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducers.flatMap { $0(&value, action) }
        
        return effects
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else {
            return []
        }
        
        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        
        return localEffects.map { localEffect in
            localEffect.map { localAction -> GlobalAction in
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                
                return globalAction
            }
            .eraseToEffect()
        }
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducer(&value, action)
        let newValue = value
        
        return [
            .fireAndForget {
                print("Action: \(action)")
                print("State:")
                dump(newValue)
                print("---")
            }
        ] + effects
    }
}
