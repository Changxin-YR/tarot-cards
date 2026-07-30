import {
  CardReadingSection,
  DrawnCard,
  ReadingContext,
  ReadingResult,
  TarotCard,
  TarotMeaningSide
} from '../models/TarotModels';
import { SafetyService } from './SafetyService';

export class InterpretationService {
  static build(context: ReadingContext, catalog: TarotCard[]): ReadingResult {
    const sections: CardReadingSection[] = context.cards.map(
      (drawn: DrawnCard): CardReadingSection => {
        const card: TarotCard = InterpretationService.requireCard(drawn.cardId, catalog);
        const side: TarotMeaningSide =
          drawn.orientation === 'upright' ? card.upright : card.reversed;
        return {
          cardId: card.id,
          cardName: card.nameZhCn,
          orientation: drawn.orientation,
          position: drawn.position,
          keywords: side.keywords,
          meaning: SafetyService.soften(
            `${drawn.position}位置的${card.nameZhCn}，把注意力带向${side.keywords.slice(0, 3).join('、')}。${side.meaning}`
          )
        };
      }
    );

    const primaryDraw: DrawnCard = context.cards[0];
    const primaryCard: TarotCard = InterpretationService.requireCard(primaryDraw.cardId, catalog);
    const primarySide: TarotMeaningSide =
      primaryDraw.orientation === 'upright' ? primaryCard.upright : primaryCard.reversed;
    const categoryLabel: string = InterpretationService.categoryLabel(context.category);
    const moodText: string = context.mood === undefined || context.mood.length === 0
      ? ''
      : `你提到此刻感到${context.mood}，这份感受也值得被认真看见。`;
    const recentText: string = context.recentThemes.length === 0
      ? ''
      : `近期反复出现的主题是${context.recentThemes.slice(0, 2).join('、')}。`;
    const supplementText: string = context.supplement === undefined || context.supplement.trim().length === 0
      ? ''
      : `你补充的”${context.supplement.trim().slice(0, 160)}”也让解读更贴近你的处境。`;
    const summary: string = SafetyService.soften(
      `围绕${categoryLabel}，${primaryCard.nameZhCn}邀请你先关注”${primarySide.keywords[0]}”。${moodText}${recentText}${supplementText}`
    );
    const connection: string | undefined = sections.length === 3
      ? SafetyService.soften(
        `三张牌从${sections[0].keywords[0]}走向${sections[1].keywords[0]}，并把可执行的焦点落在${sections[2].keywords[0]}。它们更像一条整理线索，而不是对未来的确定预测。`
      )
      : undefined;
    const notice: string = SafetyService.noticeFor(context.question);
    const result: ReadingResult = {
      summary,
      sections,
      action: SafetyService.soften(primarySide.actionSeeds[0]),
      reflection: SafetyService.soften(primarySide.reflectionSeeds[0]),
      algorithmVersion: 1
    };
    if (connection !== undefined) {
      result.connection = connection;
    }
    if (notice.length > 0) {
      result.safetyNotice = notice;
    }
    return result;
  }

  private static requireCard(cardId: string, catalog: TarotCard[]): TarotCard {
    const card: TarotCard | undefined = catalog.find(
      (item: TarotCard): boolean => item.id === cardId
    );
    if (card === undefined) {
      throw new Error(`找不到牌：${cardId}`);
    }
    return card;
  }

  private static categoryLabel(category: string): string {
    if (category === 'relationship') {
      return '关系与沟通';
    }
    if (category === 'workStudy') {
      return '工作与学习';
    }
    if (category === 'decision') {
      return '选择与决策';
    }
    if (category === 'emotion') {
      return '情绪与压力';
    }
    if (category === 'growth') {
      return '自我成长';
    }
    return '今天的状态';
  }
}
