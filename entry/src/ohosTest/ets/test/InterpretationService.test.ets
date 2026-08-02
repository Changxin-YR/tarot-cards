import { describe, expect, it } from '@ohos/hypium';
import {
  Orientation,
  ReadingContext,
  ReadingResult,
  TarotCard
} from '../../../main/ets/models/TarotModels';
import { InterpretationService } from '../../../main/ets/services/InterpretationService';
import { StoredReadingRecord } from '../../../main/ets/repositories/LocalDataCodec';

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

const CUPS_FIVE: TarotCard = {
  id: 'cups-05',
  nameZhCn: '圣杯五',
  nameEn: 'Five of Cups',
  arcana: 'cups',
  number: 5,
  element: '水',
  image: 'tarot_cups_05.jpg',
  upright: {
    keywords: ['失落', '遗憾', '仍有支持'],
    meaning: '这张牌提醒你同时看见失去与仍然存在的支持。',
    actionSeeds: ['列出一项仍然可以使用的支持。'],
    reflectionSeeds: ['什么仍然值得被珍惜？']
  },
  reversed: {
    keywords: ['释怀', '重新连接', '恢复'],
    meaning: '逆位提示你正在获得重新整理遗憾的空间。',
    actionSeeds: ['确认一项可以逐步修复的部分。'],
    reflectionSeeds: ['你准备慢慢放下什么？']
  },
  symbolism: '倾倒与仍然直立的杯子象征失去和留存。',
  sourceIds: ['waite-1910']
};

const CUPS_EIGHT: TarotCard = {
  id: 'cups-08',
  nameZhCn: '圣杯八',
  nameEn: 'Eight of Cups',
  arcana: 'cups',
  number: 8,
  element: '水',
  image: 'tarot_cups_08.jpg',
  upright: {
    keywords: ['离开', '重新选择', '寻找意义'],
    meaning: '这张牌邀请你重新评估什么值得继续投入。',
    actionSeeds: ['记录一项需要调整的投入。'],
    reflectionSeeds: ['哪项选择更符合当下需要？']
  },
  reversed: {
    keywords: ['犹豫', '停留', '回避改变'],
    meaning: '逆位提醒你先看清难以离开的真实原因。',
    actionSeeds: ['区分依恋与真正的需要。'],
    reflectionSeeds: ['你在等待哪个条件？']
  },
  symbolism: '离去的背影象征重新选择方向。',
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

    it('derivesRecentThemesFromSavedRecords', 0, () => {
      const recordWithSections: StoredReadingRecord = {
        schemaVersion: 3,
        id: 'r1',
        createdAt: 1,
        question: '',
        mood: '',
        scene: 'daily',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        clarifications: [],
        result: {
          summary: '',
          sections: [{
            cardId: 'major-17',
            cardName: '星星',
            orientation: 'upright',
            position: '核心提示',
            keywords: ['希望', '疗愈', '信念'],
            meaning: ''
          }],
          action: '',
          reflection: '',
          algorithmVersion: 1
        },
        note: '',
        favorite: false
      };
      const legacyRecord: StoredReadingRecord = {
        schemaVersion: 3,
        id: 'r2',
        createdAt: 2,
        question: '',
        mood: '',
        scene: 'daily',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-17', orientation: 'reversed', position: '核心提示' }],
        clarifications: [],
        result: { summary: '', sections: [], action: '', reflection: '', algorithmVersion: 1 },
        note: '',
        favorite: false
      };

      const themes: string[] = InterpretationService.recentThemesFromRecords(
        [recordWithSections, legacyRecord],
        (cardId: string, orientation: Orientation): string[] => {
          if (cardId === 'major-17') {
            return orientation === 'reversed' ? ['失去信心', '灰心'] : ['希望', '疗愈', '信念'];
          }
          return [];
        }
      );

      expect(themes.length).assertEqual(3);
      expect(themes[0]).assertEqual('希望');
      expect(themes[1]).assertEqual('疗愈');
      expect(themes[2]).assertEqual('信念');
    });

    it('fallsBackToCardKeywordsWhenSectionsMissing', 0, () => {
      const legacy: StoredReadingRecord = {
        schemaVersion: 3,
        id: 'r3',
        createdAt: 3,
        question: '',
        mood: '',
        scene: 'daily',
        depth: 'concise',
        spreadType: 'single',
        themeId: 'moon_garden',
        cards: [{ cardId: 'major-17', orientation: 'reversed', position: '核心提示' }],
        clarifications: [],
        result: { summary: '', sections: [], action: '', reflection: '', algorithmVersion: 1 },
        note: '',
        favorite: false
      };

      const themes: string[] = InterpretationService.recentThemesFromRecords(
        [legacy],
        (cardId: string, orientation: Orientation): string[] => {
          if (cardId === 'major-17') {
            return orientation === 'reversed' ? ['失去信心', '灰心'] : ['希望', '疗愈', '信念'];
          }
          return [];
        }
      );

      expect(themes.length).assertEqual(2);
      expect(themes[0]).assertEqual('失去信心');
      expect(themes[1]).assertEqual('灰心');
    });

    it('limitsRecentThemesToThreeDeduplicated', 0, () => {
      const base: StoredReadingRecord = {
        schemaVersion: 3, id: 'a', createdAt: 1, question: '', mood: '', scene: 'daily',
        depth: 'concise', spreadType: 'single', themeId: 'moon_garden',
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        clarifications: [], note: '', favorite: false,
        result: {
          summary: '', action: '', reflection: '', algorithmVersion: 1,
          sections: [{
            cardId: 'major-17', cardName: '星星', orientation: 'upright',
            position: '核心提示', keywords: ['希望', '疗愈'], meaning: ''
          }]
        }
      };
      const next: StoredReadingRecord = {
        schemaVersion: 3, id: 'b', createdAt: 2, question: '', mood: '', scene: 'daily',
        depth: 'concise', spreadType: 'single', themeId: 'moon_garden',
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        clarifications: [], note: '', favorite: false,
        result: {
          summary: '', action: '', reflection: '', algorithmVersion: 1,
          sections: [{
            cardId: 'major-17', cardName: '星星', orientation: 'upright',
            position: '核心提示', keywords: ['希望', '信念'], meaning: ''
          }]
        }
      };

      const themes: string[] = InterpretationService.recentThemesFromRecords(
        [next, base],
        (): string[] => []
      );

      expect(themes.length).assertEqual(3);
      expect(themes[0]).assertEqual('希望');
      expect(themes[1]).assertEqual('信念');
      expect(themes[2]).assertEqual('疗愈');
    });

    it('connectsTheReadingToTheUsersExactQuestionAndScene', 0, () => {
      const career: ReadingResult = InterpretationService.build({
        question: '项目延期后我该怎么重新推进？',
        category: 'workStudy',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        scene: 'career',
        depth: 'deep'
      }, [SAMPLE_CARD]);
      const relationship: ReadingResult = InterpretationService.build({
        question: '关系中如何更坦诚地沟通？',
        category: 'relationship',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        scene: 'relationship',
        depth: 'deep'
      }, [SAMPLE_CARD]);

      expect(career.summary.includes('项目延期')).assertTrue();
      expect(career.summary.includes('工作与推进')).assertTrue();
      expect(relationship.summary.includes('坦诚地沟通')).assertTrue();
      expect(relationship.summary.includes('关系与沟通')).assertTrue();
      expect(career.summary === relationship.summary).assertFalse();
      expect(career.algorithmVersion).assertEqual(3);
    });

    it('keepsReversedReadingsConstructiveWithoutPromises', 0, () => {
      const result: ReadingResult = InterpretationService.build({
        question: '这次面试我还有哪些可以准备？',
        category: 'workStudy',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'reversed', position: '核心提示' }],
        scene: 'career',
        depth: 'concise'
      }, [SAMPLE_CARD]);

      expect(result.summary.includes('可调整')).assertTrue();
      expect(result.action.includes('可以')).assertTrue();
      expect(result.summary.includes('一定会')).assertFalse();
      expect(result.summary.includes('保证')).assertFalse();
    });

    it('explainsClarificationsWithoutMixingThemIntoMainSections', 0, () => {
      const context: ReadingContext = {
        question: '我该如何推进这个停滞的项目？',
        category: 'workStudy',
        recentThemes: [],
        cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
        clarifications: [
          { cardId: 'cups-05', orientation: 'reversed', position: '澄清 1' },
          { cardId: 'cups-08', orientation: 'upright', position: '澄清 2' }
        ],
        scene: 'career',
        depth: 'deep'
      };

      const result: ReadingResult = InterpretationService.build(
        context,
        [SAMPLE_CARD, CUPS_FIVE, CUPS_EIGHT]
      );

      expect(result.sections.length).assertEqual(1);
      expect(result.sections[0].meaning.includes('可以利用')).assertTrue();
      expect(result.sections[0].meaning.includes('需要留意')).assertTrue();
      const clarifications = result.clarificationReadings ?? [];
      expect(clarifications.length).assertEqual(2);
      expect(clarifications[0].focus.length > 0).assertTrue();
      expect(clarifications[0].meaning.includes('圣杯五')).assertTrue();
      expect(clarifications[0].impact.length > 0).assertTrue();
      expect(clarifications[0].action.length > 0).assertTrue();
      expect(clarifications[1].impactType).assertEqual('adjust');
      expect(clarifications[1].impact.includes('上一张')).assertTrue();
      expect(result.algorithmVersion).assertEqual(3);
    });

    it('keepsVersion3OutputStableForTheSameInput', 0, () => {
      const context: ReadingContext = {
        question: '关系中如何更坦诚地沟通？',
        category: 'relationship',
        mood: '困惑',
        recentThemes: ['沟通'],
        cards: [
          { cardId: 'major-17', orientation: 'upright', position: '关系核心' },
          { cardId: 'cups-05', orientation: 'reversed', position: '我的状态' }
        ],
        clarifications: [
          { cardId: 'cups-08', orientation: 'upright', position: '澄清 1' }
        ],
        scene: 'relationship',
        depth: 'deep'
      };
      const first: ReadingResult = InterpretationService.build(
        context,
        [SAMPLE_CARD, CUPS_FIVE, CUPS_EIGHT]
      );
      const second: ReadingResult = InterpretationService.build(
        context,
        [SAMPLE_CARD, CUPS_FIVE, CUPS_EIGHT]
      );

      expect(first.summary).assertEqual(second.summary);
      expect(first.connection ?? '').assertEqual(second.connection ?? '');
      expect(first.action).assertEqual(second.action);
      expect(first.reflection).assertEqual(second.reflection);
      expect(JSON.stringify(first.clarificationReadings ?? [])).assertEqual(
        JSON.stringify(second.clarificationReadings ?? [])
      );
    });
  });
}
