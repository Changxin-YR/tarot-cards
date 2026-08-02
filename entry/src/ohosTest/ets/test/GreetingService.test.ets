import { describe, expect, it } from '@ohos/hypium';
import { GreetingService } from '../../../main/ets/services/GreetingService';

export default function greetingServiceTest(): void {
  describe('GreetingService', () => {
    it('usesExpectedGreetingAtEveryBoundary', 0, () => {
      expect(GreetingService.forHour(0).title).assertEqual('夜深了');
      expect(GreetingService.forHour(5).title).assertEqual('早上好');
      expect(GreetingService.forHour(9).title).assertEqual('上午好');
      expect(GreetingService.forHour(12).title).assertEqual('中午好');
      expect(GreetingService.forHour(14).title).assertEqual('下午好');
      expect(GreetingService.forHour(18).title).assertEqual('晚上好');
      expect(GreetingService.forHour(22).title).assertEqual('夜深了');
    });

    it('normalizesHoursOutsideTheClockRange', 0, () => {
      expect(GreetingService.forHour(29).title).assertEqual('早上好');
      expect(GreetingService.forHour(-2).title).assertEqual('夜深了');
    });
  });
}
