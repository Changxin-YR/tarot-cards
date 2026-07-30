import { describe, expect, it } from '@ohos/hypium';
import {
  ReadingContext,
  ReadingResult,
  TarotCard
} from '../../../main/ets/models/TarotModels';
import { InterpretationService } from '../../../main/ets/services/InterpretationService';

const SAMPLE_CARD: TarotCard = {
  id: 'major-17',
  nameZhCn: '星星',
  nameEn: 'The Star',
  arcana: 'major',
  number: 17,
  element: '风',
  image: 'tarot_major_17_star.jpg',
  upright: {
    keywords: ['希望', '疗愈', '信念'],
    meaning: '星星邀请你在不确定中保留希望。',
    actionSeeds: ['写下一个今天能够完成的小步骤。'],
    reflectionSeeds: ['什么能够帮你重新看见希望？']
  },
  reversed: {
    keywords: ['失去信心', '灰心', '断联'],
    meaning: '逆位提醒你先照顾正在动摇的信心。',
    actionSeeds: ['减少一个不必要的压力来源。'],
    reflectionSeeds: ['你把哪一种担忧当成了事实？']
  },
  symbolism: '星光落入水面，象征希望与修复。',
  sourceIds: ['waite-1910']
};

export default function interpretationServiceTest(): void {
  describe('InterpretationService', () => {
    it('usesQuestionMoodAndCardMeaning', 0, () => {
      const context: ReadingContext = {
        question: '工作汇报前我需要关注什么？',
        category: 'workStudy',
        mood: '紧张',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }]
      };
      const result: ReadingResult = InterpretationService.build(context, [SAMPLE_CARD]);

      expect(result.summary.includes('工作')).assertTrue();
      expect(result.summary.includes('紧张')).assertTrue();
      expect(result.sections[0].meaning.includes('希望')).assertTrue();
      expect(result.action.length > 0).assertTrue();
      expect(result.reflection.length > 0).assertTrue();
    });

    it('connectsThreeCardSpread', 0, () => {
      const context: ReadingContext = {
        question: '我如何推进当前计划？',
        category: 'decision',
        recentThemes: ['行动'],
        cards: [
          { cardId: 'major-17', orientation: 'upright', position: '过去' },
          { cardId: 'major-17', orientation: 'reversed', position: '现在' },
          { cardId: 'major-17', orientation: 'upright', position: '行动建议' }
        ]
      };
      const result: ReadingResult = InterpretationService.build(context, [SAMPLE_CARD]);

      expect(result.sections.length).assertEqual(3);
      expect((result.connection ?? '').length > 0).assertTrue();
    });

    it('addsSafetyNoticeForHighRiskQuestion', 0, () => {
      const context: ReadingContext = {
        question: '我应该买哪只股票？',
        category: 'decision',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }]
      };
      const result: ReadingResult = InterpretationService.build(context, [SAMPLE_CARD]);

      expect((result.safetyNotice ?? '').includes('专业人士')).assertTrue();
    });
  });
}
