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

    it('usesExplicitQuestionSemanticsOverAMismatchedSceneChip', 0, () => {
      expect(QuestionClassifier.sceneFor('明天的工作汇报怎么准备？', 'relationship'))
        .assertEqual('career');
      expect(QuestionClassifier.sceneFor('考试前应该怎样安排复习？', 'relationship'))
        .assertEqual('study');
      expect(QuestionClassifier.sceneFor('怎样和伴侣谈清楚边界？', 'career'))
        .assertEqual('relationship');
      expect(QuestionClassifier.sceneFor('和朋友相处时怎样表达不同意见？', 'career'))
        .assertEqual('social');
    });

    it('keepsSelectedSceneWhenQuestionHasNoExplicitScene', 0, () => {
      expect(QuestionClassifier.sceneFor('我现在最需要关注什么？', 'growth'))
        .assertEqual('growth');
    });
  });
}
