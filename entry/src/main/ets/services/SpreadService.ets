import { SpreadType } from '../models/TarotModels';

export interface SpreadDefinition {
  id: SpreadType;
  positions: string[];
  isFree: boolean;
}

export class SpreadService {
  static all(): SpreadDefinition[] {
    return [
      { id: 'single', positions: ['核心提示'], isFree: true },
      { id: 'timeline', positions: ['过去', '现在', '未来趋势'], isFree: true },
      { id: 'relationship', positions: ['我的状态', '对方或外部状态', '关系核心'], isFree: true },
      {
        id: 'seven',
        positions: ['当前状态', '问题根源', '已知资源', '隐藏影响', '当前阻碍', '行动建议', '发展趋势'],
        isFree: true
      }
    ];
  }

  static byId(id: SpreadType): SpreadDefinition {
    const spread: SpreadDefinition | undefined = SpreadService.all()
      .find((item: SpreadDefinition): boolean => item.id === id);
    return spread ?? SpreadService.all()[0];
  }
}
