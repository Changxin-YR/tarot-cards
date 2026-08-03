import { common } from '@kit.AbilityKit';
import { TarotThemeId } from '../models/TarotModels';
import { AppDataRepository, StoredAppData } from '../repositories/AppDataRepository';
import { StoredCardNote, StoredReadingRecord } from '../repositories/LocalDataCodec';
import { ReadingCollections, ReadingRecordService } from './ReadingRecordService';
import { ComplianceService } from './ComplianceService';
import { AppLogger } from '../common/AppLogger';

export class AppDataService {
  private readonly repository: AppDataRepository;
  private readonly readingRecords: ReadingRecordService;
  private queue: Promise<void> = Promise.resolve();

  constructor(repository: AppDataRepository) {
    this.repository = repository;
    this.readingRecords = new ReadingRecordService(repository);
  }

  async initialize(context: common.Context): Promise<StoredAppData> {
    await this.repository.initialize(context);
    const data: StoredAppData = await this.repository.load();
    this.readingRecords.setSnapshot({ records: data.records, history: data.history });
    return data;
  }

  async upsertRecord(record: StoredReadingRecord): Promise<ReadingCollections> {
    return this.enqueue((): Promise<ReadingCollections> => this.readingRecords.upsert(record));
  }

  async removeRecord(recordId: string): Promise<ReadingCollections> {
    return this.enqueue((): Promise<ReadingCollections> => this.readingRecords.remove(recordId));
  }

  async removeLegacyRecord(index: number): Promise<ReadingCollections> {
    return this.enqueue((): Promise<ReadingCollections> => this.readingRecords.removeLegacy(index));
  }

  async clearRecords(): Promise<ReadingCollections> {
    return this.enqueue((): Promise<ReadingCollections> => this.readingRecords.clear());
  }

  async toggleFavorite(favorites: string[], cardId: string): Promise<string[]> {
    return this.enqueue(async (): Promise<string[]> => {
      const next: string[] = favorites.includes(cardId) ?
        favorites.filter((item: string): boolean => item !== cardId) :
        favorites.concat([cardId]);
      await this.repository.saveFavorites(next);
      return next;
    });
  }

  async saveCardNote(
    notes: StoredCardNote[],
    cardId: string,
    content: string
  ): Promise<StoredCardNote[]> {
    return this.enqueue(async (): Promise<StoredCardNote[]> => {
      const next: StoredCardNote[] = notes.filter(
        (item: StoredCardNote): boolean => item.cardId !== cardId
      );
      if (content.trim().length > 0) {
        next.push({ cardId, content: content.trim() });
      }
      await this.repository.saveNotes(next);
      return next;
    });
  }

  async saveBoolean(key: string, value: boolean): Promise<boolean> {
    return this.enqueue(async (): Promise<boolean> => {
      await this.repository.saveBoolean(key, value);
      return value;
    });
  }

  async saveTheme(themeId: TarotThemeId): Promise<TarotThemeId> {
    return this.enqueue(async (): Promise<TarotThemeId> => {
      await this.repository.saveTheme(themeId);
      return themeId;
    });
  }

  async acceptCurrentTerms(): Promise<string> {
    return this.enqueue(async (): Promise<string> => {
      const version: string = ComplianceService.CURRENT_VERSION;
      await this.repository.saveAcceptedTermsVersion(version);
      return version;
    });
  }

  async clearAll(): Promise<void> {
    return this.enqueue(async (): Promise<void> => {
      await this.readingRecords.clearAllData();
    });
  }

  private enqueue<T>(action: () => Promise<T>): Promise<T> {
    const operation: Promise<T> = this.queue.then(action);
    this.queue = operation.then(
      (): void => {
      },
      (error: Error): void => {
        AppLogger.error('AppDataService', 'queuedOperation', error);
      }
    );
    return operation;
  }
}
