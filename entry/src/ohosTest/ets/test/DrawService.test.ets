import { describe, expect, it } from '@ohos/hypium';
import { DrawService } from '../../../main/ets/services/DrawService';
import { DrawnCard } from '../../../main/ets/models/TarotModels';

export default function drawServiceTest(): void {
  describe('DrawService', () => {
    it('drawsOneCardUsingInjectedRandom', 0, () => {
      const result: DrawnCard = DrawService.drawSingle(
        ['major-00', 'major-01', 'major-02'],
        true,
        (): number => 0
      );

      expect(result.cardId).assertEqual('major-00');
      expect(result.orientation).assertEqual('upright');
    });

    it('drawsThreeUniqueCards', 0, () => {
      const values: number[] = [0.05, 0.05, 0.05, 0.05, 0.05, 0.05];
      let cursor: number = 0;
      const result: DrawnCard[] = DrawService.drawThree(
        ['major-00', 'major-01', 'major-02', 'major-03'],
        true,
        (): number => values[cursor++ % values.length]
      );

      expect(result.length).assertEqual(3);
      expect(new Set<string>(result.map((item: DrawnCard): string => item.cardId)).size).assertEqual(3);
      expect(result[0].position).assertEqual('过去');
      expect(result[1].position).assertEqual('现在');
      expect(result[2].position).assertEqual('行动建议');
    });

    it('keepsDailyDrawStableForSameDate', 0, () => {
      const first: DrawnCard = DrawService.dailyDraw(
        ['major-00', 'major-01', 'major-02'],
        '2026-07-30',
        true
      );
      const second: DrawnCard = DrawService.dailyDraw(
        ['major-00', 'major-01', 'major-02'],
        '2026-07-30',
        true
      );

      expect(first.cardId).assertEqual(second.cardId);
      expect(first.orientation).assertEqual(second.orientation);
    });

    it('usesOnlyUprightWhenReversalsDisabled', 0, () => {
      const result: DrawnCard = DrawService.drawSingle(
        ['major-00'],
        false,
        (): number => 0.99
      );

      expect(result.orientation).assertEqual('upright');
    });
  });
}

