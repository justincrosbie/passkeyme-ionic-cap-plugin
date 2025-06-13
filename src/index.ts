import { registerPlugin } from '@capacitor/core';

import type { PasskeymeSDKPlugin } from './definitions';

const PasskeymeSDK = registerPlugin<PasskeymeSDKPlugin>('PasskeymeIonicCapPlugin', {
  web: () => import('./web').then(m => new m.PasskeymeSDKWeb()),
});

export * from './definitions';
export { PasskeymeSDK };
