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
struct SaveLogs: ParsableCommand {
    

    static var logs: [String] = (try? Persistence.readPlainText(path: "log.txt")) ?? []
    
    static var configuration = CommandConfiguration(
        abstract: """
        
                 ____                  _
                / ___|  __ ___   _____| | ___   __ _
                \\___ \\ / _` \\ \\ / / _ \\ |/ _ \\ / _` |
                 ___) | (_| |\\ V /  __/ | (_) | (_| |
                |____/ \\__,_| \\_/ \\___|_|\\___/ \\__, |
                                               |___/
        """,
        discussion: "O Savelog é um programa feito para você guardar seus logins com uma chave de criptografia para que somente você tenha acesso a suas senhas",
        subcommands: [Add.self, Update.self, Delete.self, List.self, Search.self]
        
    )
    
    static func setup() {
        Persistence.projectName = "savelog"
        Persistence.saveIfEmpty(model: [], filename: "log.txt")
    }
    
//-----> BUSCAR LOGIN:
    static func showAll () {
        for log in SaveLogs.logs {
            let components = log.components(separatedBy: " ")
            let logUser = components[0]
            let logPassword = components[1]
            print("Usuario: \(logUser), Senha: \(logPassword)\n")
        }
    }
    
    // mateus
    static func showOne(user: String, key: String) {
        for log in SaveLogs.logs {
            let components = log.components(separatedBy: " ")
            // Filtro pelo nome do 'user'
            if components[0] == user {
                let cipheredPass = components[1]
                if let decipheredPass = decryptCrypto(cipheredPass, withKey: key) {
                    print(user, decipheredPass)
                }
                // Encerra
                return
            }
        }
    }
    
// ----> DELETAR USUARIO :)
    static func delete(user: String) -> Bool {
        
        var indexToDelete: Int?
        
        for i in 0..<SaveLogs.logs.count {
            let components = SaveLogs.logs[i].components(separatedBy: " ")
            let logUser = components[0]
            if logUser == user {
                indexToDelete = i
                break
            }
        }
        
        if let indexToDelete {
            // se indexToDelete existir, deleta e retorna `true`
            SaveLogs.logs.remove(at: indexToDelete)
            try? Persistence.savePlainText(content: SaveLogs.logs, path: "log.txt")
            return true
        } else {
            // se indexToDelete não existir, retorna `false`
            print("Login nao encontrado")
            return false
        }
    }
   
    struct Delete: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: " -Utilizado para deletar um login")
        @Argument (help: "Usuário")
        var user: String?
        @Option (help: "Chave de criptografia")
        var key: String
        
//        @Flag
//        var all: Bool = false
        
        mutating func run() {
            SaveLogs.setup()
            Persistence.projectName = "savelog"
            
//            if all {
//                do {
//                    try Persistence.savePlainText(content: [], path: "log.txt")
//                    print("Todos os logs foram deletados")
//                } catch {
//                    print("Não foi possível deletar todos os logs")
//                }
//                return
//            }
            
            if let user, SaveLogs.delete(user: user) {
                print("Login deletado")
            } else {
                print("Operação não concluida")
            }
        }
        
    }
    
// ----> SALVAR OS LOGINS :)
    
    struct Add: ParsableCommand {
        
        static var configuration = CommandConfiguration(abstract: " -Utilizado para adicionar um login")
      
        @Argument(help: "Usuário")
        var user: String
        
        @Argument(help: "Senha")
        var password: String
        
        @Option(help: "Chave de criptografia")
        var key: String
        
        mutating func run() {
            SaveLogs.setup()
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
        static var configuration = CommandConfiguration(abstract: " -Mostra a lista de logins salvos, com senhas criptografadas")
        
        func run() {
            SaveLogs.setup()
            Persistence.projectName = "savelog"
            //read()
            SaveLogs.showAll()
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
        static var configuration = CommandConfiguration(abstract: " -Substitui a senha do usuário escrito por uma nova ")
        
        @Option(help: "Chave de criptografia")
        var key: String
        @Argument(help: "Usuário")
        var user: String
        
        @Argument(help: "Senha")
        var password: String
        
        // logica da função update
        func update(user: String, password: String, key: String) {
            for i in 0..<logs.count {
                let components = logs[i].components(separatedBy: " ")
                let logUser = components[0]
                if logUser == user {
                    if save(user: user, password: password, key: key), SaveLogs.delete(user: user) {
                        print("Alteração feita")
                    } else {
                        print("Alteração não finalizada")
                    }
                }
            }
        }
        
        mutating func run() {
            SaveLogs.setup()
            Persistence.projectName = "savelog"
            update(user: user, password: password, key: key)
        }
    }
    
    struct Search: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: " -Utilizado para procurar um usuário especifico e retornar o login com sua senha descriptografada")
        
        @Argument(help: "Usuário para procurar")
        var user: String
        @Option(help: "Chave de criptografia")
        var key: String
        var indexToPrint: Int?
        
        mutating func run() {
            SaveLogs.setup()
            Persistence.projectName = "savelog"
            SaveLogs.showOne(user: user, key: key)
           
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
        SaveLogs.logs[index] = "\(user) \(ciphered)"
    } else {
        SaveLogs.logs.append("\(user) \(ciphered)")
    }
    
    do {
        try Persistence.savePlainText(content: SaveLogs.logs, path: "log.txt")
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


 
