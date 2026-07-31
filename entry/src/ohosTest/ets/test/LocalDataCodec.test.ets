import { describe, expect, it } from '@ohos/hypium';
import { LocalDataCodec, StoredCardNote, StoredReadingRecord } from '../../../main/ets/repositories/LocalDataCodec';

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
        id: 'reading-1',
        createdAt: 1785480000000,
        question: '我应该关注什么？',
        scene: 'relationship',
        depth: 'deep',
        spreadType: 'relationship',
        themeId: 'stained_glass',
        cards: [{ cardId: 'major-01', orientation: 'reversed', position: '关系核心' }],
        summary: '先看见彼此真实的需要。'
      }];

      const decoded: StoredReadingRecord[] = LocalDataCodec.decodeRecords(
        LocalDataCodec.encodeRecords(records)
      );

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].themeId).assertEqual('stained_glass');
      expect(decoded[0].depth).assertEqual('deep');
      expect(decoded[0].cards[0].position).assertEqual('关系核心');
      expect(decoded[0].summary).assertEqual('先看见彼此真实的需要。');
    });
  });
}
