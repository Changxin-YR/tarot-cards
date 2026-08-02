export type QuestionCategory =
  'relationship' |
  'workStudy' |
  'decision' |
  'emotion' |
  'growth' |
  'daily';

export type Orientation = 'upright' | 'reversed';

export type TarotThemeId = 'moon_garden' | 'stained_glass';

export type SpreadType = 'single' | 'three' | 'daily' | 'timeline' | 'relationship' | 'seven';

export type ReadingDepth = 'concise' | 'deep';

export type ClarificationImpactType = 'reinforce' | 'supplement' | 'caution' | 'adjust';

export type ReadingScene = 'study' | 'career' | 'relationship' | 'social' | 'growth' | 'daily';

export type ReadingFlowStep = 'question' | 'spread' | 'draw' | 'confirm' | 'result';

export type AppRootPage = 'home' | 'question' | 'catalog' | 'settings';

export type AppPage = AppRootPage | 'drawMode' | 'shuffle' | 'select' | 'reveal' |
  'result' | 'history' | 'cardDetail' | 'about';

export type DrawPhase = 'shuffle' | 'select' | 'reveal' | 'complete';

export interface TarotMeaningSide {
  keywords: string[];
  meaning: string;
  actionSeeds: string[];
  reflectionSeeds: string[];
}

export interface TarotCard {
  id: string;
  nameZhCn: string;
  nameEn: string;
  arcana: string;
  number: number;
  element: string;
  image: string;
  upright: TarotMeaningSide;
  reversed: TarotMeaningSide;
  symbolism: string;
  sourceIds: string[];
}

export interface DrawnCard {
  cardId: string;
  orientation: Orientation;
  position: string;
}

export interface ReadingContext {
  question: string;
  supplement?: string;
  category: QuestionCategory;
  mood?: string;
  recentThemes: string[];
  cards: DrawnCard[];
  clarifications?: DrawnCard[];
  scene?: ReadingScene;
  depth?: ReadingDepth;
}

export interface CardReadingSection {
  cardId: string;
  cardName: string;
  orientation: Orientation;
  position: string;
  keywords: string[];
  meaning: string;
}

export interface ClarificationReading {
  cardId: string;
  cardName: string;
  orientation: Orientation;
  index: number;
  focus: string;
  meaning: string;
  impactType: ClarificationImpactType;
  impact: string;
  action: string;
}

export interface ReadingResult {
  summary: string;
  sections: CardReadingSection[];
  connection?: string;
  action: string;
  reflection: string;
  clarificationReadings?: ClarificationReading[];
  safetyNotice?: string;
  algorithmVersion: number;
}
