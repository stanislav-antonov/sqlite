import Foundation
import SQLite3

class ResultSet {
    private weak var db: Db?
    private weak var statement: Statement?
    
    init(statement: Statement, db: Db) {
        self.db = db
        self.statement = statement
        self.statement?.inUse = true
    }
    
    public func next() -> Bool {
        let result: (hasRows: Bool, status: Status) = next()
        return result.hasRows
    }
    
    public func next() -> (hasRows: Bool, status: Status) {
        let status = Status()
        let rc: Int32 = sqlite3_step(statement!.ptr)
        
        status.isError = true
        status.resultCode = Int(rc)
        
        var errorMessage: String? = nil
        if (rc == SQLITE_DONE || rc == SQLITE_ROW) {
            // It's ok, nothing to do
            status.isError = false
        } else if (rc == SQLITE_BUSY || rc == SQLITE_LOCKED) {
            errorMessage = "Database is busy: \(self.db!.configuration!.fileName)"
        } else if (rc == SQLITE_ERROR || rc == SQLITE_MISUSE) {
            errorMessage = "Error on sqlite3_step (\(rc)): \(self.db!.lastError)"
        } else {
            errorMessage = "Unknown error on sqlite3_step (\(rc)): \(self.db!.lastError)"
        }
        
        if (errorMessage != nil) {
            NSLog(errorMessage!)
            status.errorMessage = errorMessage
        }
        
        var hasRows = false
        if (rc == SQLITE_ROW) {
            // So far some rows there
            hasRows = true
        } else {
            // No more rows, or some erorr was occured
            self.close()
        }
        
        return (hasRows, status)
    }
    
    public func close() {
        self.statement?.reset()
        self.db?.resultSetClosed(resultSet: self)
        
        self.db = nil
        self.statement = nil
    }
    
    deinit {
        self.close()
    }
    
    /*
     
     sqlite3_stmt *stmt;
     const char *sql = "SELECT ID, Name FROM User";
     int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
     if (rc != SQLITE_OK) {
     print("error: ", sqlite3_errmsg(db));
     return;
     }
     while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
     int id           = sqlite3_column_int (stmt, 0);
     const char *name = sqlite3_column_text(stmt, 1);
     // ...
     }
     if (rc != SQLITE_DONE) {
     print("error: ", sqlite3_errmsg(db));
     }
     sqlite3_finalize(stmt);
     
     */
}

