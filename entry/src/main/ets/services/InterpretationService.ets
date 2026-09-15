import {
  CardReadingSection,
  ClarificationImpactType,
  ClarificationReading,
  DrawnCard,
  Orientation,
  ReadingContext,
  ReadingScene,
  ReadingResult,
  TarotCard,
  TarotMeaningSide
} from '../models/TarotModels';
import { StoredReadingRecord } from '../repositories/LocalDataCodec';
import { SafetyService } from './SafetyService';
import { QuestionClassifier } from './QuestionClassifier';
import { SceneKnowledgeService, SceneLens } from './SceneKnowledgeService';
import { ReadingRelationshipService, RelationshipInsight } from './ReadingRelationshipService';

export class InterpretationService {
  static build(context: ReadingContext, catalog: TarotCard[]): ReadingResult {
    const selectedScene: ReadingScene = context.scene ??
      InterpretationService.sceneFromCategory(context.category);
    const scene: ReadingScene = QuestionClassifier.sceneFor(context.question, selectedScene);
    const lens: SceneLens = SceneKnowledgeService.forScene(scene);
    const questionFocus: string = SceneKnowledgeService.questionFocus(context.question, scene);
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
            `回应“${questionFocus}”，${drawn.position}位置的${card.nameZhCn}把注意力带向` +
            `${side.keywords.slice(0, 3).join('、')}。${side.meaning}` +
            `${InterpretationService.strengthText(side, lens)}` +
            `${InterpretationService.challengeText(side, lens)}`
          )
        };
      }
    );

    const primaryDraw: DrawnCard = context.cards[0];
    const primaryCard: TarotCard = InterpretationService.requireCard(primaryDraw.cardId, catalog);
    const primarySide: TarotMeaningSide =
      primaryDraw.orientation === 'upright' ? primaryCard.upright : primaryCard.reversed;
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
      `围绕“${questionFocus}”这件事，在${lens.focus}上，${primaryCard.nameZhCn}邀请你先关注` +
      `“${primarySide.keywords[0]}”。你已经拥有${lens.strength}，同时也有可调整的空间：` +
      `留意${lens.caution}。${moodText}${recentText}${supplementText}`
    );
    const relationship: RelationshipInsight | undefined = sections.length > 1
      ? ReadingRelationshipService.analyze(context.cards, catalog)
      : undefined;
    const connection: string | undefined = relationship === undefined
      ? undefined
      : SafetyService.soften(
        `${relationship.text}${context.depth === 'deep'
          ? `结合各个位置，还可以同时整理${lens.strength}、${lens.caution}与实际行动。`
          : ''}` +
        `这些联系用于回应“${questionFocus}”，而不是对现实结果作确定判断。`
      );
    const clarificationReadings: ClarificationReading[] =
      InterpretationService.buildClarifications(context, catalog, sections);
    const notice: string = SafetyService.noticeFor(context.question);
    const result: ReadingResult = {
      summary,
      sections,
      action: SafetyService.soften(`你可以先${lens.actionFrame}。${primarySide.actionSeeds[0]}`),
      reflection: SafetyService.soften(`回到“${questionFocus}”，${primarySide.reflectionSeeds[0]}`),
      algorithmVersion: 3
    };
    if (connection !== undefined) {
      result.connection = connection;
    }
    if (clarificationReadings.length > 0) {
      result.clarificationReadings = clarificationReadings;
    }
    if (notice.length > 0) {
      result.safetyNotice = notice;
    }
    return result;
  }

  static recentThemesFromRecords(
    records: StoredReadingRecord[],
    fallbackKeywords: (cardId: string, orientation: Orientation) => string[]
  ): string[] {
    if (records.length === 0) {
      return [];
    }
    const recent: string[] = [];
    const maxRecords: number = Math.min(5, records.length);
    for (let index: number = 0; index < maxRecords; index++) {
      const record: StoredReadingRecord = records[index];
      if (record.cards.length === 0) {
        continue;
      }
      const sections: CardReadingSection[] = record.result.sections;
      const keywords: string[] = sections.length > 0
        ? sections[0].keywords
        : fallbackKeywords(record.cards[0].cardId, record.cards[0].orientation);
      for (let keywordIndex: number = 0; keywordIndex < keywords.length; keywordIndex++) {
        const keyword: string = keywords[keywordIndex];
        if (keyword.length > 0 && !recent.includes(keyword)) {
          recent.push(keyword);
          if (recent.length >= 3) {
            return recent;
          }
        }
      }
    }
    return recent;
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

  private static buildClarifications(
    context: ReadingContext,
    catalog: TarotCard[],
    mainSections: CardReadingSection[]
  ): ClarificationReading[] {
    const draws: DrawnCard[] = context.clarifications ?? [];
    const readings: ClarificationReading[] = [];
    if (draws.length === 0 || mainSections.length === 0) {
      return readings;
    }
    const questionFocus: string = SceneKnowledgeService.questionFocus(
      context.question,
      context.scene ?? InterpretationService.sceneFromCategory(context.category)
    );
    let target: CardReadingSection = mainSections[mainSections.length - 1];
    for (let sectionIndex: number = 0; sectionIndex < mainSections.length; sectionIndex++) {
      if (mainSections[sectionIndex].orientation === 'reversed') {
        target = mainSections[sectionIndex];
        break;
      }
    }
    for (let index: number = 0; index < draws.length; index++) {
      const draw: DrawnCard = draws[index];
      const card: TarotCard = InterpretationService.requireCard(draw.cardId, catalog);
      const side: TarotMeaningSide = draw.orientation === 'upright' ? card.upright : card.reversed;
      const impactType: ClarificationImpactType = index === 0
        ? InterpretationService.impactType(target, draw, card, catalog)
        : InterpretationService.followingImpactType(draws[index - 1], draw, catalog);
      const orientationLabel: string = draw.orientation === 'upright' ? '正向视角' : '侧向视角';
      const seedIndex: number = InterpretationService.stableIndex(
        `${questionFocus}:${draw.cardId}:${draw.orientation}:${index}`,
        side.actionSeeds.length
      );
      const focus: string = index === 0
        ? `进一步澄清${target.position}中“${target.keywords[0]}”与当前问题的关系。`
        : `继续澄清上一张牌留下的方向，并检查它如何回应“${questionFocus}”。`;
      const impact: string = index === 0
        ? InterpretationService.firstImpactText(impactType, card.nameZhCn, target)
        : InterpretationService.followingImpactText(impactType, card.nameZhCn);
      readings.push({
        cardId: card.id,
        cardName: card.nameZhCn,
        orientation: draw.orientation,
        index: index + 1,
        focus: SafetyService.soften(focus),
        meaning: SafetyService.soften(
          `围绕“${questionFocus}”，${card.nameZhCn}${orientationLabel}提示` +
          `${side.keywords.slice(0, 3).join('、')}。${side.meaning}`
        ),
        impactType,
        impact: SafetyService.soften(impact),
        action: SafetyService.soften(side.actionSeeds[seedIndex])
      });
    }
    return readings;
  }

  private static impactType(
    target: CardReadingSection,
    clarification: DrawnCard,
    card: TarotCard,
    catalog: TarotCard[]
  ): ClarificationImpactType {
    if (clarification.orientation === 'reversed') {
      return 'caution';
    }
    if (target.orientation !== clarification.orientation) {
      return 'adjust';
    }
    const targetCard: TarotCard = InterpretationService.requireCard(target.cardId, catalog);
    if (targetCard.arcana === card.arcana || targetCard.element === card.element) {
      return 'reinforce';
    }
    return 'supplement';
  }

  private static firstImpactText(
    impactType: ClarificationImpactType,
    cardName: string,
    target: CardReadingSection
  ): string {
    if (impactType === 'reinforce') {
      return `${cardName}强化了${target.cardName}已经指出的主题，可以把两张牌放在一起理解。`;
    }
    if (impactType === 'caution') {
      return `${cardName}补充了一项需要留意的阻碍，让原解读在行动前多一次检查。`;
    }
    if (impactType === 'adjust') {
      return `${cardName}调整了原解读的侧重点，提醒你不要只沿着单一方向理解。`;
    }
    return `${cardName}为${target.cardName}补充了新的现实角度，但不推翻原有提示。`;
  }

  private static followingImpactType(
    previous: DrawnCard,
    current: DrawnCard,
    catalog: TarotCard[]
  ): ClarificationImpactType {
    if (current.orientation === 'reversed') {
      return 'caution';
    }
    if (previous.orientation !== current.orientation) {
      return 'adjust';
    }
    const previousCard: TarotCard = InterpretationService.requireCard(previous.cardId, catalog);
    const currentCard: TarotCard = InterpretationService.requireCard(current.cardId, catalog);
    if (previousCard.arcana === currentCard.arcana || previousCard.element === currentCard.element) {
      return 'reinforce';
    }
    return 'supplement';
  }

  private static followingImpactText(
    impactType: ClarificationImpactType,
    cardName: string
  ): string {
    if (impactType === 'reinforce') {
      return `${cardName}与上一张澄清牌形成强化关系，让共同主题更清晰。`;
    }
    if (impactType === 'caution') {
      return `${cardName}在上一张澄清牌之后增加提醒，需要先检查阻碍再行动。`;
    }
    if (impactType === 'adjust') {
      return `${cardName}对上一张澄清牌作出调整，邀请你同时保留另一种理解。`;
    }
    return `${cardName}在上一张澄清牌之外补充新角度，使行动方向更完整。`;
  }

  private static stableIndex(seed: string, length: number): number {
    if (length <= 1) {
      return 0;
    }
    let value: number = 0;
    for (let index: number = 0; index < seed.length; index++) {
      value = (value * 31 + seed.charCodeAt(index)) % 2147483647;
    }
    return value % length;
  }

  private static strengthText(side: TarotMeaningSide, lens: SceneLens): string {
    const index: number = side.keywords.length > 1 ? 1 : 0;
    return `可以利用“${side.keywords[index]}”以及${lens.strength}。`;
  }

  private static challengeText(side: TarotMeaningSide, lens: SceneLens): string {
    const index: number = side.keywords.length > 2 ? 2 : 0;
    return `需要留意“${side.keywords[index]}”可能与${lens.caution}交织。`;
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

  private static sceneFromCategory(category: string): ReadingScene {
    if (category === 'relationship') {
      return 'relationship';
    }
    if (category === 'workStudy') {
      return 'career';
    }
    if (category === 'growth' || category === 'emotion') {
      return 'growth';
    }
    return 'daily';
  }
}
