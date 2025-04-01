package com.jc;

import android.content.Context;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.util.Base64;
import android.util.Log;

import androidx.credentials.CreateCredentialRequest;
import androidx.credentials.CreateCredentialResponse;
import androidx.credentials.CreatePublicKeyCredentialResponse;
import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.GetPublicKeyCredentialOption;
import androidx.credentials.PasswordCredential;
import androidx.credentials.exceptions.CreateCredentialCancellationException;
import androidx.credentials.exceptions.CreateCredentialCustomException;
import androidx.credentials.exceptions.CreateCredentialException;
import androidx.credentials.exceptions.CreateCredentialInterruptedException;
import androidx.credentials.exceptions.CreateCredentialProviderConfigurationException;
import androidx.credentials.exceptions.CreateCredentialUnknownException;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.PublicKeyCredential;
import androidx.credentials.CreatePublicKeyCredentialRequest;
import androidx.credentials.exceptions.domerrors.DomError;
import androidx.credentials.exceptions.publickeycredential.CreatePublicKeyCredentialDomException;

import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class PasskeyManager {
    private static final String TAG = "PasskeyManager";
    private final CredentialManager credentialManager;

    private final Executor executor;
    private Context ctx;

    private PluginCall call;

    // Nested class for the parsed publicKey object
    static class RegPublicKeyChallenge {
        Map<String, Object> rp;
        Map<String, Object> user;
        String challenge;

        Set<Map<String, Object>> pubKeyCredParams;

        Integer timeout;

        String attestation;

        Set<Map<String, Object>> excludeCredentials;

        Map<String, Object> authenticatorSelection;
        Map<String, Object> extensions;

    }

    static class RegChallenge {
        RegPublicKeyChallenge publicKey;
    }
    static class AuthPublicKeyChallenge {
        String rpId;
        String challenge;

        Integer timeout;

        String userVerification;

        Set<Map<String, Object>> allowCredentials;

    }
    static class AuthChallenge {
        AuthPublicKeyChallenge publicKey;
    }

    static class RegResponse {
        String clientDataJSON;
        String attestationObject;

    }

    static class RegCredentialResponse {
        String id;
        String rawId;
        String type;

        RegResponse response;
    }

    public PasskeyManager(Context context, PluginCall call) {
        this.ctx = context;
        this.call = call;
        this.executor = Executors.newSingleThreadExecutor();
        this.credentialManager = CredentialManager.create(context);
    }

    public void registerPasskey(String requestJson) {
        Gson gson = new Gson();
        RegChallenge challenge;

        try {
            challenge = gson.fromJson(requestJson, RegChallenge.class);
        } catch (Exception e) {
            Log.e(TAG, "passkeyme: Failed to parse publicKey JSON", e);
            call.reject("Failed to parse publicKey JSON" + e.getLocalizedMessage());
            return;
        }

        challenge.publicKey.authenticatorSelection.put("requireResidentKey", true);
        challenge.publicKey.authenticatorSelection.put("residentKey", "preferred");

        String publicKey = gson.toJson(challenge.publicKey);

        String relyingPartyID = (String) challenge.publicKey.rp.get("id");
        String challengeInner = challenge.publicKey.challenge;
        String userID = (String) challenge.publicKey.user.get("id");

        CreatePublicKeyCredentialRequest createPublicKeyCredentialRequest =
                // `requestJson` contains the request in JSON format. Uses the standard
                // WebAuthn web JSON spec.
                // `preferImmediatelyAvailableCredentials` defines whether you prefer
                // to only use immediately available credentials, not  hybrid credentials,
                // to fulfill this request. This value is false by default.
                new CreatePublicKeyCredentialRequest(publicKey);

        CancellationSignal cancelSignal = new CancellationSignal();

        // Execute CreateCredentialRequest asynchronously to register credentials
        // for a user account. Handle success and failure cases with the result and
        // exceptions, respectively.
        credentialManager.createCredentialAsync(
                // Use an activity-based context to avoid undefined system
                // UI launching behavior
                ctx,
                createPublicKeyCredentialRequest,
                cancelSignal,
                executor,
                new CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException>() {
                    @Override
                    public void onResult(CreateCredentialResponse result) {
                        handleSuccessfulCreatePasskeyResult(result);
                    }

                    @Override
                    public void onError(CreateCredentialException e) {
                        handleAuthError(e);
                    }
                }
        );
    }

    public boolean authenticatePasskey(String requestJson) {
        Gson gson = new Gson();
        AuthChallenge challenge;

        Log.i(TAG, "passkeyme: in authenticatePasskey ");

        try {
            challenge = gson.fromJson(requestJson, AuthChallenge.class);
        } catch (Exception e) {
            Log.e(TAG, "passkeyme: Failed to parse publicKey JSON", e);
            call.reject("Failed to parse publicKey JSON" + e.getLocalizedMessage());
            return false;
        }

        String publicKey = gson.toJson(challenge.publicKey);

        Log.i(TAG, "passkeyme: in authenticatePasskey, publicKey =  " + publicKey);

// Get passkey from the user's public key credential provider.
        GetPublicKeyCredentialOption getPublicKeyCredentialOption =
                new GetPublicKeyCredentialOption(publicKey);

        GetCredentialRequest getCredRequest = new GetCredentialRequest.Builder()
                .addCredentialOption(getPublicKeyCredentialOption)
                .build();

        CancellationSignal cancelSignal = new CancellationSignal();

        Log.i(TAG, "passkeyme: in authenticatePasskey, doing getCredentialAsync");

        credentialManager.getCredentialAsync(
                // Use activity based context to avoid undefined
                // system UI launching behavior
                ctx,
                getCredRequest,
                cancelSignal,
                executor,
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override
                    public void onResult(GetCredentialResponse result) {
                        handleSignIn(result);
                    }

                    @Override
                    public void onError(GetCredentialException e) {
                        handleFailure(e);
                    }
                }
        );

        return true;
    }

    public void handleSignIn(GetCredentialResponse result) {

        Log.i(TAG, "passkeyme: in authenticatePasskey, in handleSignIn");

        // Handle the successfully returned credential.
        Credential credential = result.getCredential();
        if (credential instanceof PublicKeyCredential) {
            String responseJson = ((PublicKeyCredential) credential).getAuthenticationResponseJson();
            // Share responseJson i.e. a GetCredentialResponse on your server to validate and authenticate

            Log.i(TAG, "passkeyme: in handleSignIn, PublicKeyCredential: " + responseJson);

            JSObject ret = new JSObject();
            ret.put("credential", responseJson);
            call.resolve(ret);

            call.resolve(ret);

            Log.i(TAG, "passkeyme: in handleSignIn, exiting");

        } else if (credential instanceof PasswordCredential) {
            String username = ((PasswordCredential) credential).getId();
            String password = ((PasswordCredential) credential).getPassword();
            // Use id and password to send to your server to validate and authenticate
            call.reject("unexpected PasswordCredential credential: " + result);
        } else if (credential instanceof CustomCredential) {
//                if (ExampleCustomCredential.TYPE.equals(credential.getType())) {
//                    try {
//                        ExampleCustomCredential customCred = ExampleCustomCredential.createFrom(customCredential.getData());
//                        // Extract the required credentials and complete the
//                        // authentication as per the federated sign in or any external
//                        // sign in library flow
//                    } catch (ExampleCustomCredential.ExampleCustomCredentialParsingException e) {
//                        // Unlikely to happen. If it does, you likely need to update the
//                        // dependency version of your external sign-in library.
//                        Log.e(TAG, "passkeyme: Failed to parse an ExampleCustomCredential", e);
//                    }
//                } else {
//                    // Catch any unrecognized custom credential type here.
//                    Log.e(TAG, "passkeyme: Unexpected type of credential");
//                }
        } else {
            // Catch any unrecognized credential type here.
            Log.e(TAG, "passkeyme: Unexpected type of credential");
            call.reject("unexpected credential: " + result);
        }
    }

    public void handleFailure(GetCredentialException e) {
        call.reject("Auth Failure: " + e.getLocalizedMessage());
    }

    public void handleSuccessfulCreatePasskeyResult(CreateCredentialResponse result) {

        // Extract data from the response
        try {

            if ( result instanceof CreatePublicKeyCredentialResponse ) {

                String responseJson = ((CreatePublicKeyCredentialResponse) result).getRegistrationResponseJson();

                JSObject ret = new JSObject();
                ret.put("credential", responseJson);
                call.resolve(ret);
            } else {
                call.reject("unexpected credential: " + result);
            }
        } catch (Exception e) {
            call.reject(e.getLocalizedMessage());
        }
    }

    public void handlePasskeyError(DomError e) {
        call.reject("Registration Dom Failure: " + e.toString());
    }

    public void handleAuthError(Exception e) {
        if (e instanceof CreatePublicKeyCredentialDomException) {
            // Handle the passkey DOM errors thrown according to the
            // WebAuthn spec.

            // androidx.credentials.exceptions.publickeycredential.CreatePublicKeyCredentialDomException: One of the excluded credentials exists on the local device
            // errorMessage: One of the excluded credentials exists on the local device
            // type: androidx.credentials.TYPE_CREATE_PUBLIC_KEY_CREDENTIAL_DOM_EXCEPTION/androidx.credentials.TYPE_INVALID_STATE_ERROR

            handlePasskeyError(((CreatePublicKeyCredentialDomException)e).getDomError());
        } else if (e instanceof CreateCredentialCancellationException) {
            // The user intentionally canceled the operation and chose not
            // to register the credential.
            call.reject("Registration Cancelled: " + e.getLocalizedMessage());
        } else if (e instanceof CreateCredentialInterruptedException) {
            // Retry-able error. Consider retrying the call.
            call.reject("Registration Interrupted: " + e.getLocalizedMessage());
        } else if (e instanceof CreateCredentialProviderConfigurationException) {
            // Your app is missing the provider configuration dependency.
            // Most likely, you're missing the
            // "credentials-play-services-auth" module.
            call.reject("Registration Provider Config Error: " + e.getLocalizedMessage());
        } else if (e instanceof CreateCredentialUnknownException) {
            call.reject("Registration Unknown Error: " + e.getLocalizedMessage());
        } else if (e instanceof CreateCredentialCustomException) {
            // You have encountered an error from a 3rd-party SDK. If
            // you make the API call with a request object that's a
            // subclass of
            // CreateCustomCredentialRequest using a 3rd-party SDK,
            // then you should check for any custom exception type
            // constants within that SDK to match with e.type.
            // Otherwise, drop or log the exception.
            call.reject("Registration Custom Error: " + e.getLocalizedMessage());
        } else {
            Log.w(TAG, "passkeyme: Unexpected exception type "
                    + e.getClass().getName());
            call.reject("Unexpected exception type: " + e.getClass().getName() + ": " + e.getLocalizedMessage());
        }

    }
}
