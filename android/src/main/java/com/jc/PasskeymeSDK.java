package com.jc;

import android.util.Log;

public class PasskeymeSDK {

    public String passkeyRegister(String value) {
        Log.i("Passkey Register", value);
        return value;
    }

    public String passkeyAuthenticate(String value) {
        Log.i("Passkey Authenticate", value);
        return value;
    }
}
