package com.jc;

 import android.util.Log;

 import com.getcapacitor.Plugin;
 import com.getcapacitor.PluginCall;
 import com.getcapacitor.PluginMethod;
 import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "PasskeymeIonicCapPlugin")
public class PasskeymeSDKPlugin extends Plugin {
    private static final String TAG = "PasskeymeSDKPlugin";

    private PasskeyManager passkeyManager;

//     @Override
//     public void load() {
//         passkeyManager = new PasskeyManager(getContext());
//     }

     @PluginMethod
     public void passkeyRegister(PluginCall call) {

         if ( passkeyManager == null ) {
             passkeyManager = new PasskeyManager(getContext(), call);
         }

         String challengeJson = call.getString("challenge");

         try {
             passkeyManager.registerPasskey(challengeJson);
         } catch (Exception e) {
             Log.e(TAG, "passkeyme ERROR", e);
             call.reject("An error occurred: " + e.getLocalizedMessage());
         }
     }

     @PluginMethod
     public void passkeyAuthenticate(PluginCall call) {

         Log.i(TAG, "passkeyme: passkeyAuthenticate");

         if ( passkeyManager == null ) {
             passkeyManager = new PasskeyManager(getContext(), call);
         }

         String challengeJson = call.getString("challenge");

         try {
             Log.i(TAG, "passkeyme: doing passkeyManager.authenticatePasskey on " + challengeJson);

             passkeyManager.authenticatePasskey(challengeJson);

             Log.i(TAG, "passkeyme: done passkeyManager.authenticatePasskey");

         } catch (Exception e) {
             Log.e(TAG, "passkeyme: ERROR", e);
             call.reject("An error occurred: " + e.getLocalizedMessage());
         }
     }
}
