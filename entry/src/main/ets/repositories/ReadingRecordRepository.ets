import { StoredReadingRecord } from './LocalDataCodec';

export interface ReadingRecordRepository {
  saveRecordCollections(records: StoredReadingRecord[], history: string[]): Promise<void>;
  clearAll(): Promise<void>;
}
