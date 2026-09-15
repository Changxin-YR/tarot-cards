import { describe, expect, it } from '@ohos/hypium';
import { DrawnCard, TarotCard } from '../../../main/ets/models/TarotModels';
import {
  ReadingRelationshipService,
  RelationshipInsight
} from '../../../main/ets/services/ReadingRelationshipService';

const CUPS_FIVE: TarotCard = {
  id: 'cups-05',
  nameZhCn: '圣杯五',
  nameEn: 'Five of Cups',
  arcana: 'cups',
  number: 5,
  element: '水',
  image: 'tarot_cups_05.jpg',
  upright: {
    keywords: ['失落', '遗憾'],
    meaning: '留意已经发生的损失。',
    actionSeeds: ['看见仍然可用的支持。'],
    reflectionSeeds: ['什么还值得珍惜？']
  },
  reversed: {
    keywords: ['释怀', '重新连接'],
    meaning: '可以慢慢整理遗憾并恢复连接。',
    actionSeeds: ['确认一项仍可修复的部分。'],
    reflectionSeeds: ['你准备放下什么？']
  },
  symbolism: '五只杯子提醒人看见失去与留存。',
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
    keywords: ['离开', '重新选择'],
    meaning: '重新评估什么值得继续。',
    actionSeeds: ['记录一项需要调整的投入。'],
    reflectionSeeds: ['哪项选择更符合当下需要？']
  },
  reversed: {
    keywords: ['犹豫', '停留'],
    meaning: '先看清让自己难以离开的原因。',
    actionSeeds: ['区分依恋与真正的需要。'],
    reflectionSeeds: ['你在等待什么？']
  },
  symbolism: '离去的背影象征重新选择。',
  sourceIds: ['waite-1910']
};

const STAR: TarotCard = {
  id: 'major-17',
  nameZhCn: '星星',
  nameEn: 'The Star',
  arcana: 'major',
  number: 17,
  element: '风',
  image: 'tarot_major_17.jpg',
  upright: {
    keywords: ['希望', '修复'],
    meaning: '在不确定中保留希望。',
    actionSeeds: ['完成一个可观察的小步骤。'],
    reflectionSeeds: ['什么能帮你恢复信心？']
  },
  reversed: {
    keywords: ['信心动摇', '需要休整'],
    meaning: '先照顾正在动摇的信心。',
    actionSeeds: ['减少一项不必要的压力。'],
    reflectionSeeds: ['哪个担心需要重新核对？']
  },
  symbolism: '星光象征希望与修复。',
  sourceIds: ['waite-1910']
};

const STRENGTH: TarotCard = {
  id: 'major-08',
  nameZhCn: '力量',
  nameEn: 'Strength',
  arcana: 'major',
  number: 8,
  element: '火',
  image: 'tarot_major_08.jpg',
  upright: {
    keywords: ['耐心', '勇气'], meaning: '温和地调动内在力量。',
    actionSeeds: ['先稳住节奏。'], reflectionSeeds: ['哪种力量可以温和使用？']
  },
  reversed: {
    keywords: ['自我怀疑', '消耗'], meaning: '留意自我怀疑带来的消耗。',
    actionSeeds: ['降低一项过高要求。'], reflectionSeeds: ['哪项要求可以放松？']
  },
  symbolism: '温和面对狮子象征内在力量。', sourceIds: ['waite-1910']
};

const WANDS_TWO: TarotCard = {
  id: 'wands-02', nameZhCn: '权杖二', nameEn: 'Two of Wands', arcana: 'wands', number: 2,
  element: '火', image: 'tarot_wands_02.jpg',
  upright: { keywords: ['规划'], meaning: '整理选项。', actionSeeds: ['列出选项。'], reflectionSeeds: ['你在规划什么？'] },
  reversed: { keywords: ['犹豫'], meaning: '留意犹豫。', actionSeeds: ['缩小范围。'], reflectionSeeds: ['什么让你犹豫？'] },
  symbolism: '手持地球象征规划。', sourceIds: ['waite-1910']
};

const SWORDS_THREE: TarotCard = {
  id: 'swords-03', nameZhCn: '宝剑三', nameEn: 'Three of Swords', arcana: 'swords', number: 3,
  element: '风', image: 'tarot_swords_03.jpg',
  upright: { keywords: ['诚实面对'], meaning: '认出真实感受。', actionSeeds: ['命名感受。'], reflectionSeeds: ['什么感受需要被看见？'] },
  reversed: { keywords: ['修复'], meaning: '给修复留出时间。', actionSeeds: ['先休息。'], reflectionSeeds: ['什么支持修复？'] },
  symbolism: '剑与心象征诚实面对感受。', sourceIds: ['waite-1910']
};

const PENTACLES_FOUR: TarotCard = {
  id: 'pentacles-04', nameZhCn: '星币四', nameEn: 'Four of Pentacles', arcana: 'pentacles', number: 4,
  element: '土', image: 'tarot_pentacles_04.jpg',
  upright: { keywords: ['边界'], meaning: '检查资源与边界。', actionSeeds: ['确认边界。'], reflectionSeeds: ['什么值得保留？'] },
  reversed: { keywords: ['放松'], meaning: '适度放松控制。', actionSeeds: ['松开一项控制。'], reflectionSeeds: ['什么可以放松？'] },
  symbolism: '紧握星币象征资源与边界。', sourceIds: ['waite-1910']
};

export default function readingRelationshipServiceTest(): void {
  describe('ReadingRelationshipService', () => {
    it('describesReversedToUprightTurnAndRepeatedSuit', 0, () => {
      const insight: RelationshipInsight = ReadingRelationshipService.analyze([
        { cardId: 'cups-05', orientation: 'reversed', position: '过去' },
        { cardId: 'cups-08', orientation: 'upright', position: '现在' },
        { cardId: 'major-17', orientation: 'upright', position: '行动建议' }
      ], [CUPS_FIVE, CUPS_EIGHT, STAR]);

      expect(insight.patterns[0]).assertEqual('orientation_turn');
      expect(insight.patterns.includes('suit_cluster')).assertTrue();
      expect(insight.text.includes('过去')).assertTrue();
      expect(insight.text.includes('现在')).assertTrue();
      expect(insight.text.includes('释怀')).assertTrue();
      expect(insight.text.includes('离开')).assertTrue();
    });

    it('describesUprightToReversedTurn', 0, () => {
      const insight: RelationshipInsight = ReadingRelationshipService.analyze([
        { cardId: 'major-17', orientation: 'upright', position: '起点' },
        { cardId: 'cups-05', orientation: 'reversed', position: '调整' }
      ], [STAR, CUPS_FIVE]);

      expect(insight.patterns[0]).assertEqual('orientation_turn');
      expect(insight.text.includes('正向视角')).assertTrue();
      expect(insight.text.includes('侧向视角')).assertTrue();
    });

    it('recognizesMajorArcanaConcentration', 0, () => {
      const insight: RelationshipInsight = ReadingRelationshipService.analyze([
        { cardId: 'major-17', orientation: 'upright', position: '起点' },
        { cardId: 'major-08', orientation: 'upright', position: '核心' },
        { cardId: 'cups-05', orientation: 'upright', position: '落点' }
      ], [STAR, STRENGTH, CUPS_FIVE]);

      expect(insight.patterns.includes('major_focus')).assertTrue();
      expect(insight.text.includes('星星')).assertTrue();
      expect(insight.text.includes('力量')).assertTrue();
      expect(insight.text.includes('长期主题')).assertTrue();
    });

    it('recognizesAdjacentElementSupport', 0, () => {
      const insight: RelationshipInsight = ReadingRelationshipService.analyze([
        { cardId: 'wands-02', orientation: 'upright', position: '起点' },
        { cardId: 'swords-03', orientation: 'upright', position: '推进' }
      ], [WANDS_TWO, SWORDS_THREE]);

      expect(insight.patterns.includes('element_support')).assertTrue();
      expect(insight.text.includes('权杖二')).assertTrue();
      expect(insight.text.includes('宝剑三')).assertTrue();
    });

    it('usesNeutralSequenceWhenNoReliablePatternExists', 0, () => {
      const insight: RelationshipInsight = ReadingRelationshipService.analyze([
        { cardId: 'cups-05', orientation: 'upright', position: '起点' },
        { cardId: 'wands-02', orientation: 'upright', position: '过程' },
        { cardId: 'pentacles-04', orientation: 'upright', position: '落点' }
      ], [CUPS_FIVE, WANDS_TWO, PENTACLES_FOUR]);

      expect(insight.patterns.length).assertEqual(1);
      expect(insight.patterns[0]).assertEqual('neutral_sequence');
      expect(insight.text.includes('起点')).assertTrue();
      expect(insight.text.includes('落点')).assertTrue();
      expect(insight.text.includes('不代表确定')).assertTrue();
    });

    it('throwsWhenDrawnCardIsMissingFromCatalog', 0, () => {
      const cards: DrawnCard[] = [
        { cardId: 'missing-card', orientation: 'upright', position: '核心' }
      ];
      let thrown: boolean = false;
      try {
        ReadingRelationshipService.analyze(cards, [STAR]);
      } catch (error) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
