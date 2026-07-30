import { describe, expect, it } from '@ohos/hypium';
import { LocalDataCodec } from '../../../main/ets/services/LocalDataCodec';

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
  });
}
