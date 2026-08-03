export class ResponsiveLayout {
  static catalogColumns(width: number): number {
    if (width >= 600) {
      return 4;
    }
    return width < 360 ? 2 : 3;
  }

  static selectionColumns(width: number): number {
    return width >= 600 ? 5 : 4;
  }

  static catalogTemplate(width: number): string {
    return ResponsiveLayout.template(ResponsiveLayout.catalogColumns(width));
  }

  static selectionTemplate(width: number): string {
    return ResponsiveLayout.template(ResponsiveLayout.selectionColumns(width));
  }

  private static template(columns: number): string {
    const tracks: string[] = [];
    for (let index: number = 0; index < columns; index++) {
      tracks.push('1fr');
    }
    return tracks.join(' ');
  }
}
