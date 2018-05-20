import Foundation

protocol SchemaActionsProtocol {
    var version: Int { get }
    
    func onCreate(newVersion: Int, oldVersion: Int) -> Void
    func onUpdate(newVersion: Int, oldVersion: Int) -> Void
}

