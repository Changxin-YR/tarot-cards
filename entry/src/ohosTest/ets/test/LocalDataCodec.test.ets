import { describe, expect, it } from '@ohos/hypium';
import { LocalDataCodec, StoredCardNote } from '../../../main/ets/services/LocalDataCodec';

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
  });
}
