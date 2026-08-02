import { describe, expect, it } from '@ohos/hypium';
import { NavigationService } from '../../../main/ets/services/NavigationService';

export default function navigationServiceTest(): void {
  describe('NavigationService', () => {
    it('returnsToTheActualPreviousPage', 0, () => {
      const navigation: NavigationService = new NavigationService('home');
      navigation.push('question');
      navigation.push('drawMode');

      expect(navigation.back()).assertEqual('question');
      expect(navigation.back()).assertEqual('home');
      expect(navigation.back()).assertEqual('home');
    });

    it('resetsHistoryWhenSelectingARootTab', 0, () => {
      const navigation: NavigationService = new NavigationService('home');
      navigation.push('question');
      navigation.push('shuffle');

      expect(navigation.selectRoot('catalog')).assertEqual('catalog');
      expect(navigation.depth()).assertEqual(1);
      expect(navigation.back()).assertEqual('catalog');
    });

    it('detectsOnlyASecondBackInsideTheTimeWindow', 0, () => {
      expect(NavigationService.isSecondBack(1000, 2200, 1500)).assertTrue();
      expect(NavigationService.isSecondBack(1000, 2501, 1500)).assertFalse();
      expect(NavigationService.isSecondBack(0, 500, 1500)).assertFalse();
    });
  });
}
