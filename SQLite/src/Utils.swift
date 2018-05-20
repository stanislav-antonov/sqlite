import Foundation
import SQLite3

class Utils {
    private static let noErrorMessage: String = "No error message"
    
    static func bridge<T: AnyObject>(obj: T) -> UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }
    
    static func bridge<T: AnyObject>(ptr: UnsafeMutableRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    }
    
    static func getErrorMessage(ptr: OpaquePointer?) -> String {
        if (ptr != nil) {
            if let error = sqlite3_errmsg(ptr) {
                return String(cString: error)
            }
        }
        
        return noErrorMessage
    }
    
    static func getErrorMessage(ptr: UnsafeMutablePointer<Int8>?) -> String {
        if (ptr != nil) {
            defer {
                sqlite3_free(ptr)
                ptr?.deinitialize()
            }
            
            return String(cString: ptr!)
        }
        
        return noErrorMessage
    }
}
