import { describe, expect, it } from '@ohos/hypium';
import {
  LocalDataCodec,
  StoredCardNote,
  StoredReadingCollections,
  StoredReadingRecord
} from '../../../main/ets/repositories/LocalDataCodec';

export default function localDataCodecTest(): void {
  describe('LocalDataCodec', () => {
    it('roundTripsHistoryWithoutJsonAny', 0, () => {
      const encoded: string = LocalDataCodec.encodeHistory(['单牌 · 星星', '三牌阵 · 愚者']);
      const decoded: string[] = LocalDataCodec.decodeHistory(encoded);

      expect(decoded.length).assertEqual(2);
      expect(decoded[1]).assertEqual('三牌阵 · 愚者');
    });

    it('ignoresEmptyHistorySegments', 0, () => {
      expect(LocalDataCodec.decodeHistory('记录一\u001F\u001F').length).assertEqual(1);
    });

    it('roundTripsFavorites', 0, () => {
      const encoded: string = LocalDataCodec.encodeFavorites(['major-00', 'cups-02']);
      const decoded: string[] = LocalDataCodec.decodeFavorites(encoded);

      expect(decoded.length).assertEqual(2);
      expect(decoded[0]).assertEqual('major-00');
    });

    it('roundTripsCardNotes', 0, () => {
      const encoded: string = LocalDataCodec.encodeNotes([
        { cardId: 'major-00', content: '允许自己开始。' },
        { cardId: 'cups-02', content: '先听见彼此。' }
      ]);
      const decoded: StoredCardNote[] = LocalDataCodec.decodeNotes(encoded);

      expect(decoded.length).assertEqual(2);
      expect(decoded[1].cardId).assertEqual('cups-02');
      expect(decoded[1].content).assertEqual('先听见彼此。');
    });

    it('roundTripsStructuredReadingRecords', 0, () => {
      const records: StoredReadingRecord[] = [{
        schemaVersion: 4,
        id: 'reading-1',
        createdAt: 1785480000000,
        question: '我应该关注什么？',
        mood: '期待',
        scene: 'relationship',
        depth: 'deep',
        spreadType: 'relationship',
        themeId: 'stained_glass',
        cards: [{ cardId: 'major-01', orientation: 'reversed', position: '关系核心' }],
        clarifications: [{ cardId: 'cups-02', orientation: 'upright', position: '澄清 1' }],
        result: {
          summary: '先看见彼此真实的需要。',
          sections: [{
            cardId: 'major-01',
            cardName: '魔术师',
            orientation: 'reversed',
            position: '关系核心',
            keywords: ['迟疑', '分散'],
            meaning: '先收回分散的注意力。'
          }],
          connection: '把需要和行动重新连接。',
          action: '先确认一个共同目标。',
          reflection: '什么值得被坦率表达？',
          clarificationReadings: [{
            cardId: 'cups-02',
            cardName: '圣杯二',
            orientation: 'upright',
            index: 1,
            focus: '澄清关系核心中的真实需要。',
            meaning: '圣杯二提示互相倾听与连接。',
            impactType: 'reinforce',
            impact: '这张牌强化了原解读中的沟通主题。',
            action: '确认一次平等对话的时间。'
          }],
          safetyNotice: '只作为自我反思。',
          algorithmVersion: 3
        },
        note: '稍后再看。',
        favorite: true
      }];

      const decoded: StoredReadingRecord[] = LocalDataCodec.decodeRecords(
        LocalDataCodec.encodeRecords(records)
      );

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].themeId).assertEqual('stained_glass');
      expect(decoded[0].depth).assertEqual('deep');
      expect(decoded[0].cards[0].position).assertEqual('关系核心');
      expect(decoded[0].clarifications[0].position).assertEqual('澄清 1');
      expect(decoded[0].result.summary).assertEqual('先看见彼此真实的需要。');
      expect(decoded[0].result.sections[0].keywords[1]).assertEqual('分散');
      expect(decoded[0].result.action).assertEqual('先确认一个共同目标。');
      expect((decoded[0].result.clarificationReadings ?? []).length).assertEqual(1);
      expect(decoded[0].result.clarificationReadings?.[0].focus).assertEqual(
        '澄清关系核心中的真实需要。'
      );
      expect(decoded[0].result.clarificationReadings?.[0].impactType).assertEqual('reinforce');
      expect(decoded[0].schemaVersion).assertEqual(4);
      expect(decoded[0].note).assertEqual('稍后再看。');
      expect(decoded[0].favorite).assertTrue();
      expect(decoded[0].mood).assertEqual('期待');
    });

    it('encodesStructuredRecordsWithoutAsciiControlCharacters', 0, () => {
      const encoded: string = LocalDataCodec.encodeRecords([{
        schemaVersion: 3,
        id: 'reading-2',
        createdAt: 1785480000000,
        question: '下一步是什么？',
        mood: '',
        scene: 'growth',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-00', orientation: 'upright', position: '核心指引' }],
        clarifications: [],
        result: {
          summary: '先完成眼前的一步。',
          sections: [],
          action: '完成一步。',
          reflection: '什么最重要？',
          algorithmVersion: 2
        },
        note: '',
        favorite: false
      }]);
      let hasControlCharacter: boolean = false;
      for (let index: number = 0; index < encoded.length; index += 1) {
        if (encoded.charCodeAt(index) < 32) {
          hasControlCharacter = true;
        }
      }

      expect(hasControlCharacter).assertFalse();
      expect(encoded.startsWith('TR4:')).assertTrue();
    });

    it('continuesToDecodeVersion3RecordsWithoutStructuredClarifications', 0, () => {
      const encoded: string = LocalDataCodec.encodeRecords([{
        schemaVersion: 4,
        id: 'v3-compatibility',
        createdAt: 1785480000000,
        question: '旧记录还能打开吗？',
        mood: '',
        scene: 'growth',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-00', orientation: 'upright', position: '核心指引' }],
        clarifications: [],
        result: {
          summary: '保留旧摘要。', sections: [], action: '', reflection: '', algorithmVersion: 2
        },
        note: '',
        favorite: false
      }]);
      const fields: string[] = encoded.slice(4).split('|~F~|');
      const version3: string = `TR3:${fields.slice(0, 19).join('|~F~|')}`;
      const decoded: StoredReadingRecord[] = LocalDataCodec.decodeRecords(version3);

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].schemaVersion).assertEqual(3);
      expect(decoded[0].result.summary).assertEqual('保留旧摘要。');
      expect(decoded[0].result.clarificationReadings === undefined).assertTrue();
    });

    it('decodesLegacyRecordEvenWhenQuestionContainsPrintableDelimiter', 0, () => {
      const card: string = 'major-00\u001Aupright\u001A核心指引';
      const legacy: string = [
        'legacy-1',
        '1785480000000',
        '问题包含 |~F~| 但仍是旧记录',
        'single',
        'stained_glass',
        card,
        '旧摘要'
      ].join('\u001C');
      const decoded: StoredReadingRecord[] = LocalDataCodec.decodeRecords(legacy);

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].question).assertEqual('问题包含 |~F~| 但仍是旧记录');
      expect(decoded[0].result.summary).assertEqual('旧摘要');
      expect(decoded[0].schemaVersion).assertEqual(3);
    });

    it('migratesVersion2ClarificationsIntoSeparateCollection', 0, () => {
      const cards: string = [
        ['major-00', 'upright', '核心指引'].join('\u001A'),
        ['cups-02', 'reversed', '澄清 1'].join('\u001A')
      ].join('\u001B');
      const legacyV2: string = [
        'legacy-v2',
        '1785480000000',
        '下一步是什么？',
        'growth',
        'deep',
        'single',
        'stained_glass',
        cards,
        '旧 V2 摘要'
      ].join('\u001C');
      const decoded: StoredReadingRecord[] = LocalDataCodec.decodeRecords(legacyV2);

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].cards.length).assertEqual(1);
      expect(decoded[0].cards[0].cardId).assertEqual('major-00');
      expect(decoded[0].clarifications.length).assertEqual(1);
      expect(decoded[0].clarifications[0].cardId).assertEqual('cups-02');
    });

    it('roundTripsStructuredAndLegacyRecordsInOnePrintableValue', 0, () => {
      const collections: StoredReadingCollections = {
        records: [{
          schemaVersion: 3,
          id: 'reading-combined',
          createdAt: 1785480000000,
          question: '组合记录？',
          mood: '',
          scene: 'growth',
          depth: 'concise',
          spreadType: 'single',
          themeId: 'stained_glass',
          cards: [{ cardId: 'major-00', orientation: 'upright', position: '核心指引' }],
          clarifications: [],
          result: {
            summary: '组合摘要',
            sections: [],
            action: '行动',
            reflection: '反思',
            algorithmVersion: 2
          },
          note: '',
          favorite: false
        }],
        history: ['旧文本记录 |~H~| 仍保留']
      };
      const encoded: string = LocalDataCodec.encodeReadingCollections(collections);
      const decoded: StoredReadingCollections = LocalDataCodec.decodeReadingCollections(encoded);

      expect(encoded.startsWith('TRC1:')).assertTrue();
      expect(decoded.records[0].id).assertEqual('reading-combined');
      expect(decoded.history[0]).assertEqual('旧文本记录 |~H~| 仍保留');
    });

    it('rejectsMalformedReadingCollectionsInsteadOfReturningEmptyData', 0, () => {
      let didThrow: boolean = false;
      try {
        LocalDataCodec.decodeReadingCollections('TRC1:missing-separator');
      } catch {
        didThrow = true;
      }

      expect(didThrow).assertTrue();

      didThrow = false;
      try {
        LocalDataCodec.decodeReadingCollections('TRC1:%|~H~|');
      } catch {
        didThrow = true;
      }
      expect(didThrow).assertTrue();

      didThrow = false;
      try {
        LocalDataCodec.decodeReadingCollections('TRC1:legacy-record|~H~|');
      } catch {
        didThrow = true;
      }
      expect(didThrow).assertTrue();

      const malformedRows: string[] = ['TR3:', 'TR3:bad'];
      malformedRows.forEach((recordsValue: string): void => {
        didThrow = false;
        try {
          LocalDataCodec.decodeReadingCollections(
            `TRC1:${encodeURIComponent(recordsValue)}|~H~|`
          );
        } catch {
          didThrow = true;
        }
        expect(didThrow).assertTrue();
      });

      const validRecords: string = LocalDataCodec.encodeRecords([{
        schemaVersion: 3,
        id: 'valid-before-corruption',
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
      }]);
      didThrow = false;
      try {
        LocalDataCodec.decodeReadingCollections(
          `TRC1:${encodeURIComponent(`${validRecords}|~R~|bad`)}|~H~|`
        );
      } catch {
        didThrow = true;
      }
      expect(didThrow).assertTrue();

      const emptyCreatedAtFields: string[] = validRecords.slice(4).split('|~F~|');
      emptyCreatedAtFields[1] = '';
      didThrow = false;
      try {
        LocalDataCodec.decodeReadingCollections(
          `TRC1:${encodeURIComponent(`TR3:${emptyCreatedAtFields.join('|~F~|')}`)}|~H~|`
        );
      } catch {
        didThrow = true;
      }
      expect(didThrow).assertTrue();
    });

    it('rejectsMalformedVersion3RowsBeforeMigratingLegacyPreferenceKey', 0, () => {
      const validRecords: string = LocalDataCodec.encodeRecords([{
        schemaVersion: 3,
        id: 'valid-old-key-record',
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
      }]);
      let didThrow: boolean = false;

      try {
        LocalDataCodec.decodeRecords(`${validRecords}|~R~|bad`);
      } catch {
        didThrow = true;
      }

      expect(didThrow).assertTrue();
    });
  });
}
