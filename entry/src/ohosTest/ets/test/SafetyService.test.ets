import { describe, expect, it } from '@ohos/hypium';
import { SafetyService } from '../../../main/ets/services/SafetyService';

export default function safetyServiceTest(): void {
  describe('SafetyService', () => {
    it('detectsMedicalQuestion', 0, () => {
      expect(SafetyService.isHighRisk('我会得什么病？')).assertTrue();
    });

    it('providesProfessionalAdviceNotice', 0, () => {
      expect(SafetyService.noticeFor('哪只股票一定上涨').includes('专业人士')).assertTrue();
    });

    it('detectsHighRiskDespiteWhitespace', 0, () => {
      expect(SafetyService.isHighRisk('我得了 癌 症，怎么办？')).assertTrue();
      expect(SafetyService.isHighRisk('投 资基 金')).assertTrue();
      expect(SafetyService.isHighRisk('股票  一定会涨')).assertTrue();
    });

    it('detectsHighRiskMixedWithLatinAndCase', 0, () => {
      expect(SafetyService.isHighRisk('Cancer 诊断')).assertTrue();
      expect(SafetyService.isHighRisk('听说那个 Legal Case 要 判 刑')).assertTrue();
    });

    it('doesNotFlagScatteredUnrelatedText', 0, () => {
      expect(SafetyService.isHighRisk('cancer support group 的日常活动')).assertFalse();
      expect(SafetyService.isHighRisk('legal 话题讨论')).assertFalse();
      expect(SafetyService.isHighRisk('今天天气很好')).assertFalse();
    });

    it('removesDeterministicLanguage', 0, () => {
      const filtered: string = SafetyService.soften('你一定会成功，这是注定的结果。');

      expect(filtered.includes('一定')).assertFalse();
      expect(filtered.includes('注定')).assertFalse();
    });

    it('detectsImmediateSafetyAndMedicationQuestions', 0, () => {
      expect(SafetyService.isHighRisk('我想伤害自己')).assertTrue();
      expect(SafetyService.isHighRisk('我现在要不要停药')).assertTrue();
    });

    it('detectsDeterministicLegalAndInvestmentDecisions', 0, () => {
      expect(SafetyService.isHighRisk('这场官司一定会赢吗')).assertTrue();
      expect(SafetyService.isHighRisk('现在该买哪只股票')).assertTrue();
    });

    it('keepsOrdinaryReflectionQuestionsAvailable', 0, () => {
      expect(SafetyService.isHighRisk('我今天怎样整理低落情绪')).assertFalse();
    });
  });
}
