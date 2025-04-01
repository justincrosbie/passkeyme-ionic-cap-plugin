export interface PasskeymeSDKPlugin {
  passkeyRegister(options: { challenge: string }): Promise<{ credential: string }>;
  passkeyAuthenticate(options: { challenge: string }): Promise<{ credential: string }>;
}
