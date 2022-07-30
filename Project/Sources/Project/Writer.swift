
import Foundation
import Combine

public protocol Writer {
    func write(state: State, toProjectDirectory directory: URL) -> Future<URL, Error>
}
