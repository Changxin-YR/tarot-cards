import { StoredReadingRecord } from '../repositories/LocalDataCodec';
import { ReadingRecordRepository } from '../repositories/ReadingRecordRepository';

export interface ReadingCollections {
  records: StoredReadingRecord[];
  history: string[];
}

export class ReadingRecordService {
  private readonly repository: ReadingRecordRepository;
  private current: ReadingCollections = { records: [], history: [] };
  private queue: Promise<void> = Promise.resolve();

  constructor(repository: ReadingRecordRepository) {
    this.repository = repository;
  }

  setSnapshot(collections: ReadingCollections): void {
    this.current = {
      records: collections.records.slice(),
      history: collections.history.slice()
    };
  }

  snapshot(): ReadingCollections {
    return {
      records: this.current.records.slice(),
      history: this.current.history.slice()
    };
  }

  async upsert(record: StoredReadingRecord): Promise<ReadingCollections> {
    return this.enqueue((current: ReadingCollections): ReadingCollections => {
      const remaining: StoredReadingRecord[] = current.records.filter(
        (item: StoredReadingRecord): boolean => item.id !== record.id
      );
      return { records: [record].concat(remaining), history: current.history.slice() };
    });
  }

  async remove(recordId: string): Promise<ReadingCollections> {
    return this.enqueue((current: ReadingCollections): ReadingCollections => ({
      records: current.records.filter(
        (record: StoredReadingRecord): boolean => record.id !== recordId
      ),
      history: current.history.slice()
    }));
  }

  async clear(): Promise<ReadingCollections> {
    return this.enqueue((_current: ReadingCollections): ReadingCollections => ({ records: [], history: [] }));
  }

  async removeLegacy(index: number): Promise<ReadingCollections> {
    return this.enqueue((current: ReadingCollections): ReadingCollections => ({
      records: current.records.slice(),
      history: current.history.filter(
        (_item: string, itemIndex: number): boolean => itemIndex !== index
      )
    }));
  }

  async clearAllData(): Promise<ReadingCollections> {
    return this.enqueueOperation(async (_current: ReadingCollections): Promise<ReadingCollections> => {
      await this.repository.clearAll();
      return { records: [], history: [] };
    });
  }

  private enqueue(
    transform: (current: ReadingCollections) => ReadingCollections
  ): Promise<ReadingCollections> {
    return this.enqueueOperation(async (current: ReadingCollections): Promise<ReadingCollections> => {
      const next: ReadingCollections = transform(current);
      await this.repository.saveRecordCollections(next.records, next.history);
      return next;
    });
  }

  private enqueueOperation(
    action: (current: ReadingCollections) => Promise<ReadingCollections>
  ): Promise<ReadingCollections> {
    const operation: Promise<ReadingCollections> = this.queue.then(async (): Promise<ReadingCollections> => {
      const next: ReadingCollections = await action(this.current);
      this.current = next;
      return this.snapshot();
    });
    this.queue = operation.then(
      (): void => {
      },
      (): void => {
      }
    );
    return operation;
  }
}
