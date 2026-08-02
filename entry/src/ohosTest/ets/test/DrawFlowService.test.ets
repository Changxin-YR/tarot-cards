import { describe, expect, it } from '@ohos/hypium';
import { DrawFlowService } from '../../../main/ets/services/DrawFlowService';

export default function drawFlowServiceTest(): void {
  describe('DrawFlowService', () => {
    it('requiresThreeShuffleInteractionsBeforeSelection', 0, () => {
      const flow: DrawFlowService = new DrawFlowService(1);
      expect(flow.canSelect()).assertFalse();
      expect(flow.shuffle()).assertEqual(1);
      expect(flow.shuffle()).assertEqual(2);
      expect(flow.canSelect()).assertFalse();
      expect(flow.shuffle()).assertEqual(3);
      expect(flow.canSelect()).assertTrue();
      expect(flow.shuffle()).assertEqual(3);
    });

    it('allowsSelectionChangesUntilExactCountIsConfirmed', 0, () => {
      const flow: DrawFlowService = new DrawFlowService(2);
      flow.shuffle();
      flow.shuffle();
      flow.shuffle();

      expect(flow.toggle('major-00')).assertTrue();
      expect(flow.toggle('major-00')).assertTrue();
      expect(flow.selectedCount()).assertEqual(0);
      expect(flow.confirm()).assertFalse();
      expect(flow.toggle('major-00')).assertTrue();
      expect(flow.toggle('major-01')).assertTrue();
      expect(flow.toggle('major-02')).assertFalse();
      expect(flow.confirm()).assertTrue();
      expect(flow.toggle('major-02')).assertFalse();
      expect(flow.selectedIds()[0]).assertEqual('major-00');
    });

    it('revealsLockedCardsOneAtATime', 0, () => {
      const flow: DrawFlowService = new DrawFlowService(2);
      flow.shuffle();
      flow.shuffle();
      flow.shuffle();
      flow.toggle('major-00');
      flow.toggle('major-01');
      flow.confirm();

      expect(flow.revealNext()).assertEqual(1);
      expect(flow.allRevealed()).assertFalse();
      expect(flow.revealNext()).assertEqual(2);
      expect(flow.allRevealed()).assertTrue();
      expect(flow.revealNext()).assertEqual(2);
    });
  });
}
