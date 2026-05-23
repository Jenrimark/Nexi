import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'nexi_settings';
const KEY_PRIVACY_ACCEPTED: string = 'privacy_accepted';

export class PrivacyPreferences {
  static async isAccepted(context: Context): Promise<boolean> {
    const store = await preferences.getPreferences(context, STORE_NAME);
    return await store.get(KEY_PRIVACY_ACCEPTED, false) as boolean;
  }

  static async setAccepted(context: Context, accepted: boolean): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME);
    await store.put(KEY_PRIVACY_ACCEPTED, accepted);
    await store.flush();
  }

  /** 仅开发调试用：重置隐私同意状态 */
  static async reset(context: Context): Promise<void> {
    await PrivacyPreferences.setAccepted(context, false);
  }
}
