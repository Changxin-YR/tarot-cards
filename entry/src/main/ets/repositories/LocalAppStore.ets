import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { LocalDataCodec, StoredCardNote } from './LocalDataCodec';

export interface StoredAppData {
  history: string[];
  favorites: string[];
  notes: StoredCardNote[];
  reversalsEnabled: boolean;
  soundEnabled: boolean;
  hapticEnabled: boolean;
  recentThemesEnabled: boolean;
}

export class LocalAppStore {
  private store: preferences.Preferences | null = null;

  async initialize(context: common.Context): Promise<void> {
    try {
      this.store = await preferences.getPreferences(context, 'tarot_inspiration_local_v1');
    } catch {
      this.store = null;
    }
  }

  async load(): Promise<StoredAppData> {
    if (this.store === null) {
      return this.defaults();
    }
    let historyValue: preferences.ValueType = '';
    let favoritesValue: preferences.ValueType = '';
    let notesValue: preferences.ValueType = '';
    let reversalsValue: preferences.ValueType = true;
    let soundValue: preferences.ValueType = true;
    let hapticValue: preferences.ValueType = true;
    let recentValue: preferences.ValueType = true;
    try {
      historyValue = await this.store.get('history', '');
      favoritesValue = await this.store.get('favorites', '');
      notesValue = await this.store.get('notes', '');
      reversalsValue = await this.store.get('reversals', true);
      soundValue = await this.store.get('sound', true);
      hapticValue = await this.store.get('haptic', true);
      recentValue = await this.store.get('recentThemes', true);
    } catch {
      return this.defaults();
    }
    return {
      history: LocalDataCodec.decodeHistory(
        typeof historyValue === 'string' ? historyValue : ''
      ),
      favorites: LocalDataCodec.decodeFavorites(
        typeof favoritesValue === 'string' ? favoritesValue : ''
      ),
      notes: LocalDataCodec.decodeNotes(
        typeof notesValue === 'string' ? notesValue : ''
      ),
      reversalsEnabled: typeof reversalsValue === 'boolean' ? reversalsValue : true,
      soundEnabled: typeof soundValue === 'boolean' ? soundValue : true,
      hapticEnabled: typeof hapticValue === 'boolean' ? hapticValue : true,
      recentThemesEnabled: typeof recentValue === 'boolean' ? recentValue : true
    };
  }

  async saveHistory(history: string[]): Promise<void> {
    await this.put('history', LocalDataCodec.encodeHistory(history));
  }

  async saveFavorites(cardIds: string[]): Promise<void> {
    await this.put('favorites', LocalDataCodec.encodeFavorites(cardIds));
  }

  async saveNotes(notes: StoredCardNote[]): Promise<void> {
    await this.put('notes', LocalDataCodec.encodeNotes(notes));
  }

  async saveBoolean(key: string, value: boolean): Promise<void> {
    await this.put(key, value);
  }

  private async put(key: string, value: preferences.ValueType): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.put(key, value);
      await this.store.flush();
    } catch {
    }
  }

  private defaults(): StoredAppData {
    return {
      history: [],
      favorites: [],
      notes: [],
      reversalsEnabled: true,
      soundEnabled: true,
      hapticEnabled: true,
      recentThemesEnabled: true
    };
  }
}
