import UIKit
import Combine

var str = "Hello, playground"

/// Just
let justPub = Just("Hello World")

justPub.sink {
    print($0)
}

(1...3).publisher.sink {
    print($0)
}

let passThroughSubject = PassthroughSubject<Int, Never>()
var allCancellables = Set<AnyCancellable>()

passThroughSubject.sink { (comp) in
    print("I got completion")
} receiveValue: {
    print("PassThroughSubject \($0)")
}.store(in: &allCancellables)


passThroughSubject.send(1)

passThroughSubject.sink {
    print("I am in second subs \($0)")
}.store(in: &allCancellables)

(2...5).forEach {
    passThroughSubject.send($0)
}


let cvs = CurrentValueSubject<Int, Never>(0)

cvs.sink { (comp) in
    print("I got completion")
} receiveValue: {
    print("CVS \($0)")
}.store(in: &allCancellables)


cvs.send(1)

let subscription2 = cvs.sink {
    print("CVS-2 \($0)")
}

(2...5).forEach {
    cvs.send($0)
}
subscription2.cancel()
cvs.value
cvs.value = 7
cvs.send(completion: .finished)
cvs.value = 8
cvs.value





