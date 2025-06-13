![alt text](https://passkeyme.com/docs/img/passkeyme-logo-removebg-preview.png)

# passkeyme-ionic-cap-plugin

Passkeyme for Ionic Apps

## Install

```bash
npm install passkeyme-ionic-cap-plugin
npx cap sync
```

## API

<docgen-index>

* [`passkeyRegister(...)`](#passkeyregister)
* [`passkeyAuthenticate(...)`](#passkeyauthenticate)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### passkeyRegister(...)

```typescript
passkeyRegister(options: { challenge: string; }) => Promise<{ credential: string; }>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ challenge: string; }</code> |

**Returns:** <code>Promise&lt;{ credential: string; }&gt;</code>

--------------------


### passkeyAuthenticate(...)

```typescript
passkeyAuthenticate(options: { challenge: string; }) => Promise<{ credential: string; }>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ challenge: string; }</code> |

**Returns:** <code>Promise&lt;{ credential: string; }&gt;</code>

--------------------

</docgen-api>


## Example

Here is a full working example. 

To get it working, first, go to [Passkeyme](https://passkeyme.com), register, create an app and grab the AppID and API Key, and populate in your env as:
```
VITE_APP_UUID=
VITE_API_KEY=
```
Then, create the app:
```
npx create-react-app passkeyme-react-demo
npm install passkeyme-web-sdk axios styled-components
npm start
```

You'll need to run it behind an addressible domain for Passkeys to work. You can host it, or use ngrok to serve it.

```
import { IonButton, IonButtons, IonCard, IonCardContent, IonCardHeader, IonCardSubtitle, IonCardTitle, IonContent, IonHeader, IonInput, IonItem, IonList, IonMenuButton, IonPage, IonTitle, IonToolbar } from '@ionic/react';
import { useParams } from 'react-router';
import ExploreContainer from '../components/ExploreContainer';
import { PasskeymeSDK } from 'passkeyme-ionic-cap-plugin';

import axios from "axios";
import { useState } from 'react';

const API_URL = "https://passkeyme.com";
const APP_UUID = import.meta.env.VITE_APP_UUID;
const API_KEY = import.meta.env.VITE_API_KEY;

const client = axios.create({
   baseURL: `${API_URL}/webauthn/${APP_UUID}`, 
   headers: {
     'x-api-key': API_KEY,
     'Content-Type': 'application/json'
   }});

const Page: React.FC = () => {

  const [result, setResult] = useState<any>("");
  const [username, setUsername] = useState<any>("");
  const [displayName, setDisplayName] = useState<any>("");

  const appuuid = APP_UUID;
  const apikey = API_KEY;

  async function registerPasskey() {
    try {

      const response = await client.post(`/start_registration`, {username, displayName});

      const { credential } = await PasskeymeSDK.passkeyRegister({ challenge: response.data.challenge });

      let completionresponse = await client.post(`/complete_registration`, { username, credential });

      setResult(JSON.stringify(completionresponse.data));
    } catch (error) {
      console.log('passkeyme: reg: error:', JSON.stringify(error))
      setResult(JSON.stringify(error));
    }
  };

  async function authenticatePasskey() {
    try {

      let response = await client.post(`/start_authentication`, { username });

      const { credential } = await PasskeymeSDK.passkeyAuthenticate({ challenge: response.data.challenge });

      let completionresponse = await client.post(`/complete_authentication`, { credential });

      setResult(JSON.stringify(completionresponse.data));

    } catch (error) {
      console.log('passkeyme: error:', JSON.stringify(error))
      setResult(JSON.stringify(error));
    }
  }

  const { name } = useParams<{ name: string; }>();

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start">
            <IonMenuButton />
          </IonButtons>
          <IonTitle>{name}</IonTitle>
        </IonToolbar>
      </IonHeader>

      <IonContent fullscreen>
        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">{name}</IonTitle>
          </IonToolbar>
        </IonHeader>
        <ExploreContainer name={name} />
        <IonCard>
          <IonCardHeader>
            <IonCardTitle>
            <IonList>
              <IonItem>
                <IonInput label="username" placeholder="Enter a username" value={username}
                  onIonChange={(e: any) => setUsername(e.target.value)}               
                  ></IonInput>
              </IonItem>

              <IonItem>
                <IonInput label="displayName" placeholder="Enter a display name" value={displayName}
                onIonChange={(e: any) => setDisplayName(e.target.value)}
                ></IonInput>
              </IonItem>
            </IonList>
                
            <IonButton 
                onClick={() => {
                  registerPasskey()
                }}
            >Register Passkey
            </IonButton>
            <IonButton 
                onClick={() => {
                  authenticatePasskey()
                }}
            >Login Passkey
            </IonButton>

            </IonCardTitle>
          </IonCardHeader>

          <IonCardContent>{result}</IonCardContent>
        </IonCard>

      </IonContent>
    </IonPage>
  );
};

export default Page;
```
