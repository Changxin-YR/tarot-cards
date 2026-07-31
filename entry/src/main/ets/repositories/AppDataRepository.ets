import { common } from '@kit.AbilityKit';
import { TarotThemeId } from '../models/TarotModels';
import { StoredCardNote, StoredReadingRecord } from './LocalDataCodec';
import { ReadingRecordRepository } from './ReadingRecordRepository';

export interface StoredAppData {
  history: string[];
  favorites: string[];
  notes: StoredCardNote[];
  reversalsEnabled: boolean;
  soundEnabled: boolean;
  hapticEnabled: boolean;
  recentThemesEnabled: boolean;
  themeId: TarotThemeId;
  records: StoredReadingRecord[];
}

export interface AppDataRepository extends ReadingRecordRepository {
  initialize(context: common.Context): Promise<void>;
  load(): Promise<StoredAppData>;
  saveFavorites(cardIds: string[]): Promise<void>;
  saveNotes(notes: StoredCardNote[]): Promise<void>;
  saveBoolean(key: string, value: boolean): Promise<void>;
  saveTheme(themeId: TarotThemeId): Promise<void>;
}
