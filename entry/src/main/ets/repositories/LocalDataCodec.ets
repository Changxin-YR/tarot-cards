export interface StoredCardNote {
  cardId: string;
  content: string;
}

export class LocalDataCodec {
  private static readonly SEPARATOR: string = '';
  private static readonly FIELD_SEPARATOR: string = '';

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

  private static sanitize(value: string): string {
    return value
      .split(LocalDataCodec.SEPARATOR).join(' ')
      .split(LocalDataCodec.FIELD_SEPARATOR).join(' ');
  }
}
