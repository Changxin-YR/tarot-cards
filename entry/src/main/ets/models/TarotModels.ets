export type QuestionCategory =
  'relationship' |
  'workStudy' |
  'decision' |
  'emotion' |
  'growth' |
  'daily';

export type Orientation = 'upright' | 'reversed';

export type TarotThemeId = 'moon_garden' | 'stained_glass';

export type SpreadType = 'single' | 'timeline' | 'relationship' | 'seven';

export type ReadingDepth = 'concise' | 'deep';

export type ReadingScene = 'study' | 'career' | 'relationship' | 'social' | 'growth' | 'daily';

export type ReadingFlowStep = 'question' | 'spread' | 'draw' | 'confirm' | 'result';

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

export interface ReadingResult {
  summary: string;
  sections: CardReadingSection[];
  connection?: string;
  action: string;
  reflection: string;
  safetyNotice?: string;
  algorithmVersion: number;
}
