import {
  CardReadingSection,
  DrawnCard,
  Orientation,
  ReadingDepth,
  ReadingResult,
  ReadingScene,
  TarotThemeId
} from '../models/TarotModels';

export interface StoredCardNote {
  cardId: string;
  content: string;
}

export interface StoredReadingRecord {
  schemaVersion: number;
  id: string;
  createdAt: number;
  question: string;
  mood: string;
  scene: ReadingScene;
  depth: ReadingDepth;
  spreadType: string;
  themeId: TarotThemeId;
  cards: DrawnCard[];
  clarifications: DrawnCard[];
  result: ReadingResult;
  note: string;
  favorite: boolean;
}

export interface StoredReadingCollections {
  records: StoredReadingRecord[];
  history: string[];
}

export class LocalDataCodec {
  private static readonly RECORD_VERSION_PREFIX: string = 'TR3:';
  private static readonly COLLECTION_VERSION_PREFIX: string = 'TRC1:';
  private static readonly COLLECTION_SEPARATOR: string = '|~H~|';
  private static readonly SEPARATOR: string = '';
  private static readonly FIELD_SEPARATOR: string = '';
  private static readonly RECORD_SEPARATOR: string = '|~R~|';
  private static readonly RECORD_FIELD_SEPARATOR: string = '|~F~|';
  private static readonly CARD_SEPARATOR: string = '|~C~|';
  private static readonly CARD_FIELD_SEPARATOR: string = '|~P~|';
  private static readonly SECTION_SEPARATOR: string = '|~S~|';
  private static readonly SECTION_FIELD_SEPARATOR: string = '|~Q~|';
  private static readonly KEYWORD_SEPARATOR: string = '|~K~|';
  private static readonly LEGACY_RECORD_SEPARATOR: string = '';
  private static readonly LEGACY_RECORD_FIELD_SEPARATOR: string = '';
  private static readonly LEGACY_CARD_SEPARATOR: string = '';
  private static readonly LEGACY_CARD_FIELD_SEPARATOR: string = '';

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
    if (records.length === 0) {
      return '';
    }
    const rows: string = records.map((record: StoredReadingRecord): string => {
      return [
        LocalDataCodec.encodeValue(record.id),
        record.createdAt.toString(),
        LocalDataCodec.encodeValue(record.question),
        LocalDataCodec.encodeValue(record.mood),
        record.scene,
        record.depth,
        LocalDataCodec.encodeValue(record.spreadType),
        record.themeId,
        LocalDataCodec.encodeRecordCards(record.cards),
        LocalDataCodec.encodeRecordCards(record.clarifications),
        LocalDataCodec.encodeValue(record.result.summary),
        LocalDataCodec.encodeValue(record.result.connection ?? ''),
        LocalDataCodec.encodeValue(record.result.action),
        LocalDataCodec.encodeValue(record.result.reflection),
        LocalDataCodec.encodeValue(record.result.safetyNotice ?? ''),
        record.result.algorithmVersion.toString(),
        LocalDataCodec.encodeSections(record.result.sections),
        LocalDataCodec.encodeValue(record.note),
        record.favorite ? '1' : '0'
      ].join(LocalDataCodec.RECORD_FIELD_SEPARATOR);
    }).join(LocalDataCodec.RECORD_SEPARATOR);
    return `${LocalDataCodec.RECORD_VERSION_PREFIX}${rows}`;
  }

  static decodeRecords(value: string): StoredReadingRecord[] {
    if (value.length === 0) {
      return [];
    }
    if (value.startsWith(LocalDataCodec.RECORD_VERSION_PREFIX)) {
      return LocalDataCodec.decodeVersion3Strict(value.slice(LocalDataCodec.RECORD_VERSION_PREFIX.length));
    }
    if (value.includes(LocalDataCodec.LEGACY_RECORD_FIELD_SEPARATOR)) {
      return LocalDataCodec.decodeLegacyRecords(
        value,
        LocalDataCodec.LEGACY_RECORD_SEPARATOR,
        LocalDataCodec.LEGACY_RECORD_FIELD_SEPARATOR,
        LocalDataCodec.LEGACY_CARD_SEPARATOR,
        LocalDataCodec.LEGACY_CARD_FIELD_SEPARATOR
      );
    }
    return LocalDataCodec.decodeLegacyRecords(
      value,
      LocalDataCodec.RECORD_SEPARATOR,
      LocalDataCodec.RECORD_FIELD_SEPARATOR,
      LocalDataCodec.CARD_SEPARATOR,
      LocalDataCodec.CARD_FIELD_SEPARATOR
    );
  }

  static encodeReadingCollections(collections: StoredReadingCollections): string {
    const records: string = LocalDataCodec.encodeValue(LocalDataCodec.encodeRecords(collections.records));
    const history: string = LocalDataCodec.encodeValue(LocalDataCodec.encodeHistory(collections.history));
    return `${LocalDataCodec.COLLECTION_VERSION_PREFIX}${records}${LocalDataCodec.COLLECTION_SEPARATOR}${history}`;
  }

  static decodeReadingCollections(value: string): StoredReadingCollections {
    if (!value.startsWith(LocalDataCodec.COLLECTION_VERSION_PREFIX)) {
      throw new Error('Unsupported reading collections format.');
    }
    const payload: string = value.slice(LocalDataCodec.COLLECTION_VERSION_PREFIX.length);
    const separatorIndex: number = payload.indexOf(LocalDataCodec.COLLECTION_SEPARATOR);
    if (separatorIndex < 0) {
      throw new Error('Malformed reading collections payload.');
    }
    const recordsValue: string = LocalDataCodec.decodeRequiredValue(payload.slice(0, separatorIndex));
    const historyValue: string = LocalDataCodec.decodeRequiredValue(
      payload.slice(separatorIndex + LocalDataCodec.COLLECTION_SEPARATOR.length)
    );
    if (recordsValue.length > 0 && !recordsValue.startsWith(LocalDataCodec.RECORD_VERSION_PREFIX)) {
      throw new Error('Malformed reading records payload.');
    }
    const records: StoredReadingRecord[] = recordsValue.length === 0 ? [] :
      LocalDataCodec.decodeVersion3Strict(recordsValue.slice(LocalDataCodec.RECORD_VERSION_PREFIX.length));
    return {
      records,
      history: LocalDataCodec.decodeHistory(historyValue)
    };
  }

  private static decodeVersion3Strict(value: string): StoredReadingRecord[] {
    if (value.length === 0) {
      throw new Error('Malformed empty reading records payload.');
    }
    value.split(LocalDataCodec.RECORD_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.RECORD_FIELD_SEPARATOR);
      if (fields.length !== 19 ||
        !LocalDataCodec.isUnsignedInteger(fields[1]) ||
        !LocalDataCodec.isUnsignedInteger(fields[15]) ||
        (fields[4] !== 'study' && fields[4] !== 'career' && fields[4] !== 'relationship' &&
          fields[4] !== 'social' && fields[4] !== 'daily' && fields[4] !== 'growth') ||
        (fields[5] !== 'concise' && fields[5] !== 'deep') ||
        (fields[7] !== 'moon_garden' && fields[7] !== 'stained_glass') ||
        (fields[18] !== '0' && fields[18] !== '1')) {
        throw new Error('Malformed reading record row.');
      }
      const id: string = LocalDataCodec.decodeRequiredValue(fields[0]);
      const spreadType: string = LocalDataCodec.decodeRequiredValue(fields[6]);
      if (id.length === 0 || spreadType.length === 0) {
        throw new Error('Malformed required reading record field.');
      }
      [2, 3, 10, 11, 12, 13, 14, 17].forEach((index: number): void => {
        LocalDataCodec.decodeRequiredValue(fields[index]);
      });
      LocalDataCodec.validateEncodedCards(fields[8], false);
      LocalDataCodec.validateEncodedCards(fields[9], true);
      LocalDataCodec.validateEncodedSections(fields[16]);
    });
    return LocalDataCodec.decodeVersion3(value);
  }

  private static validateEncodedCards(value: string, allowEmpty: boolean): void {
    if (value.length === 0) {
      if (allowEmpty) {
        return;
      }
      throw new Error('Reading record has no primary cards.');
    }
    value.split(LocalDataCodec.CARD_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.CARD_FIELD_SEPARATOR);
      if (fields.length !== 3 || (fields[1] !== 'upright' && fields[1] !== 'reversed')) {
        throw new Error('Malformed reading card row.');
      }
      const cardId: string = LocalDataCodec.decodeRequiredValue(fields[0]);
      LocalDataCodec.decodeRequiredValue(fields[2]);
      if (cardId.length === 0) {
        throw new Error('Malformed reading card ID.');
      }
    });
  }

  private static validateEncodedSections(value: string): void {
    if (value.length === 0) {
      return;
    }
    value.split(LocalDataCodec.SECTION_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.SECTION_FIELD_SEPARATOR);
      if (fields.length !== 6 || (fields[2] !== 'upright' && fields[2] !== 'reversed')) {
        throw new Error('Malformed reading section row.');
      }
      [0, 1, 3, 5].forEach((index: number): void => {
        LocalDataCodec.decodeRequiredValue(fields[index]);
      });
      if (fields[4].length > 0) {
        fields[4].split(LocalDataCodec.KEYWORD_SEPARATOR).forEach((keyword: string): void => {
          LocalDataCodec.decodeRequiredValue(keyword);
        });
      }
    });
  }

  private static decodeVersion3(value: string): StoredReadingRecord[] {
    const records: StoredReadingRecord[] = [];
    value.split(LocalDataCodec.RECORD_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.RECORD_FIELD_SEPARATOR);
      if (fields.length !== 19) {
        return;
      }
      const cards: DrawnCard[] = LocalDataCodec.decodeRecordCards(
        fields[8],
        LocalDataCodec.CARD_SEPARATOR,
        LocalDataCodec.CARD_FIELD_SEPARATOR,
        true
      );
      if (cards.length === 0) {
        return;
      }
      const createdAt: number = Number(fields[1]);
      const result: ReadingResult = {
        summary: LocalDataCodec.decodeValue(fields[10]),
        sections: LocalDataCodec.decodeSections(fields[16]),
        action: LocalDataCodec.decodeValue(fields[12]),
        reflection: LocalDataCodec.decodeValue(fields[13]),
        algorithmVersion: LocalDataCodec.finiteNumber(fields[15], 1)
      };
      const connection: string = LocalDataCodec.decodeValue(fields[11]);
      const safetyNotice: string = LocalDataCodec.decodeValue(fields[14]);
      if (connection.length > 0) {
        result.connection = connection;
      }
      if (safetyNotice.length > 0) {
        result.safetyNotice = safetyNotice;
      }
      records.push({
        schemaVersion: 3,
        id: LocalDataCodec.decodeValue(fields[0]),
        createdAt: Number.isFinite(createdAt) ? createdAt : 0,
        question: LocalDataCodec.decodeValue(fields[2]),
        mood: LocalDataCodec.decodeValue(fields[3]),
        scene: LocalDataCodec.scene(fields[4]),
        depth: fields[5] === 'deep' ? 'deep' : 'concise',
        spreadType: LocalDataCodec.decodeValue(fields[6]),
        themeId: fields[7] === 'stained_glass' ? 'stained_glass' : 'moon_garden',
        cards,
        clarifications: LocalDataCodec.decodeRecordCards(
          fields[9],
          LocalDataCodec.CARD_SEPARATOR,
          LocalDataCodec.CARD_FIELD_SEPARATOR,
          true
        ),
        result,
        note: LocalDataCodec.decodeValue(fields[17]),
        favorite: fields[18] === '1'
      });
    });
    return records;
  }

  private static decodeLegacyRecords(
    value: string,
    recordSeparator: string,
    fieldSeparator: string,
    cardSeparator: string,
    cardFieldSeparator: string
  ): StoredReadingRecord[] {
    const records: StoredReadingRecord[] = [];
    value.split(recordSeparator).forEach((row: string): void => {
      const fields: string[] = row.split(fieldSeparator);
      if ((fields.length !== 7 && fields.length !== 9) || fields[0].length === 0) {
        return;
      }
      const isV2: boolean = fields.length === 9;
      const cardFieldIndex: number = isV2 ? 7 : 5;
      const decodedCards: DrawnCard[] = LocalDataCodec.decodeRecordCards(
        fields[cardFieldIndex],
        cardSeparator,
        cardFieldSeparator,
        false
      );
      if (decodedCards.length === 0) {
        return;
      }
      const clarifications: DrawnCard[] = isV2 ? decodedCards.filter(
        (card: DrawnCard): boolean => card.position.startsWith('澄清')
      ) : [];
      const cards: DrawnCard[] = isV2 ? decodedCards.filter(
        (card: DrawnCard): boolean => !card.position.startsWith('澄清')
      ) : decodedCards;
      if (cards.length === 0) {
        return;
      }
      const createdAt: number = Number(fields[1]);
      const summary: string = fields[isV2 ? 8 : 6];
      const result: ReadingResult = {
        summary,
        sections: [],
        action: '',
        reflection: '',
        algorithmVersion: 1
      };
      records.push({
        schemaVersion: 3,
        id: fields[0],
        createdAt: Number.isFinite(createdAt) ? createdAt : 0,
        question: fields[2],
        mood: '',
        scene: isV2 ? LocalDataCodec.scene(fields[3]) : 'growth',
        depth: isV2 && fields[4] === 'deep' ? 'deep' : 'concise',
        spreadType: fields[isV2 ? 5 : 3],
        themeId: fields[isV2 ? 6 : 4] === 'stained_glass' ? 'stained_glass' : 'moon_garden',
        cards,
        clarifications,
        result,
        note: '',
        favorite: false
      });
    });
    return records;
  }

  private static encodeRecordCards(cards: DrawnCard[]): string {
    return cards.map((card: DrawnCard): string => [
      LocalDataCodec.encodeValue(card.cardId),
      card.orientation,
      LocalDataCodec.encodeValue(card.position)
    ].join(LocalDataCodec.CARD_FIELD_SEPARATOR)).join(LocalDataCodec.CARD_SEPARATOR);
  }

  private static decodeRecordCards(
    value: string,
    cardSeparator: string,
    fieldSeparator: string,
    decodeValues: boolean
  ): DrawnCard[] {
    if (value.length === 0) {
      return [];
    }
    const cards: DrawnCard[] = [];
    value.split(cardSeparator).forEach((row: string): void => {
      const fields: string[] = row.split(fieldSeparator);
      if (fields.length !== 3 || fields[0].length === 0) {
        return;
      }
      const orientation: Orientation = fields[1] === 'reversed' ? 'reversed' : 'upright';
      cards.push({
        cardId: decodeValues ? LocalDataCodec.decodeValue(fields[0]) : fields[0],
        orientation,
        position: decodeValues ? LocalDataCodec.decodeValue(fields[2]) : fields[2]
      });
    });
    return cards;
  }

  private static encodeSections(sections: CardReadingSection[]): string {
    return sections.map((section: CardReadingSection): string => [
      LocalDataCodec.encodeValue(section.cardId),
      LocalDataCodec.encodeValue(section.cardName),
      section.orientation,
      LocalDataCodec.encodeValue(section.position),
      section.keywords.map((keyword: string): string => LocalDataCodec.encodeValue(keyword))
        .join(LocalDataCodec.KEYWORD_SEPARATOR),
      LocalDataCodec.encodeValue(section.meaning)
    ].join(LocalDataCodec.SECTION_FIELD_SEPARATOR)).join(LocalDataCodec.SECTION_SEPARATOR);
  }

  private static decodeSections(value: string): CardReadingSection[] {
    if (value.length === 0) {
      return [];
    }
    const sections: CardReadingSection[] = [];
    value.split(LocalDataCodec.SECTION_SEPARATOR).forEach((row: string): void => {
      const fields: string[] = row.split(LocalDataCodec.SECTION_FIELD_SEPARATOR);
      if (fields.length !== 6) {
        return;
      }
      const keywords: string[] = fields[4].length === 0 ? [] : fields[4]
        .split(LocalDataCodec.KEYWORD_SEPARATOR)
        .map((keyword: string): string => LocalDataCodec.decodeValue(keyword));
      sections.push({
        cardId: LocalDataCodec.decodeValue(fields[0]),
        cardName: LocalDataCodec.decodeValue(fields[1]),
        orientation: fields[2] === 'reversed' ? 'reversed' : 'upright',
        position: LocalDataCodec.decodeValue(fields[3]),
        keywords,
        meaning: LocalDataCodec.decodeValue(fields[5])
      });
    });
    return sections;
  }

  private static encodeValue(value: string): string {
    return encodeURIComponent(value);
  }

  private static decodeValue(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch {
      return '';
    }
  }

  private static decodeRequiredValue(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch {
      throw new Error('Malformed encoded local data.');
    }
  }

  private static finiteNumber(value: string, fallback: number): number {
    const parsed: number = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private static isUnsignedInteger(value: string): boolean {
    if (value.length === 0) {
      return false;
    }
    for (let index: number = 0; index < value.length; index += 1) {
      const code: number = value.charCodeAt(index);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return Number.isFinite(Number(value));
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

}
