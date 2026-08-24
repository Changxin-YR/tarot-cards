import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  LocalDataCodec,
  StoredCardNote,
  StoredReadingCollections,
  StoredReadingRecord
} from './LocalDataCodec';
import { TarotThemeId } from '../models/TarotModels';
import { AppDataRepository, StoredAppData } from './AppDataRepository';
import { AppLogger } from '../common/AppLogger';

export class LocalAppStore implements AppDataRepository {
  private store: preferences.Preferences | null = null;
  private ready: Promise<void> | null = null;

  async initialize(context: common.Context): Promise<void> {
    if (this.ready === null) {
      this.ready = this.open(context);
    }
    try {
      await this.ready;
    } catch (error) {
      this.ready = null;
      this.store = null;
      AppLogger.error('LocalAppStore', 'initialize', error);
      throw new Error('Local preferences initialization failed.');
    }
  }

  private async open(context: common.Context): Promise<void> {
    this.store = await preferences.getPreferences(context, 'tarot_inspiration_local_v1');
  }

  async load(): Promise<StoredAppData> {
    if (this.ready !== null) {
      await this.ready;
    }
    if (this.store === null) {
      throw new Error('Local preferences are unavailable.');
    }
    let historyValue: preferences.ValueType = '';
    let favoritesValue: preferences.ValueType = '';
    let notesValue: preferences.ValueType = '';
    let reversalsValue: preferences.ValueType = true;
    let soundValue: preferences.ValueType = true;
    let hapticValue: preferences.ValueType = true;
    let recentValue: preferences.ValueType = true;
    let themeValue: preferences.ValueType = 'moon_garden';
    let recordsValue: preferences.ValueType = '';
    let collectionsValue: preferences.ValueType = '';
    let acceptedTermsVersionValue: preferences.ValueType = '';
    historyValue = await this.store.get('history', '');
    favoritesValue = await this.store.get('favorites', '');
    notesValue = await this.store.get('notes', '');
    reversalsValue = await this.store.get('reversals', true);
    soundValue = await this.store.get('sound', true);
    hapticValue = await this.store.get('haptic', true);
    recentValue = await this.store.get('recentThemes', true);
    themeValue = await this.store.get('themeId', 'moon_garden');
    recordsValue = await this.store.get('readingRecordsV2', '');
    collectionsValue = await this.store.get('readingCollectionsV1', '');
    acceptedTermsVersionValue = await this.store.get('acceptedTermsVersion', '');
    const collectionsText: string = typeof collectionsValue === 'string' ? collectionsValue : '';
    const legacyHistory: string[] = LocalDataCodec.decodeHistory(
      typeof historyValue === 'string' ? historyValue : ''
    );
    const legacyRecords: StoredReadingRecord[] = LocalDataCodec.decodeRecords(
      typeof recordsValue === 'string' ? recordsValue : ''
    );
    const collections: StoredReadingCollections = collectionsText.length > 0 ?
      LocalDataCodec.decodeReadingCollections(collectionsText) :
      { records: legacyRecords, history: legacyHistory };
    return {
      history: collections.history,
      favorites: LocalDataCodec.decodeFavorites(
        typeof favoritesValue === 'string' ? favoritesValue : ''
      ),
      notes: LocalDataCodec.decodeNotes(
        typeof notesValue === 'string' ? notesValue : ''
      ),
      reversalsEnabled: typeof reversalsValue === 'boolean' ? reversalsValue : true,
      soundEnabled: typeof soundValue === 'boolean' ? soundValue : true,
      hapticEnabled: typeof hapticValue === 'boolean' ? hapticValue : true,
      recentThemesEnabled: typeof recentValue === 'boolean' ? recentValue : true,
      themeId: themeValue === 'stained_glass' ? 'stained_glass' : 'moon_garden',
      records: collections.records,
      acceptedTermsVersion: typeof acceptedTermsVersionValue === 'string' ? acceptedTermsVersionValue : ''
    };
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

  async saveTheme(themeId: TarotThemeId): Promise<void> {
    await this.put('themeId', themeId);
  }

  async saveAcceptedTermsVersion(value: string): Promise<void> {
    await this.put('acceptedTermsVersion', value);
  }

  async saveRecordCollections(records: StoredReadingRecord[], history: string[]): Promise<void> {
    if (this.ready !== null) {
      await this.ready;
    }
    if (this.store === null) {
      throw new Error('Local preferences are unavailable.');
    }
    const collections: StoredReadingCollections = { records, history };
    await this.store.put('readingCollectionsV1', LocalDataCodec.encodeReadingCollections(collections));
    await this.store.flush();
  }

  async clearAll(): Promise<void> {
    if (this.ready !== null) {
      await this.ready;
    }
    if (this.store === null) {
      throw new Error('Local preferences are unavailable.');
    }
    await this.store.clear();
    await this.store.flush();
  }

  private async put(key: string, value: preferences.ValueType): Promise<void> {
    if (this.ready !== null) {
      await this.ready;
    }
    if (this.store === null) {
      throw new Error('Local preferences are unavailable.');
    }
    await this.store.put(key, value);
    await this.store.flush();
  }

}
