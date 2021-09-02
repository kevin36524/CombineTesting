//: [Previous](@previous)

import Foundation
import Combine

var str = "Hello, playground"

(1...3).publisher
    .map{ return "Hello \($0)"}
    .sink {
        print($0)
    }

enum NumErr: Error {
    case evenNumberError(Int)
    case unknown
}

(1...4).publisher
    .tryMap {
        if ($0%2 ==  0) {
            throw NumErr.evenNumberError($0)
        }
        return "tryMap \($0)"
    }
//    .mapError { (err) -> NumErr in
//        if let err = err as? NumErr {
//            return err
//        }
//        return NumErr.unknown
//    }
    .retry(2)
//    .replaceError(with: "Error Value")
    .sink { (comp) in
        switch comp {
        case .failure(let err):
            if case let NumErr.evenNumberError(num) = err {
                print("Err number is \(num)")
            }
        default:
            print("No Err")
        }
    } receiveValue: {
        print($0)
    }


func getPub(returnJust: Bool) -> AnyPublisher<Int, Never> {
    if (returnJust)  {
        return Just(1).eraseToAnyPublisher()
    }
    
    return (1...3).publisher.eraseToAnyPublisher()
}

getPub(returnJust: false).sink {
    print($0)
}

/// Flat Map ==>  used for publisher chaning

let pub1 = Just(3)
pub1.flatMap {
    return getPub(returnJust: $0%2 == 0)
}.sink {
    print("FlatMap \($0)")
}

let typeText = [
    ("H",0.1),
    ("He",0.5),
    ("Hel",1.5),
    ("Hell",1.9),
    ("Hello",2.1)
]

var cancelBag = Set<AnyCancellable>()
let typePub = PassthroughSubject<String, Never>()
typePub.debounce(for: .seconds(0.6), scheduler: DispatchQueue.main).sink {
    print("DEBOUNCE I am getting \($0) \(Date().timeIntervalSince(now))")
}.store(in: &cancelBag)

typePub.throttle(for: .seconds(1.0), scheduler: DispatchQueue.main, latest: false)
    .sink {
        print ("THROTTLE I am getting \($0) \(Date().timeIntervalSince(now))")
    }.store(in: &cancelBag)

let now = Date()

for bounce in typeText {
    DispatchQueue.main.asyncAfter(deadline: .now() + bounce.1) {
        typePub.send(bounce.0)
    }
}
//: [Next](@next)


class TestAssign {
    var newStuff : String = "" {
        didSet  {
            print("I am setting the value \(newStuff)")
        }
    }
}

let assignObj =  TestAssign()

typePub
    .assign(to: \.newStuff, on: assignObj)
    .store(in: &cancelBag)
