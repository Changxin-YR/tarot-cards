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

    it('removesDeterministicLanguage', 0, () => {
      const filtered: string = SafetyService.soften('你一定会成功，这是注定的结果。');

      expect(filtered.includes('一定')).assertFalse();
      expect(filtered.includes('注定')).assertFalse();
    });
  });
}

