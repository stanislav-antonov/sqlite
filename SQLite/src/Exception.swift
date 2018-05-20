import Foundation
import SQLite3

public enum Exception: Error {
    case fromString(String)
    case fromPtr(OpaquePointer?)
    case fromMutablePtr(UnsafeMutablePointer<Int8>?)
}

extension Exception: LocalizedError {
    public var errorDescription: String? {
        let noError: String = "No error message was provided from sqlite."
        switch (self) {
        case .fromPtr(let ptr):
            if (ptr != nil) {
                if let error = sqlite3_errmsg(ptr) {
                    return String(cString: error)
                }
            }
            
            return noError
        case .fromMutablePtr(let ptr):
            if (ptr != nil) {
                defer {
                    sqlite3_free(ptr)
                    ptr?.deinitialize()
                }
                
                return String(cString: ptr!)
            }
            
            return noError
        default:
            return noError
        }
    }
}

