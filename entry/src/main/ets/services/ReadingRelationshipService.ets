import { DrawnCard, TarotCard, TarotMeaningSide } from '../models/TarotModels';

export type RelationshipPattern =
  'orientation_turn' | 'suit_cluster' | 'major_focus' | 'element_support' | 'neutral_sequence';

export interface RelationshipInsight {
  patterns: RelationshipPattern[];
  text: string;
}

interface ResolvedDraw {
  drawn: DrawnCard;
  card: TarotCard;
}

export class ReadingRelationshipService {
  static analyze(cards: DrawnCard[], catalog: TarotCard[]): RelationshipInsight {
    const resolved: ResolvedDraw[] = ReadingRelationshipService.resolveCards(cards, catalog);
    const patterns: RelationshipPattern[] = [];
    const descriptions: string[] = [];

    const orientationText: string = ReadingRelationshipService.orientationTurnText(resolved);
    if (orientationText.length > 0) {
      patterns.push('orientation_turn');
      descriptions.push(orientationText);
    }

    const suitText: string = ReadingRelationshipService.suitClusterText(resolved);
    if (suitText.length > 0) {
      patterns.push('suit_cluster');
      descriptions.push(suitText);
    }

    const majorText: string = ReadingRelationshipService.majorFocusText(resolved);
    if (majorText.length > 0) {
      patterns.push('major_focus');
      descriptions.push(majorText);
    }

    const elementText: string = ReadingRelationshipService.elementSupportText(resolved);
    if (elementText.length > 0) {
      patterns.push('element_support');
      descriptions.push(elementText);
    }

    if (patterns.length === 0) {
      patterns.push('neutral_sequence');
      descriptions.push(ReadingRelationshipService.neutralText(resolved));
    }

    return { patterns: patterns, text: descriptions.join('') };
  }

  private static resolveCards(cards: DrawnCard[], catalog: TarotCard[]): ResolvedDraw[] {
    const resolved: ResolvedDraw[] = [];
    for (let index: number = 0; index < cards.length; index++) {
      const drawn: DrawnCard = cards[index];
      const card: TarotCard | undefined = catalog.find(
        (item: TarotCard): boolean => item.id === drawn.cardId
      );
      if (card === undefined) {
        throw new Error(`找不到牌：${drawn.cardId}`);
      }
      resolved.push({ drawn: drawn, card: card });
    }
    return resolved;
  }

  private static orientationTurnText(cards: ResolvedDraw[]): string {
    for (let index: number = 1; index < cards.length; index++) {
      const previous: ResolvedDraw = cards[index - 1];
      const current: ResolvedDraw = cards[index];
      if (previous.drawn.orientation !== current.drawn.orientation) {
        const previousKeyword: string = ReadingRelationshipService.keywordFor(previous);
        const currentKeyword: string = ReadingRelationshipService.keywordFor(current);
        return `从${previous.drawn.position}的${previous.card.nameZhCn}${ReadingRelationshipService.orientationLabel(previous.drawn)}` +
          `“${previousKeyword}”转向${current.drawn.position}的${current.card.nameZhCn}` +
          `${ReadingRelationshipService.orientationLabel(current.drawn)}“${currentKeyword}”，` +
          `这一视角变化可以作为梳理状态转折的线索。`;
      }
    }
    return '';
  }

  private static suitClusterText(cards: ResolvedDraw[]): string {
    for (let index: number = 0; index < cards.length; index++) {
      const arcana: string = cards[index].card.arcana;
      if (arcana === 'major') {
        continue;
      }
      const matched: ResolvedDraw[] = [];
      for (let candidateIndex: number = 0; candidateIndex < cards.length; candidateIndex++) {
        const candidate: ResolvedDraw = cards[candidateIndex];
        if (candidate.card.arcana === arcana) {
          matched.push(candidate);
        }
      }
      if (matched.length >= 2) {
        const first: ResolvedDraw = matched[0];
        const second: ResolvedDraw = matched[1];
        return `${ReadingRelationshipService.suitLabel(arcana)}在${first.drawn.position}的${first.card.nameZhCn}` +
          `和${second.drawn.position}的${second.card.nameZhCn}重复出现，` +
          `让“${ReadingRelationshipService.keywordFor(first)}”与` +
          `“${ReadingRelationshipService.keywordFor(second)}”成为可以一起观察的主题。`;
      }
    }
    return '';
  }

  private static majorFocusText(cards: ResolvedDraw[]): string {
    const majors: ResolvedDraw[] = [];
    for (let index: number = 0; index < cards.length; index++) {
      if (cards[index].card.arcana === 'major') {
        majors.push(cards[index]);
      }
    }
    if (majors.length < 2 || majors.length * 2 < cards.length) {
      return '';
    }
    const names: string[] = [];
    for (let index: number = 0; index < majors.length; index++) {
      const item: ResolvedDraw = majors[index];
      names.push(`${item.drawn.position}的${item.card.nameZhCn}`);
    }
      return `高层主题集中在${names.join('、')}，` +
      `可以把这些卡片的象征作为长期主题来反思，再回到当下可调整的现实环节。`;
  }

  private static elementSupportText(cards: ResolvedDraw[]): string {
    for (let index: number = 1; index < cards.length; index++) {
      const previous: ResolvedDraw = cards[index - 1];
      const current: ResolvedDraw = cards[index];
      if (ReadingRelationshipService.elementsSupport(previous.card.element, current.card.element)) {
        return `${previous.drawn.position}的${previous.card.nameZhCn}` +
          `与${current.drawn.position}的${current.card.nameZhCn}相邻呼应，` +
          `可以同时整理“${ReadingRelationshipService.keywordFor(previous)}”和` +
          `“${ReadingRelationshipService.keywordFor(current)}”如何互相支持。`;
      }
    }
    return '';
  }

  private static neutralText(cards: ResolvedDraw[]): string {
    if (cards.length === 0) {
      return '当前没有足够的卡片信息形成可靠关系，可先保留中性观察。';
    }
    if (cards.length === 1) {
      const only: ResolvedDraw = cards[0];
      return `${only.drawn.position}的${only.card.nameZhCn}先把注意力带向` +
        `“${ReadingRelationshipService.keywordFor(only)}”，单张牌不代表确定结果。`;
    }
    const first: ResolvedDraw = cards[0];
    const last: ResolvedDraw = cards[cards.length - 1];
    return `从${first.drawn.position}的${first.card.nameZhCn}“${ReadingRelationshipService.keywordFor(first)}”` +
      `到${last.drawn.position}的${last.card.nameZhCn}“${ReadingRelationshipService.keywordFor(last)}”，` +
      `目前没有形成更可靠的集中或转折关系；这是整理顺序的线索，不代表确定因果或预测。`;
  }

  private static keywordFor(item: ResolvedDraw): string {
    const side: TarotMeaningSide = item.drawn.orientation === 'upright'
      ? item.card.upright
      : item.card.reversed;
    return side.keywords.length > 0 ? side.keywords[0] : item.card.symbolism;
  }

  private static orientationLabel(drawn: DrawnCard): string {
      return drawn.orientation === 'upright' ? '正向视角' : '侧向视角';
  }

  private static suitLabel(arcana: string): string {
    if (arcana === 'cups') {
      return '主题集合 C';
    }
    if (arcana === 'wands') {
      return '主题集合 B';
    }
    if (arcana === 'swords') {
      return '主题集合 D';
    }
    if (arcana === 'pentacles') {
      return '主题集合 E';
    }
      return '主题集合';
  }

  private static elementsSupport(first: string, second: string): boolean {
    return (first === '火' && second === '风') ||
      (first === '风' && second === '火') ||
      (first === '水' && second === '土') ||
      (first === '土' && second === '水');
  }
}
