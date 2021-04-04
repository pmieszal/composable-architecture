import Combine
import SwiftUI

public typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]

public func combine<Value, Action, Environment>(
    _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducers.flatMap { $0(&value, action, environment) }
        
        return effects
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnviroment>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>,
    environment: @escaping (GlobalEnviroment) -> LocalEnvironment)
-> Reducer<GlobalValue, GlobalAction, GlobalEnviroment > {
    return { globalValue, globalAction, globalEnviroment in
        guard let localAction = globalAction[keyPath: action] else {
            return []
        }
        
        let localEffects = reducer(&globalValue[keyPath: value], localAction, environment(globalEnviroment))
        
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

public func logging<Value, Action, Environment>(
    _ reducer: @escaping Reducer<Value, Action, Environment>
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducer(&value, action, environment)
        let newValue = value
        
        return [
            .fireAndForget {
                print("Action: \(action)")
                print("State:")
                dump(newValue)
                print("---")
            },
        ] + effects
    }
}

public final class Store<Value, Action>: ObservableObject {
    @Published public private(set) var value: Value
    
    private let reducer: Reducer<Value, Action, Any>
    private let environment: Any
    private var viewCancellable: Cancellable?
    private var effectCancellables: Set<AnyCancellable> = []
    
    public init<Environment>(initialValue: Value,
                reducer: @escaping Reducer<Value, Action, Environment>,
                environment: Environment) {
        value = initialValue
        self.reducer = { value, action, enviroment in
            reducer(&value, action, environment)
        }
        self.environment = environment
    }
    
    public func send(_ action: Action) {
        let effects = reducer(&value, action, environment)
        effects.forEach { effect in
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
                    effectCancellable)
            }
        }
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(value),
            reducer: { localValue, localAction, _ in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                
                return []
            },
            environment: environment)
        
        localStore.viewCancellable = $value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        
        return localStore
    }
}
