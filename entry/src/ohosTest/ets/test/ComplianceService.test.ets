import { describe, expect, it } from '@ohos/hypium';
import { ComplianceService } from '../../../main/ets/services/ComplianceService';

export default function complianceServiceTest(): void {
  describe('ComplianceService', () => {
    it('requiresAcceptanceWhenNoVersionWasSaved', 0, () => {
      expect(ComplianceService.requiresAcceptance('')).assertTrue();
    });

    it('acceptsOnlyTheCurrentPolicyVersion', 0, () => {
      expect(ComplianceService.requiresAcceptance(ComplianceService.CURRENT_VERSION)).assertFalse();
      expect(ComplianceService.requiresAcceptance('2026-07-30-v1')).assertTrue();
    });
  });
}
