import Foundation

struct RP: Codable {
    let name: String
    let id: String
}

struct User: Codable {
    let id: String
    let name: String
    let displayName: String
}

struct PublicKeyCredentialParameters: Codable {
    let type: String
    let alg: Int
}

struct ExcludeCredential: Codable {
    let type: String
    let id: String
}

struct AuthenticatorSelection: Codable {
    let requireResidentKey: Bool
    let userVerification: String
}

struct Extensions: Codable {
    let uvm: Bool
    let credProps: Bool
}

struct RegisterPublicKey: Codable {
    let rp: RP
    let user: User
    let challenge: String
    let pubKeyCredParams: [PublicKeyCredentialParameters]
    let timeout: Int
    let attestation: String
    let excludeCredentials: [ExcludeCredential]
    let authenticatorSelection: AuthenticatorSelection
    let extensions: Extensions
}

struct RegisterChallenge: Codable {
    let publicKey: RegisterPublicKey
}

/*
 {
   "challenge": {
     "publicKey": {
       "challenge": "qyaYu-kx5cTIAQX8T2k9HjlfhxocEmS5oPUHbrTsXPc",
       "timeout": 60000,
       "rpId": "a3b0-58-104-243-37.ngrok-free.app",
       "allowCredentials": [
         {
           "type": "public-key",
           "id": "7abVULSdJ1rIERMykLNPOOP9cSA"
         },
         {
           "type": "public-key",
           "id": "yhkV34nJFgwinlGe9mXw6McaFKI"
         }
       ],
       "userVerification": "preferred"
     }
   }
 }
 */

struct AllowCredential: Codable {
    let type: String
    let id: String
}

struct AuthPublicKey: Codable {
    let challenge: String
    let timeout: Int
    let rpId: String
    let allowCredentials: [AllowCredential]
    let userVerification: String
}

struct AuthChallenge: Codable {
    let publicKey: AuthPublicKey
}

// Main struct for the authentication response
struct PasskeyResponse: Codable {
    let authenticatorAttachment: String
    let id: String
    let type: String
    let rawId: String
    let response: PasskeyAuthResponse
}

// Nested struct for the response object
struct PasskeyAuthResponse: Codable {
    let clientDataJSON: String
    let authenticatorData: String
    let signature: String
    let userHandle: String
}

// Nested struct for the response object
struct ClientDataJSON: Codable {
    let type: String
    let challenge: String
    let origin: String
    let crossOrigin: Bool
}
