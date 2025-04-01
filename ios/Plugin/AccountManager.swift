/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The authentication manager object.
*/

import AuthenticationServices
import Foundation
import os
import Capacitor

extension NSNotification.Name {
    static let UserSignedIn = Notification.Name("UserSignedInNotification")
    static let ModalSignInSheetCanceled = Notification.Name("ModalSignInSheetCanceledNotification")
}

class AccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    var authenticationAnchor: ASPresentationAnchor?
    var isPerformingModalReqest = false
    var capPluginCall: CAPPluginCall?
    
    func signInWith(_ challenge: AuthChallenge, _ anchor: ASPresentationAnchor, _ preferImmediatelyAvailableCredentials: Bool, _ call: CAPPluginCall) {
        
        let domain = challenge.publicKey.rpId
        self.capPluginCall = call
        self.authenticationAnchor = anchor
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        let challengeData = Data(challenge.publicKey.challenge.utf8)
//        let challengeDataOld = challenge.publicKey.challenge.data(using: .utf8)!

//        let challengeData = Data(base64Encoded: challenge.publicKey.challenge)!
        
        print("challenge.publicKey.challenge: \(challenge.publicKey.challenge)")
        print("challengeData: \(String(data: challengeData, encoding: .utf8)!)")
//        print("challengeDataOld: \(String(data: challengeDataold, encoding: .utf8)!)")

        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
        
        // Also allow the user to use a saved password, if they have one.
        let passwordCredentialProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordCredentialProvider.createRequest()
        
        // Pass in any mix of supported sign-in request types.
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        
        if preferImmediatelyAvailableCredentials {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, no UI appears and
            // the system passes ASAuthorizationError.Code.canceled to call
            // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
            authController.performRequests(options: .preferImmediatelyAvailableCredentials)
        } else {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
            // passkey from a nearby device.
            authController.performRequests()
        }
        
        isPerformingModalReqest = true
    }
    
    func beginAutoFillAssistedPasskeySignIn(_ challenge: RegisterChallenge,anchor: ASPresentationAnchor) {
        self.authenticationAnchor = anchor
        
        let domain = challenge.publicKey.rp.id
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        let challenge = Data()
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
        
        // AutoFill-assisted requests only support ASAuthorizationPlatformPublicKeyCredentialAssertionRequest.
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performAutoFillAssistedRequests()
    }
    
    func signUpWith(_ challenge: RegisterChallenge, _ anchor: ASPresentationAnchor, _ call: CAPPluginCall) {
        
        self.capPluginCall = call
        self.authenticationAnchor = anchor
        
        let domain = challenge.publicKey.rp.id
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        // The userID is the identifier for the user's account.
        
        //        let challengeData = Data(challenge.utf8)
        //        let userIDData = Data(userId.utf8)
        //
        //        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challengeData,
        //                                                                                                  name: userName, userID: userIDData)
        
        let username = challenge.publicKey.user.name
        let rpID = challenge.publicKey.rp.id
        let userIDData = challenge.publicKey.user.id.data(using: .utf8)!
        let challengeData = Data(challenge.publicKey.challenge.utf8)

        print("blap")
        print("challenge.publicKey.challenge: \(challenge.publicKey.challenge)")
        print("challengeData: \(String(data: challengeData, encoding: .utf8)!)")

        // Create the Credential Provider with the specified RP ID
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        
        // Create the Registration Request using the Provider
        let registrationRequest = provider.createCredentialRegistrationRequest(
            challenge: challengeData,
            name: username,
            userID: userIDData
        )
        
        // Use only ASAuthorizationPlatformPublicKeyCredentialRegistrationRequests or
        // ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequests here.
        let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
        isPerformingModalReqest = true
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let logger = Logger()
        
        var result = [String: String]()
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            logger.log("A new passkey was registered: \(credentialRegistration)")
            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            //             let attestationObject = credentialRegistration.rawAttestationObject!
            //             let clientDataJSON = credentialRegistration.rawClientDataJSON
            //
            //            result = [
            //                "attestation": attestationObject.base64EncodedString(),
            //                "clientDataJSON": clientDataJSON.base64EncodedString()
            //            ]
            
            let id = credentialRegistration.credentialID
            let type = "public-key"
            let rawIdEncoded = base64UrlEncode(credentialRegistration.credentialID)
            //            let clientDataEncoded = base64UrlEncode(credentialRegistration.rawClientDataJSON)
            //            let clientDataEncoded = String(decoding: credentialRegistration.rawClientDataJSON, as: UTF8.self)
            let attestationObjectEncoded = base64UrlEncode(credentialRegistration.rawAttestationObject!)
            
            if let decodedChallenge = updateClientDataJSONChallenge(from: credentialRegistration.rawClientDataJSON) {
                let clientDataEncoded = base64UrlEncode(decodedChallenge)
                print("Decoded Challenge: \(clientDataEncoded)")
                
                // Construct JSON-like dictionary
                let jsonResponse: [String: Any] = [
                    "id": String(data: id, encoding: .utf8) ?? "",
                    "type": type,
                    "rawId": rawIdEncoded,
                    "response": [
                        "clientDataJSON": clientDataEncoded,
                        "attestationObject": attestationObjectEncoded
                    ]
                ]
                
                // Convert to JSON string
                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Passkey Registration JSON Response: \(jsonString)")
                    
                    self.capPluginCall!.resolve([
                        "credential": jsonString
                    ])
                } else {
                    print("Error converting to JSON")
                    self.capPluginCall!.reject("Error converting to JSON")
                }
            } else {
                print("Failed to decode challenge")
                self.capPluginCall!.reject("Failed to decode challenge")
            }
            
            // After the server verifies the registration and creates the user account, sign in the user with the new account.
            didFinishSignIn()
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            logger.log("A passkey was used to sign in: \(credentialAssertion)")
            
            
            if let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData,
               let signature = credentialAssertion.signature,
               let userID = credentialAssertion.userID {
                
                let stringUserID = String(data: userID, encoding: .utf8)
                let stringSignature = String(data: signature, encoding: .utf8)
                let stringAuthenticatorData = String(data: rawAuthenticatorData, encoding: .utf8)
                
                // Verify the below signature and clientDataJSON with your service for the given userID.
                let rawClientDataJSON = credentialAssertion.rawClientDataJSON
                let credentialID = credentialAssertion.credentialID
                let type = "public-key"
                let rawIdEncoded = base64UrlEncode(credentialAssertion.credentialID)
                //            let clientDataEncoded = base64UrlEncode(credentialAssertion.rawClientDataJSON)
                //            let clientDataEncoded = String(decoding: credentialAssertion.rawClientDataJSON, as: UTF8.self)
//                if let decodedChallenge = updateClientDataJSONChallenge(from: rawClientDataJSON) {
                    let clientDataEncoded = base64UrlEncode(credentialAssertion.rawClientDataJSON)
                    //                let clientDataEncoded = String(decoding: decodedChallenge, as: UTF8.self)
                    print("Decoded Challenge: \(clientDataEncoded)")
                    
                    // Construct JSON-like dictionary
//                    let jsonResponse: [String: Any] = [
//                        "authenticatorAttachment": "platform",
//                        "id": rawIdEncoded,
//                        "type": type,
//                        "rawId": rawIdEncoded,
//                        "response": [
//                            "clientDataJSON": clientDataEncoded,
//                            "authenticatorData": base64UrlEncode(rawAuthenticatorData),
//                            "signature": base64UrlEncode(signature),
//                            "userHandle": base64UrlEncode(userID)
//                        ]
//                    ]

                    let jsonString = """
                     {
                       "authenticatorAttachment": "platform",
                       "id": "\(rawIdEncoded)",
                       "type": "public-key",
                       "rawId": "\(rawIdEncoded)",
                       "response": {
                         "clientDataJSON": "\(credentialAssertion.rawClientDataJSON.base64EncodedString())",
                         "authenticatorData": "\(base64UrlEncode(rawAuthenticatorData))",
                         "signature": "\(base64UrlEncode(signature))",
                         "userHandle": "\(base64UrlEncode(userID))"
                       }
                     }
                    """

                    self.capPluginCall!.resolve([
                        "credential": jsonString
                    ])

//
//                    let response = PasskeyAuthResponse(
//                        clientDataJSON: clientDataEncoded,
//                        authenticatorData: base64UrlEncode(rawAuthenticatorData),
//                        signature: base64UrlEncode(signature),
//                        userHandle: base64UrlEncode(userID)
//                    )
//
//                    // Create the main response object
//                    let passkeyResponse = PasskeyResponse(
//                        authenticatorAttachment: "platform",
//                        id: rawIdEncoded,
//                        type: "public-key",
//                        rawId: rawIdEncoded,
//                        response: response
//                    )
//                    
//                    let encoder = JSONEncoder()
//                    do {
//                        let jsonData = try encoder.encode(passkeyResponse)
//                        self.capPluginCall!.resolve([
//                            "credential": String(data: jsonData, encoding: .utf8)
//                        ])
//                    } catch {
//                        print("Error encoding JSON: \(error)")
//                        self.capPluginCall!.reject("Error converting to JSON")
//                    }
//
//                    // Convert to JSON string
//                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []),
//                       let jsonString = String(data: jsonData, encoding: .utf8) {
//                        print("Passkey Authentication JSON Response: \(jsonString)")
//                        
//                        self.capPluginCall!.resolve([
//                            "credential": jsonString
//                        ])
//                    } else {
//                        print("Error converting to JSON")
//                        self.capPluginCall!.reject("Error converting to JSON")
//                    }
//                } else {
//                    print("Failed to decode challenge")
//                    self.capPluginCall!.reject("Failed to decode challenge")
//                }
            }
            
            
            // After the server verifies the assertion, sign in the user.
            didFinishSignIn()
        case let passwordCredential as ASPasswordCredential:
            logger.log("A password was provided: \(passwordCredential)")
            // Verify the userName and password with your service.
            // let userName = passwordCredential.user
            // let password = passwordCredential.password
            
            // After the server verifies the userName and password, sign in the user.
            didFinishSignIn()
        default:
            fatalError("Received unknown authorization type.")
        }
        
        isPerformingModalReqest = false
        
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
//            let jsonString = String(data: jsonData, encoding: .utf8)!
//            self.capPluginCall?.resolve(["result": jsonString])
//        } catch {
//            self.capPluginCall?.reject("Failed to serialize result to JSON")
//        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let logger = Logger()
        guard let authorizationError = error as? ASAuthorizationError else {
            isPerformingModalReqest = false
            logger.error("Unexpected authorization error: \(error.localizedDescription)")
            return
        }
        
        if authorizationError.code == .canceled {
            // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
            // This is a good time to show a traditional login form, or ask the user to create an account.
            logger.log("Request canceled.")
            
            if isPerformingModalReqest {
                didCancelModalSheet()
            }
        } else {
            // Another ASAuthorization error.
            // Note: The userInfo dictionary contains useful information.
            logger.error("Error: \((error as NSError).userInfo)")
        }
        
        isPerformingModalReqest = false
        
        if let capPluginCall = self.capPluginCall {
            capPluginCall.reject(error.localizedDescription)
        } else {
            // Throw
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor!
    }
    
    func didFinishSignIn() {
        NotificationCenter.default.post(name: .UserSignedIn, object: nil)
    }
    
    func didCancelModalSheet() {
        NotificationCenter.default.post(name: .ModalSignInSheetCanceled, object: nil)
    }
    
    func base64UrlEncode(_ data: Data) -> String {
        var encodedString = data.base64EncodedString()
        encodedString = encodedString
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        return encodedString
    }
    
    func base64UrlDecode(_ base64String: String) -> Data? {
        var base64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch base64.count % 4 {
        case 2: base64 += "=="
        case 3: base64 += "="
        default: break
        }
        return Data(base64Encoded: base64)
    }
    func base64UrlDecodeToStr(_ base64String: String) -> String {
        var base64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch base64.count % 4 {
        case 2: base64 += "=="
        case 3: base64 += "="
        default: break
        }
        let d = Data(base64Encoded: base64)!
        return String(data: d, encoding: .utf8)!
    }

    func base64UrlToBase64(_ base64Url: String) -> String {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch base64.count % 4 {
        case 2: base64 += "=="
        case 3: base64 += "="
        default: break
        }
        return base64
    }
    
    func updateClientDataJSONChallenge(from rawClientDataJSON: Data) -> Data? {
        
        print("rawClientDataJSON \(rawClientDataJSON.base64EncodedString())")
        
        // Decode the raw clientDataJSON to a JSON object
        guard var clientData = try? JSONSerialization.jsonObject(with: rawClientDataJSON, options: []) as? [String: Any],
              let base64Challenge = clientData["challenge"]
               else {
            print("Failed to decode clientDataJSON or challenge")
            return nil
        }
        
        let decodedChallengeStr = base64UrlDecodeToStr(base64Challenge as? String ?? "")
        
        // Update the challenge field to the decoded value
        clientData["challenge"] = decodedChallengeStr as Any
        
        print("clientData[origin]: \(clientData["origin"]!)")

//        if let escapedOrigin = clientData["origin"] as? String {
////            clientData["origin"] = escapedOrigin.replacingOccurrences(of: "//", with: "/") as AnyObject
//            clientData["origin"] = "https://0d4b-58-104-243-37.ngrok-free.app" as Any
//        }

        clientData["crossOrigin"] = false as Any
        
        // Extract and reorder fields to match the Web structure
//        let reorderedClientData: [String: Any] = [
//            "type": clientData["type"] ?? "",
//            "challenge": clientData["challenge"] ?? "",
//            "origin": clientData["origin"] ?? "",
//            "crossOrigin": clientData["crossOrigin"] ?? false
//        ]
//

        let type = clientData["type"] as? String
        let challenge = clientData["challenge"] as? String
        let origin = clientData["origin"] as? String
        
//        let cdj = ClientDataJSON(
//            type: type!,
//            challenge: challenge!,
//            origin: origin!,
//            crossOrigin: false)
        
//        print("clientData[origin]: \(clientData["origin"]!)")
//
//        let encoder = JSONEncoder()
//        do {
//            let jsonData = try encoder.encode(cdj)
//            return jsonData
//        } catch {
//            print("Error encoding JSON: \(error)")
//            return nil
//        }

        let updatedStr = "{\"type\":\"\(type!)\",\"challenge\":\"\(challenge!)\",\"origin\":\"\(origin!)\",\"crossOrigin\":false}"

        let updatedData = updatedStr.data(using: .utf8)
        
        return updatedData!
        
//        // Serialize the updated JSON object back to Data
//        if let updatedData = try? JSONSerialization.data(data: updatedStr., options: [JSONSerialization.WritingOptions.withoutEscapingSlashes]) {
//            return updatedData
//        } else {
//            print("Failed to serialize updated clientDataJSON")
//            return nil
//        }
    }
    
    func unwrapChallengeInClientDataJSON(clientDataJSONData: Data) -> String {
        var unwrappedClientDataJSON = base64UrlEncode(clientDataJSONData)
        
        do {
            
            guard var clientDataJSON = try JSONSerialization.jsonObject(with: clientDataJSONData) as? Dictionary<String, String> else {
                return ""
            }
            
            let challenge = clientDataJSON["challenge"]!
            let challengeDecoded = base64UrlDecode(challenge)!
            
            guard let challengeDataJSON = try JSONSerialization.jsonObject(with: challengeDecoded) as? Dictionary<String, AnyObject> else {
                return unwrappedClientDataJSON
            }
            
            let innerChallenge = challengeDataJSON["challenge"]
            clientDataJSON["challenge"] = innerChallenge as? String
            let newClientDataJSON = try JSONSerialization.data(withJSONObject: clientDataJSON, options: [])
            unwrappedClientDataJSON = base64UrlEncode(newClientDataJSON)
            
        } catch let error {
            print(error)
            return unwrappedClientDataJSON
        }
        
        return unwrappedClientDataJSON
    }

    
    func unescapeJsonString(_ jsonString: String) -> String {
        let data = "\"\(jsonString)\"".data(using: .utf8)!
        let decodedString = try? JSONDecoder().decode(String.self, from: data)
        return decodedString ?? jsonString
    }
    
    func decodeUserIDTwice(encodedUserID: String) -> String? {
        // First decoding
        guard let firstDecoded = base64UrlDecode(encodedUserID),
              let firstDecodedString = String(data: firstDecoded, encoding: .utf8) else {
            print("First decoding failed")
            return nil
        }
        
        // Second decoding (if necessary)
        if let secondDecoded = base64UrlDecode(firstDecodedString),
           let secondDecodedString = String(data: secondDecoded, encoding: .utf8) {
            return secondDecodedString
        } else {
            // Return the result after the first decoding if the second decoding fails
            return firstDecodedString
        }
    }
}

