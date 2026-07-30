export type QuestionCategory =
  'relationship' |
  'workStudy' |
  'decision' |
  'emotion' |
  'growth' |
  'daily';

export type Orientation = 'upright' | 'reversed';

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

