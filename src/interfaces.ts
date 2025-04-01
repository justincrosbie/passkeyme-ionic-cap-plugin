interface ExcludeCredential {
    type: string;
    id: string;
}

interface User {
    id: string;
    name: string;
    displayName: string;
}

interface RegisterPublicKey {
    rp: PublicKeyCredentialRpEntity;
    user: User;
    challenge: string;
    pubKeyCredParams: PublicKeyCredentialParameters[];
    timeout: number;
    attestation: AttestationConveyancePreference;
    excludeCredentials: ExcludeCredential[];
    authenticatorSelection: AuthenticatorSelectionCriteria;
    extensions: AuthenticationExtensionsClientInputs;
}

export interface RegisterChallenge {
    publicKey: RegisterPublicKey;
}

interface AuthPublicKey {
    challenge: string;
    timeout: number;
    rpId: string;
    allowCredentials: PublicKeyCredentialDescriptor[];
    userVerification: UserVerificationRequirement;
}

export interface AuthChallenge {
    publicKey: AuthPublicKey;
}

