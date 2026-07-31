import { describe, expect, it } from '@ohos/hypium';
import { SpreadDefinition, SpreadService } from '../../../main/ets/services/SpreadService';

export default function spreadServiceTest(): void {
  describe('SpreadService', () => {
    it('definesAllFourFreeSpreads', 0, () => {
      const spreads: SpreadDefinition[] = SpreadService.all();

      expect(spreads.length).assertEqual(4);
      expect(spreads[0].id).assertEqual('single');
      expect(spreads[1].positions.join('|')).assertEqual('过去|现在|未来趋势');
      expect(spreads[2].positions.join('|')).assertEqual('我的状态|对方或外部状态|关系核心');
      expect(spreads[3].positions.length).assertEqual(7);
      expect(spreads.every((spread: SpreadDefinition): boolean => spread.isFree)).assertTrue();
    });
  });
}
