//
//  MockableMacro.swift
//
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct MockableMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let decl = declaration.as(ProtocolDeclSyntax.self) else {
            throw ServiceMacroError.badType
        }
        
        let access = decl.modifiers.first?.name.text ?? ""
        
        let name = decl.name.text
        let accessModifier = access == "" ? "" : "\(access) "
        
        let functions: String = decl.memberBlock.members.compactMap { member -> String? in
            guard let fDecl = member.decl.as(FunctionDeclSyntax.self) else { return nil }
            var function: String?
            do {
                function = try MockableMethodBuilder.map(accessModifier: accessModifier, declaration: fDecl, serviceName: name)
            } catch {
                context.diagnose((error as! Diagnostics).generate(for: member, severity: .error, fixIts: []))
            }
            return function
        }.joined(separator: "\n\n")

        let functionResults: String = decl.memberBlock.members.compactMap { member -> String? in
            guard let fDecl = member.decl.as(FunctionDeclSyntax.self),
                  let returnType = fDecl.signature.returnClause?.type.description else {
                return nil
            }
            
            let funcName = fDecl.name.text
            return "\(accessModifier)var \(funcName)Result: Result<\(returnType), Error> = .failure(SnowdropError(type: .unknown))"
        }.joined(separator: "\n")
        
        let functionsAndResults = functionResults + "\n\n" + functions
        
        return [
            """
            \(raw: ClassBuilder.printOutcome(type: .mock, accessModifier: accessModifier, name: name, functions: functionsAndResults))
            """
        ]
    }
}
