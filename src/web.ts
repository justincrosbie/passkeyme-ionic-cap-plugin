import { WebPlugin } from '@capacitor/core';

import type { PasskeymeSDKPlugin } from './definitions';

export class PasskeymeSDKWeb extends WebPlugin implements PasskeymeSDKPlugin {

  async passkeyRegister(options: { challenge: string }): Promise<{ credential: string }> {


    try {

      const challenge = JSON.parse(options.challenge);

      // Need to reconstruct the publicKey to encode the base64 strings as ArrayBuffer
      const publicKeyCredentialCreationOptions: CredentialCreationOptions = {
        publicKey: {
          ...challenge.publicKey,
          challenge: this.base64ToArrayBuffer(challenge.publicKey.challenge),
          user: {
            ...challenge.publicKey.user,
            id: this.base64ToArrayBuffer(challenge.publicKey.user.id),
          },
          excludeCredentials: challenge.publicKey.excludeCredentials.map((excludeCredential: any) => {
            return {
              ...excludeCredential,
              id: this.base64ToArrayBuffer(excludeCredential.id)
            }
          })
        }
      }

      console.log('publicKeyCredentialCreationOptions', publicKeyCredentialCreationOptions);

      const credential = await navigator.credentials.create(publicKeyCredentialCreationOptions);

      // Need to reconstruct the response to encode the ArrayBuffers strings as base64url encoded strings
      const cred: any = credential || {};
      const converted = {
        ...cred,
        id: cred.id,
        type: cred.type,        
        rawId: this.base64UrlEncode(cred.rawId),
        response: {
          ...cred.response,
          clientDataJSON: this.base64UrlEncode(cred.response.clientDataJSON),
          attestationObject: this.base64UrlEncode(cred.response.attestationObject)
        }
      }
      
      if (!credential) {
        throw new Error('Failed to create credentials');
      }

      return {
        credential: JSON.stringify(converted)
      };
    } catch (error: any) {
      throw new Error(`Registration failed: ${error.message || 'An unknown error occurred'}`);
    }
  }

  async passkeyAuthenticate(options: { challenge: string }): Promise<{ credential: string }>{
    
    try {
      const challenge = JSON.parse(options.challenge);

      // Need to reconstruct the publicKey to encode the base64 strings as ArrayBuffer
      const credentialRequestOptions: CredentialRequestOptions = {
        publicKey: {
          ...challenge.publicKey,
          challenge: this.base64ToArrayBuffer(challenge.publicKey.challenge),
          allowCredentials: challenge.publicKey.allowCredentials.map((allowCredential: any) => {
            return {
              ...allowCredential,
              id: this.base64ToArrayBuffer(allowCredential.id)
            }
          })
        }
      };

      const credential = await navigator.credentials.get(credentialRequestOptions);

      // Need to reconstruct the response to encode the ArrayBuffers strings as base64url encoded strings
      const cred: any = credential || {};
      const converted = {
        // ...cred,
        id: cred.id,
        type: cred.type,        
        rawId: this.base64UrlEncode(cred.rawId),
        response: {
          // ...cred.response,
          signature: this.base64UrlEncode(cred.response.signature),
          clientDataJSON: this.base64UrlEncode(cred.response.clientDataJSON),
          authenticatorData: this.base64UrlEncode(cred.response.authenticatorData),
          userHandle: this.base64UrlEncode(cred.response.userHandle)
        },
        authenticatorAttachment: cred.authenticatorAttachment,        
      }
      
      if (!credential) {
        throw new Error('Failed to create credentials');
      }

      return {
        credential: JSON.stringify(converted)
        // Populate additional result fields as needed
      };
    } catch (error: any) {
      throw new Error(`Authentication failed: ${error.message || 'An unknown error occurred'}`);
    }
  }

  // private arrayBufferToBase64(buffer: ArrayBuffer): string {
  //   let binary = '';
  //   const bytes = new Uint8Array(buffer);
  //   const len = bytes.byteLength;
  //   for (let i = 0; i < len; i++) {
  //     binary += String.fromCharCode(bytes[i]);
  //   }

  //   return window.btoa(binary);
  // }

  private base64UrlEncode(arrayBuffer: ArrayBuffer): string {
    // Convert ArrayBuffer to a standard Base64 string
    const byteArray = new Uint8Array(arrayBuffer);
    let binaryString = '';

    for (let i = 0; i < byteArray.length; i++) {
        binaryString += String.fromCharCode(byteArray[i]);
    }

    // Standard Base64 encode
    let base64String = btoa(binaryString);

    // Make it URL-safe by replacing specific characters and removing padding
    return base64String
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
  }
  
  // private unpackClientDataJSON (clientDataJSON: string) {

  //   const decodedClientDataJSON: any = atob(clientDataJSON);
  //   const clientData = JSON.parse(decodedClientDataJSON);

  //   const innerChallenge = clientData.challenge;

  //   const innerChallengeFixed = innerChallenge.replace(/\+/g, '-')
  //   .replace(/\//g, '_')
  //   .replace(/=+$/, '');

  //   const decodedClientDataJSONInnerChallenge: any = atob(innerChallengeFixed);

  //   clientData.challenge = decodedClientDataJSONInnerChallenge;

  //   const clientDataStr = JSON.stringify(clientData);

  //   // base64UrlEncode innerChallenge
  //   const innerChallengeBase64Url = window.btoa(clientDataStr);

  //   return innerChallengeBase64Url;
  // }
  
  // private arrayBufferToHex(buffer: ArrayBuffer): string {
  //   return Array.from(new Uint8Array(buffer), byte => byte.toString(16).padStart(2, '0')).join('');
  // }
  // private arrayBufferToArray(buffer: ArrayBuffer): string[] {
  //   return Array.from(new Uint8Array(buffer), byte => byte.toString(16).padStart(2, '0'));
  // }
  
  // private generateRandomBuffer() {
  //   const buffer = new Uint8Array(32);
  //   window.crypto.getRandomValues(buffer);
  //   return buffer;
  // }

  // private encodeUserHandle(username: string) {
  //   return new TextEncoder().encode(username);
  // }
  // private encodeUserHandleNoUndef(username: string) {
  //   return new TextEncoder().encode(username);
  // }
 
  private base64ToArrayBuffer(base64String: string): ArrayBuffer {
    // Decode Base64 URL-safe characters
    base64String = base64String.replace(/-/g, '+').replace(/_/g, '/');
    const decodedStr = atob(base64String);

    // Convert to ArrayBuffer
    const buffer = new Uint8Array(decodedStr.length);
    for (let i = 0; i < decodedStr.length; i++) {
        buffer[i] = decodedStr.charCodeAt(i);
    }
    return buffer.buffer;
}  


  // // Helper function to convert base64 string to ArrayBuffer
  // base64ToBuffer(base64: string): ArrayBuffer {
  //   const binaryString = atob(base64); // Decode base64
  //   const len = binaryString.length;
  //   const bytes = new Uint8Array(len);
  //   for (let i = 0; i < len; i++) {
  //     bytes[i] = binaryString.charCodeAt(i);
  //   }
  //   return bytes.buffer;
  // }
}

