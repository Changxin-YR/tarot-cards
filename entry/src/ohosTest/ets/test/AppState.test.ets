import { describe, expect, it } from '@ohos/hypium';
import { TarotAppState } from '../../../main/ets/models/TarotAppState';

export default function appStateTest(): void {
  describe('TarotAppState', () => {
    it('startsOnHome', 0, () => {
      expect(new TarotAppState().page).assertEqual('home');
    });

    it('movesThroughQuestionAndDraw', 0, () => {
      const state: TarotAppState = new TarotAppState();
      state.chooseSpread('single');
      expect(state.page).assertEqual('question');
      state.submitQuestion('我需要关注什么？');
      expect(state.page).assertEqual('shuffle');
    });

    it('preventsDuplicateShuffle', 0, () => {
      const state: TarotAppState = new TarotAppState();
      expect(state.beginShuffle()).assertTrue();
      expect(state.beginShuffle()).assertFalse();
      state.resetAnimation();
      expect(state.beginShuffle()).assertTrue();
    });
  });
}
