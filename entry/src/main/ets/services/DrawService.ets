import { DrawnCard, Orientation } from '../models/TarotModels';

export class DrawService {
  static drawSingle(
    cardIds: string[],
    reversalsEnabled: boolean,
    random: () => number = Math.random
  ): DrawnCard {
    if (cardIds.length === 0) {
      throw new Error('牌库不能为空');
    }
    const index: number = Math.min(
      cardIds.length - 1,
      Math.floor(Math.max(0, random()) * cardIds.length)
    );
    const orientation: Orientation = DrawService.orientation(reversalsEnabled, random);
    return {
      cardId: cardIds[index],
      orientation,
      position: '核心提示'
    };
  }

  static drawThree(
    cardIds: string[],
    reversalsEnabled: boolean,
    random: () => number = Math.random
  ): DrawnCard[] {
    if (cardIds.length < 3) {
      throw new Error('三牌阵至少需要三张牌');
    }
    const available: string[] = cardIds.slice();
    const positions: string[] = ['过去', '现在', '行动建议'];
    const result: DrawnCard[] = [];
    positions.forEach((position: string): void => {
      const index: number = Math.min(
        available.length - 1,
        Math.floor(Math.max(0, random()) * available.length)
      );
      const cardId: string = available.splice(index, 1)[0];
      result.push({
        cardId,
        orientation: DrawService.orientation(reversalsEnabled, random),
        position
      });
    });
    return result;
  }

  static dailyDraw(
    cardIds: string[],
    localDateKey: string,
    reversalsEnabled: boolean
  ): DrawnCard {
    if (cardIds.length === 0) {
      throw new Error('牌库不能为空');
    }
    const hash: number = DrawService.hash(localDateKey);
    const index: number = hash % cardIds.length;
    const orientation: Orientation =
      reversalsEnabled && ((Math.floor(hash / cardIds.length) % 2) === 1)
        ? 'reversed'
        : 'upright';
    return {
      cardId: cardIds[index],
      orientation,
      position: '今日灵感'
    };
  }

  private static orientation(
    reversalsEnabled: boolean,
    random: () => number
  ): Orientation {
    if (!reversalsEnabled) {
      return 'upright';
    }
    return random() >= 0.5 ? 'reversed' : 'upright';
  }

  private static hash(value: string): number {
    let hash: number = 2166136261;
    for (let index: number = 0; index < value.length; index++) {
      hash ^= value.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }
}

