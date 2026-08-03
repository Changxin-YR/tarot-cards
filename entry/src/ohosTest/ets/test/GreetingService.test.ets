import { describe, expect, it } from '@ohos/hypium';
import { GreetingService } from '../../../main/ets/services/GreetingService';

export default function greetingServiceTest(): void {
  describe('GreetingService', () => {
    it('usesExpectedGreetingAtEveryBoundary', 0, () => {
      expect(GreetingService.forHour(0).title).assertEqual('夜深了');
      expect(GreetingService.forHour(0).subtitle).assertEqual('愿你卸下疲惫，安心度过今夜');
      expect(GreetingService.forHour(5).title).assertEqual('早上好');
      expect(GreetingService.forHour(5).subtitle).assertEqual('新的一天，愿你心怀轻盈与期待');
      expect(GreetingService.forHour(9).title).assertEqual('上午好');
      expect(GreetingService.forHour(9).subtitle).assertEqual('愿今天的每一步都从容而清晰');
      expect(GreetingService.forHour(12).title).assertEqual('中午好');
      expect(GreetingService.forHour(12).subtitle).assertEqual('忙碌半日，记得让自己稍作休息');
      expect(GreetingService.forHour(14).title).assertEqual('下午好');
      expect(GreetingService.forHour(14).subtitle).assertEqual('愿午后的时光温柔而充实');
      expect(GreetingService.forHour(18).title).assertEqual('晚上好');
      expect(GreetingService.forHour(18).subtitle).assertEqual('辛苦一天，愿此刻轻松而宁静');
      expect(GreetingService.forHour(22).title).assertEqual('夜深了');
      expect(GreetingService.forHour(22).subtitle).assertEqual('愿你卸下疲惫，安心度过今夜');
    });

    it('normalizesHoursOutsideTheClockRange', 0, () => {
      expect(GreetingService.forHour(29).title).assertEqual('早上好');
      expect(GreetingService.forHour(-2).title).assertEqual('夜深了');
    });
  });
}
