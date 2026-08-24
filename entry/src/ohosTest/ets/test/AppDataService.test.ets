import { common } from '@kit.AbilityKit';
import { describe, expect, it } from '@ohos/hypium';
import { TarotThemeId } from '../../../main/ets/models/TarotModels';
import { AppDataRepository, StoredAppData } from '../../../main/ets/repositories/AppDataRepository';
import { StoredCardNote, StoredReadingRecord } from '../../../main/ets/repositories/LocalDataCodec';
import { AppDataService } from '../../../main/ets/services/AppDataService';
import { ReadingCollections } from '../../../main/ets/services/ReadingRecordService';

class MemoryAppDataRepository implements AppDataRepository {
  shouldFail: boolean = false;
  savedFavorites: string[] = [];
  operations: string[] = [];
  holdFavoriteWrite: boolean = false;
  favoriteRelease: (() => void) | null = null;
  savedAcceptedTermsVersion: string = '';

  async initialize(_context: common.Context): Promise<void> {
  }

  async load(): Promise<StoredAppData> {
    return {
      history: [], favorites: [], notes: [], records: [],
      reversalsEnabled: true, soundEnabled: true, hapticEnabled: true,
      recentThemesEnabled: true, themeId: 'moon_garden', acceptedTermsVersion: ''
    };
  }

  async saveFavorites(cardIds: string[]): Promise<void> {
    if (this.holdFavoriteWrite) {
      await new Promise<void>((resolve: () => void): void => {
        this.favoriteRelease = (): void => resolve();
      });
    }
    if (this.shouldFail) {
      throw new Error('write failed');
    }
    this.savedFavorites = cardIds.slice();
    this.operations.push('save-favorites');
  }

  async saveNotes(_notes: StoredCardNote[]): Promise<void> {
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }

  async saveBoolean(_key: string, _value: boolean): Promise<void> {
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }

  async saveTheme(_themeId: TarotThemeId): Promise<void> {
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }

  async saveAcceptedTermsVersion(value: string): Promise<void> {
    if (this.shouldFail) {
      throw new Error('write failed');
    }
    this.savedAcceptedTermsVersion = value;
  }

  async saveRecordCollections(
    _records: StoredReadingRecord[],
    _history: string[]
  ): Promise<void> {
    this.operations.push('save-records');
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }

  async clearAll(): Promise<void> {
    this.operations.push('clear-all');
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }
}

export default function appDataServiceTest(): void {
  describe('AppDataService', () => {
    it('returnsFavoriteStateOnlyAfterPersistenceSucceeds', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      const service: AppDataService = new AppDataService(repository);
      const favorites: string[] = await service.toggleFavorite([], 'major-00');

      expect(favorites.length).assertEqual(1);
      expect(repository.savedFavorites[0]).assertEqual('major-00');
    });

    it('rejectsFavoriteUpdateWhenPersistenceFails', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      repository.shouldFail = true;
      const service: AppDataService = new AppDataService(repository);
      let rejected: boolean = false;

      try {
        await service.toggleFavorite([], 'major-00');
      } catch {
        rejected = true;
      }

      expect(rejected).assertTrue();
    });

    it('returnsUpdatedNotesOnlyAfterPersistenceSucceeds', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      const service: AppDataService = new AppDataService(repository);
      const notes: StoredCardNote[] = await service.saveCardNote([], 'major-00', '新的理解');

      expect(notes.length).assertEqual(1);
      expect(notes[0].content).assertEqual('新的理解');
    });

    it('waitsForQueuedRecordWritesBeforeClearingAllLocalData', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      const service: AppDataService = new AppDataService(repository);
      const record: StoredReadingRecord = {
        schemaVersion: 3,
        id: 'queued',
        createdAt: 1785480000000,
        question: '',
        mood: '',
        scene: 'growth',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-00', orientation: 'upright', position: '核心指引' }],
        clarifications: [],
        result: {
          summary: '摘要', sections: [], action: '', reflection: '', algorithmVersion: 1
        },
        note: '',
        favorite: false
      };

      const save: Promise<ReadingCollections> = service.upsertRecord(record);
      await service.clearAll();
      await save;

      expect(repository.operations.length).assertEqual(2);
      expect(repository.operations[0]).assertEqual('save-records');
      expect(repository.operations[1]).assertEqual('clear-all');
    });

    it('waitsForInFlightAppDataWritesBeforeClearingAllLocalData', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      repository.holdFavoriteWrite = true;
      const service: AppDataService = new AppDataService(repository);
      const favorite: Promise<string[]> = service.toggleFavorite([], 'major-00');
      const clear: Promise<void> = service.clearAll();

      await Promise.resolve();
      repository.favoriteRelease?.();
      await favorite;
      await clear;

      expect(repository.operations.length).assertEqual(2);
      expect(repository.operations[0]).assertEqual('save-favorites');
      expect(repository.operations[1]).assertEqual('clear-all');
    });

    it('returnsCurrentTermsVersionOnlyAfterPersistenceSucceeds', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      const service: AppDataService = new AppDataService(repository);

      const version: string = await service.acceptCurrentTerms();

      expect(version).assertEqual('2026-08-03-v1');
      expect(repository.savedAcceptedTermsVersion).assertEqual(version);
    });

    it('rejectsTermsAcceptanceWhenPersistenceFails', 0, async () => {
      const repository: MemoryAppDataRepository = new MemoryAppDataRepository();
      repository.shouldFail = true;
      const service: AppDataService = new AppDataService(repository);
      let rejected: boolean = false;

      try {
        await service.acceptCurrentTerms();
      } catch {
        rejected = true;
      }

      expect(rejected).assertTrue();
      expect(repository.savedAcceptedTermsVersion).assertEqual('');
    });
  });
}
