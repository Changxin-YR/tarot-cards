import { DrawnCard, Orientation, ReadingDepth, ReadingScene, TarotThemeId } from '../models/TarotModels';

export interface StoredCardNote {
  cardId: string;
  content: string;
}

export interface StoredReadingRecord {
  id: string;
  createdAt: number;
  question: string;
  scene: ReadingScene;
  depth: ReadingDepth;
  spreadType: string;
  themeId: TarotThemeId;
  cards: DrawnCard[];
  summary: string;
}

export class LocalDataCodec {
  private static readonly SEPARATOR: string = '';
  private static readonly FIELD_SEPARATOR: string = '';
  private static readonly RECORD_SEPARATOR: string = '';
  private static readonly RECORD_FIELD_SEPARATOR: string = '';
  private static readonly CARD_SEPARATOR: string = '';
  private static readonly CARD_FIELD_SEPARATOR: string = '';

  static encodeHistory(items: string[]): string {
    return items
      .map((item: string): string => item.split(LocalDataCodec.SEPARATOR).join(' '))
      .join(LocalDataCodec.SEPARATOR);
  }

  static decodeHistory(value: string): string[] {
    if (value.length === 0) {
      return [];
    }
    return value
      .split(LocalDataCodec.SEPARATOR)
      .filter((item: string): boolean => item.trim().length > 0);
  }

  static encodeFavorites(cardIds: string[]): string {
    return LocalDataCodec.encodeHistory(cardIds);
  }

  static decodeFavorites(value: string): string[] {
    return LocalDataCodec.decodeHistory(value);
  }

  static encodeNotes(notes: StoredCardNote[]): string {
    return notes
      .map((note: StoredCardNote): string => {
        const cardId: string = LocalDataCodec.sanitize(note.cardId);
        const content: string = LocalDataCodec.sanitize(note.content);
        return `${cardId}${LocalDataCodec.FIELD_SEPARATOR}${content}`;
      })
      .join(LocalDataCodec.SEPARATOR);
  }

  static decodeNotes(value: string): StoredCardNote[] {
    if (value.length === 0) {
      return [];
    }
    const notes: StoredCardNote[] = [];
    value.split(LocalDataCodec.SEPARATOR).forEach((record: string): void => {
      const separatorIndex: number = record.indexOf(LocalDataCodec.FIELD_SEPARATOR);
      if (separatorIndex <= 0) {
        return;
      }
      const cardId: string = record.slice(0, separatorIndex);
      const content: string = record.slice(separatorIndex + 1);
      if (cardId.length > 0 && content.trim().length > 0) {
        notes.push({ cardId, content });
      }
    });
    return notes;
  }

  static encodeRecords(records: StoredReadingRecord[]): string {
    return records.map((record: StoredReadingRecord): string => {
      const cards: string = record.cards.map((card: DrawnCard): string => [
        LocalDataCodec.sanitizeRecord(card.cardId),
        card.orientation,
        LocalDataCodec.sanitizeRecord(card.position)
      ].join(LocalDataCodec.CARD_FIELD_SEPARATOR)).join(LocalDataCodec.CARD_SEPARATOR);
      return [
        LocalDataCodec.sanitizeRecord(record.id),
        record.createdAt.toString(),
        LocalDataCodec.sanitizeRecord(record.question),
        record.scene,
        record.depth,
        LocalDataCodec.sanitizeRecord(record.spreadType),
        record.themeId,
        cards,
        LocalDataCodec.sanitizeRecord(record.summary)
      ].join(LocalDataCodec.RECORD_FIELD_SEPARATOR);
    }).join(LocalDataCodec.RECORD_SEPARATOR);
  }

  static decodeRecords(value: string): StoredReadingRecord[] {
    if (value.length === 0) {
      return [];
    }
    const records: StoredReadingRecord[] = [];
    value.split(LocalDataCodec.RECORD_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.RECORD_FIELD_SEPARATOR);
      if ((fields.length !== 7 && fields.length !== 9) || fields[0].length === 0) {
        return;
      }
      const isV2: boolean = fields.length === 9;
      const cardFieldIndex: number = isV2 ? 7 : 5;
      const cards: DrawnCard[] = LocalDataCodec.decodeRecordCards(fields[cardFieldIndex]);
      if (cards.length === 0) {
        return;
      }
      const createdAt: number = Number(fields[1]);
      records.push({
        id: fields[0],
        createdAt: Number.isFinite(createdAt) ? createdAt : 0,
        question: fields[2],
        scene: isV2 ? LocalDataCodec.scene(fields[3]) : 'growth',
        depth: isV2 && fields[4] === 'deep' ? 'deep' : 'concise',
        spreadType: fields[isV2 ? 5 : 3],
        themeId: fields[isV2 ? 6 : 4] === 'stained_glass' ? 'stained_glass' : 'moon_garden',
        cards,
        summary: fields[isV2 ? 8 : 6]
      });
    });
    return records;
  }

  private static decodeRecordCards(value: string): DrawnCard[] {
    const cards: DrawnCard[] = [];
    value.split(LocalDataCodec.CARD_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.CARD_FIELD_SEPARATOR);
      if (fields.length !== 3 || fields[0].length === 0) {
        return;
      }
      const orientation: Orientation = fields[1] === 'reversed' ? 'reversed' : 'upright';
      cards.push({ cardId: fields[0], orientation, position: fields[2] });
    });
    return cards;
  }

  private static scene(value: string): ReadingScene {
    if (value === 'study' || value === 'career' || value === 'relationship' || value === 'social' || value === 'daily') {
      return value;
    }
    return 'growth';
  }

  private static sanitize(value: string): string {
    return value
      .split(LocalDataCodec.SEPARATOR).join(' ')
      .split(LocalDataCodec.FIELD_SEPARATOR).join(' ');
  }

  private static sanitizeRecord(value: string): string {
    return value
      .split(LocalDataCodec.RECORD_SEPARATOR).join(' ')
      .split(LocalDataCodec.RECORD_FIELD_SEPARATOR).join(' ')
      .split(LocalDataCodec.CARD_SEPARATOR).join(' ')
      .split(LocalDataCodec.CARD_FIELD_SEPARATOR).join(' ');
  }
}
