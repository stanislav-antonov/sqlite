import Foundation
import SQLite3

public enum Exception: Error {
    case message(String?)
}

