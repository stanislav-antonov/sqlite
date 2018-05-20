import Foundation
import SQLite3

class Connection {
    private var _ptr: OpaquePointer?
    public var ptr: OpaquePointer? {
        return _ptr
    }
    
    private var startBusyRetryTime: TimeInterval?
    private weak var configuration: Configuration!
    
    private var _isOpen: Bool!
    public var isOpen: Bool {
        return _isOpen
    }
    
    init(configuration: Configuration) {
        self._isOpen = false
        self.configuration = configuration
    }
    
    public static func open(configuration: Configuration) throws -> Connection {
        let connection = Connection(configuration: configuration)
        if (try connection.open() == false) {
            throw Exception.message("Failed to open connection")
        }
        
        return connection
    }
    
    public func open() throws -> Bool {
        if (self._isOpen) {
            return true
        }
        
        if (self.ptr != nil) {
            self.close()
        }
        
        let rc = sqlite3_open_v2(self.configuration.path, &self._ptr, self.configuration.openFlags, nil)
        if (rc != SQLITE_OK) {
            defer { self.close() }
            throw Exception.message(Utils.getErrorMessage(ptr: self.ptr))
        }
        
        self.setBusyRetryHandler()
        self._isOpen = true
        
        return true
    }
    
    private func setBusyRetryHandler() {
        if (configuration.busyRetryInterval > 0) {
            sqlite3_busy_handler(self._ptr, { (ptr, count) in
                let _self: Connection = Utils.bridge(ptr: ptr!)
                
                if (count == 0) {
                    _self.startBusyRetryTime = Date.timeIntervalSinceReferenceDate
                    return 1
                }
                
                let delta = Date.timeIntervalSinceReferenceDate - _self.startBusyRetryTime!
                if (delta < _self.configuration.busyRetryInterval) {
                    let mills = (Int32)(arc4random_uniform(50) + 50)
                    sqlite3_sleep(mills)
                    return 1
                }
                
                return 0
            }, Utils.bridge(obj: self))
        } else {
            sqlite3_busy_handler(self._ptr, nil, nil)
        }
    }
    
    public func close() {
        if (self.ptr != nil) {
            sqlite3_close(self._ptr!)
            self._ptr = nil
            self._isOpen = false
        }
    }
    
    deinit {
        self.close()
    }
}

