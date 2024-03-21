// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
// ParsableCommand -> Subcomando
//logs[i].components(separatedBy: " ") // "gabi 123" -> ["gabi", "123"]

//---->SUBCOMANDOS :)
@main
struct PasswordGenerator: ParsableCommand {
    
    @Flag(help: "Crypto password")
    var crypto = false
    static var logs: [String] = (try? Persistence.readPlainText(path: "log.txt")) ?? []
    
    static var configuration = CommandConfiguration(
        abstract: "",
        subcommands: [Add.self, Update.self, Delete.self, List.self, Search.self]
    )
    
//-----> BUSCAR LOGIN:
    static func showAll () {
        for log in PasswordGenerator.logs {
            let components = log.components(separatedBy: " ")
            let logUser = components[0]
            let logPassword = components[1]
            print("Usuario: \(logUser), Senha: \(logPassword)\n")
        }
    }
    
    static func showOne(user: String, key: String) {
        for log in PasswordGenerator.logs {
            let components = log.components(separatedBy: " ")
            let user = components[0]
            let cipheredPass = components[1]
            if let decipheredPass = decryptCrypto(cipheredPass, withKey: key) {
                print(user, decipheredPass)
            }
        }
    }
    
// ----> DELETAR USUARIO :)
    struct Delete: ParsableCommand {
        @Argument (help: "User")
        var user: String
        @Option(help: "Crypto key")
        var key: String
        func delete(user: String) -> Bool {
            
            var indexToDelete: Int?
            
            for i in 0..<logs.count {
                let components = logs[i].components(separatedBy: " ")
                let logUser = components[0]
                if logUser == user {
                    indexToDelete = i
                }
            }
            
            if let indexToDelete {
                // se indexToDelete existir, deleta e retorna `true`
                logs.remove(at: indexToDelete)
                try? Persistence.savePlainText(content: logs, path: "log.txt")
                return true
            } else {
                // se indexToDelete não existir, retorna `false`
                print("Login nao encontrado")
                return false
            }
        }
        mutating func run() {
            Persistence.projectName = "savelog"
            if delete(user: user ) {
                print("Login deletado")
            } else {
                print("Operação não concluida")
            }
        }
        
    }
    
// ----> SALVAR OS LOGINS :)
    
    struct Add: ParsableCommand {
      
        @Argument(help: "User")
        var user: String
        
        @Argument(help: "Password")
        var password: String
        
        @Option(help: "Crypto key")
        var key: String
        
        mutating func run() {
            Persistence.projectName = "savelog"
            
            if save(user: user, password: password, key: key) {
                print("Login salvo")
            } else {
                print("Error")
            }
        }
        
    }
    
//----> MOSTRAR OS DADOS :)
    
    struct List: ParsableCommand {
        
        func run() {
            Persistence.projectName = "savelog"
            //read()
            PasswordGenerator.showAll()
        }
        func read() {
            var x: Int = 1
            for i in 0...(logs.count - 1) {
            print("\(x).", logs[i])
                x+=1
            }
            print((try? Persistence.readPlainText(path: "log.txt")) ?? "Error")
        }
        
    }
    
//----> ALTERAR LOGIN :)
    
    struct Update: ParsableCommand {
        @Option(help: "Crypto key")
        var key: String
        @Argument(help: "User")
        var user: String
        
        @Argument(help: "Password")
        var password: String
        
        // logica da função update
        func update(user: String, password: String) {
            for i in 0..<logs.count {
                let components = logs[i].components(separatedBy: " ")
                let logUser = components[0]
                if logUser == user {
                    logs[i] = "\(user) \(password)"
                    if save(user: user, password: password, key: key) {
                        print("Alteração feita")
                    } else {
                        print("Alteração não finalizada")
                    }
                }
            }
        }
        
        mutating func run() {
            Persistence.projectName = "savelog"
            update(user: user, password: password)
        }
    }
    
    struct Search: ParsableCommand {
        @Argument(help: "User to search")
        var user: String
        @Option(help: "Crypto key")
        var key: String
        var indexToPrint: Int?
        
        mutating func run() {
            Persistence.projectName = "savelog"
            PasswordGenerator.showOne(user: user, key: key)
        }
        
    }
}

//-----> SALVAR:)

func save(user: String, password: String? = "", key: String?, index: Int? = nil) -> Bool {
    guard let password, let key, let ciphered = crypto(password, withKey: key) else {
        print("Null parameters")
        return false
    }
    
    if let index {
        PasswordGenerator.logs[index] = "\(user) \(ciphered)"
    } else {
        PasswordGenerator.logs.append("\(user) \(ciphered)")
    }
    
    do {
        try Persistence.savePlainText(content: PasswordGenerator.logs, path: "log.txt")
        return true
    } catch {
        return false
    }
}

//----> CRIPTOGRAFAR E DESCRIPTOGRAFAR SENHAS :)

func crypto(_ input: String, withKey key: String) -> String? {
    guard let inputData = input.data(using: .utf8),
        let keyData = key.data(using: .utf8) else {
        return nil
    }
    
    let inputBytes = [UInt8](inputData)
    let keyBytes = [UInt8](keyData)
    
    var encryptedBytes = [UInt8]()
    
    for i in 0..<inputBytes.count {
        encryptedBytes.append(inputBytes[i] ^ keyBytes[i % keyBytes.count])
    }
    
    let encryptedData = Data(encryptedBytes)
    return encryptedData.base64EncodedString()
}

func decryptCrypto(_ encryptedString: String, withKey key: String) -> String? {
    guard let encryptedData = Data(base64Encoded: encryptedString),
        let keyData = key.data(using: .utf8) else {
        return nil
    }
    
    let encryptedBytes = [UInt8](encryptedData)
    let keyBytes = [UInt8](keyData)
    
    var decryptedBytes = [UInt8]()
    
    for i in 0..<encryptedBytes.count {
        decryptedBytes.append(encryptedBytes[i] ^ keyBytes[i % keyBytes.count])
    }
    
    let decryptedData = Data(decryptedBytes)
    
    return String(data: decryptedData, encoding: .utf8)
}

/*
    > savelog add "gabi 123" --key "academy"
    ...usar key academy para criptografar 123
    ...asdlk12309asdk
    ...salvando senha criptografada e usuario
    ...gabi asdlk12309asdk
 
    > savelog read "gabi" --key "academy"
    ...usar key academy para descriptografar asdlk12309asdk
    ...123
 
*/
