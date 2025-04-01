import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PasskeymeSDKPlugin)
public class PasskeymeSDKPlugin: CAPPlugin {
    private let implementation = PasskeymeSDK()

    @objc func passkeyRegister(_ call: CAPPluginCall) {

        if let challengeJsonString = call.getString("challenge"),
           let data = challengeJsonString.data(using: .utf8) {
            do {
                // Use a Codable struct or dictionary to represent the data
                let challenge = try! JSONDecoder().decode(RegisterChallenge.self, from: data)

                DispatchQueue.main.async {
                    if let window = self.bridge?.viewController?.view.window {
                        self.implementation.passkeyRegister(challenge, window, call)
                    } else {
                        call.reject("Cannot open window")
                    }
                }
            } catch {
                call.reject("Invalid JSON data")
            }
        } else {
            call.reject("Missing data")
        }
    }

    @objc func passkeyAuthenticate(_ call: CAPPluginCall) {
        if let challengeJsonString = call.getString("challenge"),
           let data = challengeJsonString.data(using: .utf8) {
            do {
                // Use a Codable struct or dictionary to represent the data
                let challenge = try! JSONDecoder().decode(AuthChallenge.self, from: data)

                DispatchQueue.main.async {
                    if let window = self.bridge?.viewController?.view.window {
                        self.implementation.passkeyAuthenticate(challenge, window, call)
                    } else {
                        call.reject("Cannot open window")
                    }
                }
            } catch {
                call.reject("Invalid JSON data")
            }
        } else {
            call.reject("Missing data")
        }
    }
}

