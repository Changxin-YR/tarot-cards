import { describe, expect, it } from '@ohos/hypium';
import { StoredReadingRecord } from '../../../main/ets/repositories/LocalDataCodec';
import {
  ReadingCollections,
  ReadingRecordService
} from '../../../main/ets/services/ReadingRecordService';
import { ReadingRecordRepository } from '../../../main/ets/repositories/ReadingRecordRepository';

class MemoryReadingRecordRepository implements ReadingRecordRepository {
  saveCollectionsCalls: number = 0;
  shouldFail: boolean = false;
  failNextSaveCount: number = 0;
  savedCollections: ReadingCollections[] = [];

  async saveRecordCollections(
    records: StoredReadingRecord[],
    history: string[]
  ): Promise<void> {
    this.saveCollectionsCalls += 1;
    if (this.shouldFail || this.failNextSaveCount > 0) {
      if (this.failNextSaveCount > 0) {
        this.failNextSaveCount -= 1;
      }
      throw new Error('write failed');
    }
    this.savedCollections.push({ records: records.slice(), history: history.slice() });
  }

  async clearAll(): Promise<void> {
    if (this.shouldFail) {
      throw new Error('write failed');
    }
  }
}

function sampleRecord(id: string): StoredReadingRecord {
  return {
    schemaVersion: 3,
    id,
    createdAt: 1785480000000,
    question: '我应该关注什么？',
    mood: '',
    scene: 'growth',
    depth: 'concise',
    spreadType: 'single',
    themeId: 'stained_glass',
    cards: [{ cardId: 'major-00', orientation: 'upright', position: '核心指引' }],
    clarifications: [],
    result: {
      summary: '先看清此刻。',
      sections: [],
      action: '完成一步。',
      reflection: '什么最重要？',
      algorithmVersion: 2
    },
    note: '',
    favorite: false
  };
}

export default function readingRecordServiceTest(): void {
  describe('ReadingRecordService', () => {
    it('persistsCreatedRecordBeforeReturningNewCollection', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      service.setSnapshot({ records: [sampleRecord('old')], history: ['旧记录'] });
      const created: ReadingCollections = await service.upsert(sampleRecord('new'));

      expect(created.records.length).assertEqual(2);
      expect(created.records[0].id).assertEqual('new');
      expect(created.history[0]).assertEqual('旧记录');
      expect(repository.saveCollectionsCalls).assertEqual(1);
    });

    it('persistsOnlyRecordsRemainingAfterDeletion', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      service.setSnapshot({ records: [sampleRecord('one'), sampleRecord('two')], history: [] });
      const remaining: ReadingCollections = await service.remove('one');

      expect(remaining.records.length).assertEqual(1);
      expect(remaining.records[0].id).assertEqual('two');
      expect(repository.saveCollectionsCalls).assertEqual(1);
    });

    it('clearsStructuredAndLegacyRecordsWithOneRepositoryOperation', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      const cleared: ReadingCollections = await service.clear();

      expect(cleared.records.length).assertEqual(0);
      expect(cleared.history.length).assertEqual(0);
      expect(repository.saveCollectionsCalls).assertEqual(1);
    });

    it('persistsLegacyHistoryAfterSingleDeletion', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      service.setSnapshot({ records: [], history: ['第一条', '第二条'] });
      const remaining: ReadingCollections = await service.removeLegacy(0);

      expect(remaining.history.length).assertEqual(1);
      expect(remaining.history[0]).assertEqual('第二条');
      expect(repository.saveCollectionsCalls).assertEqual(1);
    });

    it('rejectsFailedWritesWithoutReturningOptimisticState', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      repository.shouldFail = true;
      const service: ReadingRecordService = new ReadingRecordService(repository);
      let rejected: boolean = false;

      try {
        await service.upsert(sampleRecord('new'));
      } catch {
        rejected = true;
      }

      expect(rejected).assertTrue();
      expect(service.snapshot().records.length).assertEqual(0);
    });

    it('serializesConcurrentWritesAgainstLatestSnapshot', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      const first: Promise<ReadingCollections> = service.upsert(sampleRecord('first'));
      const second: Promise<ReadingCollections> = service.upsert(sampleRecord('second'));

      await first;
      const latest: ReadingCollections = await second;

      expect(latest.records.length).assertEqual(2);
      expect(latest.records[0].id).assertEqual('second');
      expect(latest.records[1].id).assertEqual('first');
      expect(repository.savedCollections[1].records.length).assertEqual(2);
    });

    it('updatesExistingSavedRecordInsteadOfDuplicatingIt', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      const service: ReadingRecordService = new ReadingRecordService(repository);
      service.setSnapshot({ records: [sampleRecord('same')], history: [] });
      const updated: StoredReadingRecord = sampleRecord('same');
      updated.clarifications = [{ cardId: 'cups-02', orientation: 'upright', position: '澄清 1' }];

      const latest: ReadingCollections = await service.upsert(updated);

      expect(latest.records.length).assertEqual(1);
      expect(latest.records[0].clarifications.length).assertEqual(1);
    });

    it('continuesQueueFromLastCommittedSnapshotAfterEarlierWriteFails', 0, async () => {
      const repository: MemoryReadingRecordRepository = new MemoryReadingRecordRepository();
      repository.failNextSaveCount = 1;
      const service: ReadingRecordService = new ReadingRecordService(repository);
      const first: Promise<ReadingCollections> = service.upsert(sampleRecord('failed'));
      const second: Promise<ReadingCollections> = service.upsert(sampleRecord('committed'));
      let firstRejected: boolean = false;

      try {
        await first;
      } catch {
        firstRejected = true;
      }
      const latest: ReadingCollections = await second;

      expect(firstRejected).assertTrue();
      expect(latest.records.length).assertEqual(1);
      expect(latest.records[0].id).assertEqual('committed');
      expect(repository.savedCollections.length).assertEqual(1);
      expect(repository.savedCollections[0].records[0].id).assertEqual('committed');
    });
  });
}
