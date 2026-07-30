export class LocalDataCodec {
  private static readonly SEPARATOR: string = '\u001F';

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
}

