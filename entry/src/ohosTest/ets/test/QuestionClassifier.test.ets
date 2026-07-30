import { describe, expect, it } from '@ohos/hypium';
import { QuestionClassifier } from '../../../main/ets/services/QuestionClassifier';

export default function questionClassifierTest(): void {
  describe('QuestionClassifier', () => {
    it('classifiesRelationshipQuestion', 0, () => {
      expect(QuestionClassifier.classify('我应该怎样看待这段关系？')).assertEqual('relationship');
    });

    it('classifiesWorkQuestion', 0, () => {
      expect(QuestionClassifier.classify('这次工作汇报要注意什么？')).assertEqual('workStudy');
    });

    it('classifiesDecisionQuestion', 0, () => {
      expect(QuestionClassifier.classify('面对两个选择，我忽略了什么？')).assertEqual('decision');
    });

    it('fallsBackToDailyForEmptyQuestion', 0, () => {
      expect(QuestionClassifier.classify('  ')).assertEqual('daily');
    });
  });
}

