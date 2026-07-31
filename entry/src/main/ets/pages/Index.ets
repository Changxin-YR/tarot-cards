import { common } from '@kit.AbilityKit';
import { TAROT_CARDS } from '../common/TarotCatalogData';
import { DesignTokens } from '../common/DesignTokens';
import { tarotThemeBack, tarotThemeMedia } from '../common/TarotThemeMedia';
import {
  DrawnCard,
  ReadingDepth,
  ReadingScene,
  ReadingContext,
  ReadingResult,
  TarotCard
} from '../models/TarotModels';
import { TarotThemeId } from '../models/TarotModels';
import { DrawService } from '../services/DrawService';
import { InterpretationService } from '../services/InterpretationService';
import { LocalAppStore, StoredAppData } from '../repositories/LocalAppStore';
import { StoredCardNote, StoredReadingRecord } from '../repositories/LocalDataCodec';
import { QuestionClassifier } from '../services/QuestionClassifier';
import { SpreadService } from '../services/SpreadService';

// Mood options — label resource paired with internal value.
const MOOD_OPTIONS: [Resource, string][] = [
  [$r('app.string.mood_calm'), '平静'],
  [$r('app.string.mood_expectant'), '期待'],
  [$r('app.string.mood_nervous'), '紧张'],
  [$r('app.string.mood_confused'), '困惑'],
  [$r('app.string.mood_low'), '低落'],
];

const SCENE_OPTIONS: [Resource, ReadingScene][] = [
  [$r('app.string.scene_study'), 'study'],
  [$r('app.string.scene_career'), 'career'],
  [$r('app.string.scene_relationship'), 'relationship'],
  [$r('app.string.scene_social'), 'social'],
  [$r('app.string.scene_growth'), 'growth'],
  [$r('app.string.scene_daily'), 'daily'],
];

// Catalog filter tabs — [category key, label resource].
const CATALOG_FILTERS: [string, Resource][] = [
  ['all', $r('app.string.catalog_all')],
  ['favorite', $r('app.string.catalog_favorite')],
  ['major', $r('app.string.catalog_major')],
  ['wands', $r('app.string.catalog_wands')],
  ['cups', $r('app.string.catalog_cups')],
  ['swords', $r('app.string.catalog_swords')],
  ['pentacles', $r('app.string.catalog_pentacles')],
];

@Entry
@Component
struct Index {
  @State page: string = 'home';
  @State spread: string = 'single';
  @State question: string = '';
  @State mood: string = '';
  @State drawn: DrawnCard[] = [];
  @State clarifications: DrawnCard[] = [];
  @State summary: string = '';
  @State connection: string = '';
  @State actionText: string = '';
  @State reflection: string = '';
  @State safetyNotice: string = '';
  @State history: string[] = [];
  @State favorites: string[] = [];
  @State notes: StoredCardNote[] = [];
  @State noteDraft: string = '';
  @State catalogFilter: string = 'all';
  @State searchText: string = '';
  @State selectedCardId: string = '';
  @State reversalsEnabled: boolean = true;
  @State soundEnabled: boolean = true;
  @State hapticEnabled: boolean = true;
  @State recentThemesEnabled: boolean = true;
  @State currentTheme: TarotThemeId = 'moon_garden';
  @State records: StoredReadingRecord[] = [];
  @State currentSaved: boolean = false;
  @State readingScene: ReadingScene = 'growth';
  @State readingDepth: ReadingDepth = 'concise';
  private localStore: LocalAppStore = new LocalAppStore();

  async aboutToAppear(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    try {
      await this.localStore.initialize(context);
      const data: StoredAppData = await this.localStore.load();
      this.history = data.history;
      this.favorites = data.favorites;
      this.notes = data.notes;
      this.reversalsEnabled = data.reversalsEnabled;
      this.soundEnabled = data.soundEnabled;
      this.hapticEnabled = data.hapticEnabled;
      this.recentThemesEnabled = data.recentThemesEnabled;
      this.currentTheme = data.themeId;
      this.records = data.records;
    } catch {
    }
  }

  private filteredCards(): TarotCard[] {
    return TAROT_CARDS.filter((card: TarotCard): boolean => {
      const matchesCategory: boolean =
        this.catalogFilter === 'all' ||
        card.arcana === this.catalogFilter ||
        (this.catalogFilter === 'favorite' && this.favorites.includes(card.id));
      const matchesSearch: boolean =
        this.searchText.trim().length === 0 ||
        card.nameZhCn.includes(this.searchText.trim()) ||
        card.nameEn.toLowerCase().includes(this.searchText.trim().toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }

  private cardById(cardId: string): TarotCard {
    return TAROT_CARDS.find((card: TarotCard): boolean => card.id === cardId) ?? TAROT_CARDS[0];
  }

  private deriveRecentThemes(): string[] {
    if (!this.recentThemesEnabled || this.history.length === 0) {
      return [];
    }
    const recent: string[] = [];
    const maxEntries: number = Math.min(5, this.history.length);
    for (let index: number = 0; index < maxEntries; index++) {
      const entry: string = this.history[index];
      const parts: string[] = entry.split(' · ');
      for (let partIndex: number = 1; partIndex < parts.length; partIndex++) {
        if (!recent.includes(parts[partIndex])) {
          recent.push(parts[partIndex]);
          if (recent.length >= 3) {
            return recent;
          }
        }
      }
    }
    return recent;
  }

  private noteFor(cardId: string): string {
    const note: StoredCardNote | undefined =
      this.notes.find((item: StoredCardNote): boolean => item.cardId === cardId);
    return note?.content ?? '';
  }

  private openCard(cardId: string): void {
    this.selectedCardId = cardId;
    this.noteDraft = this.noteFor(cardId);
  }

  private toggleFavorite(cardId: string): void {
    if (this.favorites.includes(cardId)) {
      this.favorites = this.favorites.filter((item: string): boolean => item !== cardId);
    } else {
      this.favorites = [...this.favorites, cardId];
    }
    this.localStore.saveFavorites(this.favorites).catch((): void => {
    });
  }

  private saveCardNote(cardId: string): void {
    const remaining: StoredCardNote[] =
      this.notes.filter((item: StoredCardNote): boolean => item.cardId !== cardId);
    if (this.noteDraft.trim().length > 0) {
      remaining.push({ cardId, content: this.noteDraft.trim() });
    }
    this.notes = remaining;
    this.localStore.saveNotes(this.notes).catch((): void => {
    });
  }

  private chooseSpread(spread: string): void {
    this.spread = spread;
    this.question = '';
    this.page = 'question';
  }

  private confirmSpread(spread: string): void {
    this.spread = spread;
    this.page = 'shuffle';
  }

  private completeDraw(): void {
    const ids: string[] = TAROT_CARDS.map((card: TarotCard): string => card.id);
    if (this.spread === 'timeline' || this.spread === 'three') {
      this.drawn = DrawService.drawSpread(ids, SpreadService.byId('timeline').positions, this.reversalsEnabled);
    } else if (this.spread === 'relationship') {
      this.drawn = DrawService.drawSpread(ids, SpreadService.byId('relationship').positions, this.reversalsEnabled);
    } else if (this.spread === 'seven') {
      this.drawn = DrawService.drawSpread(ids, SpreadService.byId('seven').positions, this.reversalsEnabled);
    } else if (this.spread === 'daily') {
      const now: Date = new Date();
      const key: string =
        `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
      this.drawn = [DrawService.dailyDraw(ids, key, this.reversalsEnabled)];
    } else {
      this.drawn = [DrawService.drawSingle(ids, this.reversalsEnabled)];
    }
    this.clarifications = [];
    this.currentSaved = false;
    this.updateReading(this.drawn);
    this.page = 'result';
  }

  private updateReading(cards: DrawnCard[]): void {
    const context: ReadingContext = {
      question: this.question,
      category: QuestionClassifier.classify(this.question),
      mood: this.mood,
      recentThemes: this.deriveRecentThemes(),
      cards,
      scene: this.readingScene,
      depth: this.readingDepth
    };
    const result: ReadingResult = InterpretationService.build(context, TAROT_CARDS);
    this.summary = result.summary;
    this.connection = result.connection ?? '';
    this.actionText = result.action;
    this.reflection = result.reflection;
    this.safetyNotice = result.safetyNotice ?? '';
  }

  private addClarification(): void {
    if (this.clarifications.length >= 3) {
      return;
    }
    const ids: string[] = TAROT_CARDS.map((card: TarotCard): string => card.id);
    const excluded: string[] = this.drawn.concat(this.clarifications)
      .map((draw: DrawnCard): string => draw.cardId);
    const next: DrawnCard[] = DrawService.drawClarifications(
      ids,
      excluded,
      1,
      this.reversalsEnabled
    );
    if (next.length === 0) {
      return;
    }
    const clarification: DrawnCard = {
      cardId: next[0].cardId,
      orientation: next[0].orientation,
      position: `澄清 ${this.clarifications.length + 1}`
    };
    this.clarifications = this.clarifications.concat([clarification]);
    this.updateReading(this.drawn.concat(this.clarifications));
  }

  private saveCurrent(): void {
    if (this.currentSaved) {
      return;
    }
    const record: StoredReadingRecord = {
      id: `reading-${Date.now()}`,
      createdAt: Date.now(),
      question: this.question,
      scene: this.readingScene,
      depth: this.readingDepth,
      spreadType: this.spread,
      themeId: this.currentTheme,
      cards: this.drawn.concat(this.clarifications),
      summary: this.summary
    };
    this.records = [record].concat(this.records);
    this.currentSaved = true;
    this.localStore.saveRecords(this.records).catch((): void => {
    });
  }

  // Format the history-count label (e.g. "第 3 次记录").
  private historyCountLabel(index: number): string {
    return `第 ${this.history.length - index} 次记录`;
  }

  @Builder
  Header(title: ResourceStr, showBack: boolean = false) {
    Row() {
      if (showBack) {
        Button($r('app.string.header_back_icon'))
          .type(ButtonType.Normal)
          .width(44)
          .height(44)
          .fontSize(30)
          .fontColor(DesignTokens.GOLD)
          .backgroundColor(Color.Transparent)
          .onClick((): void => {
            this.page = 'home';
            this.selectedCardId = '';
          })
      } else {
        Text($r('app.string.header_moon_icon'))
          .width(44)
          .fontSize(25)
          .fontColor(DesignTokens.GOLD)
      }
      Text(title)
        .layoutWeight(1)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.TEXT)
        .textAlign(TextAlign.Center)
      Button($r('app.string.header_settings_icon'))
        .type(ButtonType.Normal)
        .width(44)
        .height(44)
        .fontSize(19)
        .fontColor(DesignTokens.GOLD)
        .backgroundColor(Color.Transparent)
        .onClick((): void => {
          this.page = 'settings';
        })
    }
    .width('100%')
    .height(58)
  }

  @Builder
  GoldButton(label: ResourceStr, action: () => void) {
    Button(label)
      .width('100%')
      .height(50)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(DesignTokens.TEXT_ON_GOLD)
      .backgroundColor(DesignTokens.GOLD_LIGHT)
      .borderRadius(14)
      .onClick(action)
  }

  @Builder
  NavBar() {
    Row() {
      this.NavItem($r('app.string.nav_home_icon'), $r('app.string.nav_home'), 'home')
      this.NavItem($r('app.string.nav_draw_icon'), $r('app.string.nav_draw'), 'question')
      this.NavItem($r('app.string.nav_catalog_icon'), $r('app.string.nav_catalog'), 'catalog')
      this.NavItem($r('app.string.nav_history_icon'), $r('app.string.nav_history'), 'history')
      this.NavItem($r('app.string.nav_profile_icon'), $r('app.string.nav_profile'), 'settings')
    }
    .width('100%')
    .height(66)
    .padding({ left: 8, right: 8 })
    .backgroundColor(DesignTokens.NAV_BG)
    .border({ width: { top: 1 }, color: DesignTokens.NAV_BORDER })
  }

  @Builder
  NavItem(icon: ResourceStr, label: ResourceStr, target: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(22)
        .fontColor(this.page === target ? DesignTokens.GOLD_LIGHT : DesignTokens.TEXT_SECONDARY)
      Text(label)
        .fontSize(11)
        .fontColor(this.page === target ? DesignTokens.GOLD_LIGHT : DesignTokens.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick((): void => {
      this.page = target;
      this.selectedCardId = '';
    })
  }

  @Builder
  HomePage() {
    Scroll() {
      Column({ space: 16 }) {
        this.Header($r('app.string.app_title'))
        Column({ space: 5 }) {
          Text($r('app.string.greeting'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(DesignTokens.TEXT)
          Text($r('app.string.privacy_local_only'))
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text($r('app.string.daily_draw_title'))
            .fontSize(20)
            .fontColor(DesignTokens.GOLD_LIGHT)
          Text($r('app.string.daily_draw_hint'))
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
          Image(tarotThemeBack(this.currentTheme))
            .width(132)
            .height(198)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .shadow({ radius: 18, color: DesignTokens.CARD_SHADOW })
          Button($r('app.string.draw_one_card_btn'))
            .width(190)
            .height(46)
            .fontColor(DesignTokens.TEXT_ON_GOLD)
            .backgroundColor(DesignTokens.GOLD_LIGHT)
            .borderRadius(14)
            .onClick((): void => this.chooseSpread('daily'))
        }
        .width('100%')
        .padding(18)
        .backgroundColor(DesignTokens.CARD)
        .borderRadius(18)
        .border({ width: 1, color: DesignTokens.PURPLE_BORDER_WARM })

        Text($r('app.string.quick_entry'))
          .width('100%')
          .fontSize(18)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 10 }) {
          this.QuickCard('✧', $r('app.string.single_card'), $r('app.string.single_card_desc'), 'single')
          this.QuickCard('♢', $r('app.string.three_card_spread'), $r('app.string.three_card_desc'), 'three')
          this.QuickCard('▤', $r('app.string.catalog'), $r('app.string.catalog_desc'), 'catalog')
        }
        .width('100%')

        Column({ space: 7 }) {
          Text($r('app.string.daily_inspiration'))
            .fontSize(16)
            .fontColor(DesignTokens.GOLD_LIGHT)
          Text($r('app.string.daily_inspiration_quote'))
            .fontSize(15)
            .fontColor(DesignTokens.TEXT)
            .lineHeight(23)
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(DesignTokens.PURPLE_DEEP)
        .borderRadius(16)
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  QuickCard(icon: string, title: ResourceStr, subtitle: ResourceStr, target: string) {
    Column({ space: 6 }) {
      Text(icon).fontSize(25).fontColor(DesignTokens.GOLD)
      Text(title).fontSize(14).fontColor(DesignTokens.TEXT)
      Text(subtitle)
        .fontSize(10)
        .fontColor(DesignTokens.TEXT_SECONDARY)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(112)
    .justifyContent(FlexAlign.Center)
    .padding(8)
    .backgroundColor(DesignTokens.SURFACE)
    .borderRadius(14)
    .border({ width: 1, color: DesignTokens.PURPLE_BORDER })
    .onClick((): void => {
      if (target === 'catalog') {
        this.page = 'catalog';
      } else {
        this.chooseSpread(target);
      }
    })
  }

  @Builder
  DrawModePage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header($r('app.string.choose_spread'), true)
        Text($r('app.string.choose_spread_hint'))
          .fontSize(14)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        this.SpreadCard('✧', $r('app.string.single_card'), $r('app.string.single_card_spread_desc'), 'single')
        this.SpreadCard('♢', $r('app.string.timeline_spread'), $r('app.string.timeline_spread_desc'), 'timeline')
        this.SpreadCard('☾', $r('app.string.relationship_spread'), $r('app.string.relationship_spread_desc'), 'relationship')
        this.SpreadCard('✦', $r('app.string.seven_spread'), $r('app.string.seven_spread_desc'), 'seven')
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  SpreadCard(icon: string, title: ResourceStr, description: ResourceStr, spread: string) {
    Row({ space: 16 }) {
      Text(icon).fontSize(34).fontColor(DesignTokens.GOLD)
      Column({ space: 6 }) {
        Text(title).fontSize(19).fontColor(DesignTokens.TEXT)
        Text(description).fontSize(13).fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text($r('app.string.spread_arrow')).fontSize(28).fontColor(DesignTokens.GOLD)
    }
    .width('100%')
    .height(112)
    .padding(18)
    .backgroundColor(DesignTokens.CARD)
    .borderRadius(16)
    .border({ width: 1, color: DesignTokens.PURPLE_BORDER_LIGHT })
    .onClick((): void => this.confirmSpread(spread))
  }

  @Builder
  QuestionPage() {
    Scroll() {
      Column({ space: 16 }) {
        this.Header($r('app.string.input_question'), true)
        Text($r('app.string.input_question_hint'))
          .fontSize(14)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        TextArea({ text: this.question, placeholder: $r('app.string.question_placeholder') })
          .height(150)
          .fontColor(DesignTokens.TEXT)
          .placeholderColor(DesignTokens.PLACEHOLDER)
          .backgroundColor(DesignTokens.SURFACE)
          .borderRadius(14)
          .padding(14)
          .maxLength(300)
          .onChange((value: string): void => {
            this.question = value;
          })
        Text(`${this.question.length}/300`)
          .width('100%')
          .textAlign(TextAlign.End)
          .fontSize(12)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        Text($r('app.string.scene_label'))
          .width('100%')
          .fontSize(16)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 8 }) {
          ForEach(SCENE_OPTIONS.slice(0, 3), (item: [Resource, ReadingScene]) => {
            this.SceneChip(item[0], item[1])
          })
        }
        .width('100%')
        Row({ space: 8 }) {
          ForEach(SCENE_OPTIONS.slice(3), (item: [Resource, ReadingScene]) => {
            this.SceneChip(item[0], item[1])
          })
        }
        .width('100%')
        Text($r('app.string.depth_label'))
          .width('100%')
          .fontSize(16)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 8 }) {
          this.DepthChip($r('app.string.depth_concise'), 'concise')
          this.DepthChip($r('app.string.depth_deep'), 'deep')
        }
        .width('100%')
        Text($r('app.string.mood_label'))
          .width('100%')
          .fontSize(16)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 8 }) {
          ForEach(MOOD_OPTIONS, (item: [Resource, string]) => {
            Button(item[0])
              .layoutWeight(1)
              .height(38)
              .fontSize(12)
              .fontColor(this.mood === item[1] ? DesignTokens.TEXT_ON_GOLD : DesignTokens.TEXT_SECONDARY)
              .backgroundColor(this.mood === item[1] ? DesignTokens.GOLD_LIGHT : DesignTokens.CARD)
              .borderRadius(19)
              .onClick((): void => {
                this.mood = item[1];
              })
          })
        }
        this.GoldButton(this.question.trim().length > 0 ? $r('app.string.next_step') : $r('app.string.skip_to_draw'), (): void => {
          this.page = 'drawMode';
        })
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  SceneChip(label: ResourceStr, value: ReadingScene) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(12)
      .fontColor(this.readingScene === value ? DesignTokens.TEXT_ON_GOLD : DesignTokens.TEXT_SECONDARY)
      .backgroundColor(this.readingScene === value ? DesignTokens.PURPLE : DesignTokens.CARD)
      .borderRadius(20)
      .onClick((): void => {
        this.readingScene = value;
      })
  }

  @Builder
  DepthChip(label: ResourceStr, value: ReadingDepth) {
    Button(label)
      .layoutWeight(1)
      .height(42)
      .fontSize(13)
      .fontColor(this.readingDepth === value ? DesignTokens.TEXT_ON_GOLD : DesignTokens.TEXT_SECONDARY)
      .backgroundColor(this.readingDepth === value ? DesignTokens.PURPLE : DesignTokens.CARD)
      .borderRadius(21)
      .onClick((): void => {
        this.readingDepth = value;
      })
  }

  @Builder
  ShufflePage() {
    Column({ space: 18 }) {
      this.Header($r('app.string.breathe_title'), true)
      Blank()
      Text($r('app.string.breathe_hint'))
        .fontSize(18)
        .fontColor(DesignTokens.TEXT)
      Stack() {
        Image(tarotThemeBack(this.currentTheme))
          .width(156)
          .height(234)
          .objectFit(ImageFit.Cover)
          .borderRadius(14)
          .rotate({ angle: -8 })
        Image(tarotThemeBack(this.currentTheme))
          .width(156)
          .height(234)
          .objectFit(ImageFit.Cover)
          .borderRadius(14)
          .rotate({ angle: 8 })
          .translate({ x: 18 })
      }
      .height(265)
      Blank()
      this.GoldButton($r('app.string.confirm_draw_btn'), (): void => {
        this.completeDraw();
      })
    }
    .layoutWeight(1)
    .padding({ left: 28, right: 28, bottom: 190 })
  }

  @Builder
  ResultPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header(this.drawn.length > 1 ? $r('app.string.three_result_title') : $r('app.string.single_result_title'), true)
        if (this.question.trim().length > 0) {
          Text(`"${this.question}"`)
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          ForEach(this.drawn, (draw: DrawnCard) => {
            Column({ space: 6 }) {
              Image(tarotThemeMedia(this.currentTheme, draw.cardId))
                .width(this.drawn.length === 1 ? 190 : this.drawn.length <= 3 ? 98 : 72)
                .height(this.drawn.length === 1 ? 285 : this.drawn.length <= 3 ? 147 : 108)
                .objectFit(ImageFit.Cover)
                .borderRadius(10)
                .rotate({ angle: draw.orientation === 'reversed' ? 180 : 0 })
              Text(draw.position)
                .fontSize(12)
                .fontColor(DesignTokens.GOLD)
              Text(this.cardById(draw.cardId).nameZhCn)
                .fontSize(14)
                .fontColor(DesignTokens.TEXT)
              Text(draw.orientation === 'upright' ? $r('app.string.orientation_upright') : $r('app.string.orientation_reversed'))
                .fontSize(11)
                .fontColor(DesignTokens.TEXT_SECONDARY)
            }
            .width(this.drawn.length === 1 ? 210 : this.drawn.length <= 3 ? 108 : 82)
            .margin({ bottom: 10 })
          }, (draw: DrawnCard): string => `${draw.cardId}-${draw.position}`)
        }
        .width('100%')
        this.ResultSection($r('app.string.section_inspiration'), this.summary)
        if (this.connection.length > 0) {
          this.ResultSection($r('app.string.section_connection'), this.connection)
        }
        this.ResultSection($r('app.string.section_action'), this.actionText)
        this.ResultSection($r('app.string.section_reflection'), this.reflection)
        if (this.safetyNotice.length > 0) {
          this.ResultSection($r('app.string.section_safety'), this.safetyNotice)
        }
        if (this.clarifications.length > 0) {
          Text($r('app.string.clarification_title'))
            .width('100%')
            .fontSize(17)
            .fontColor(DesignTokens.TEXT)
          Row({ space: 10 }) {
            ForEach(this.clarifications, (draw: DrawnCard) => {
              Column({ space: 5 }) {
                Image(tarotThemeMedia(this.currentTheme, draw.cardId))
                  .width(82)
                  .height(123)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .rotate({ angle: draw.orientation === 'reversed' ? 180 : 0 })
                Text(draw.position).fontSize(11).fontColor(DesignTokens.TEXT_SECONDARY)
              }
            }, (draw: DrawnCard): string => draw.position)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        if (this.clarifications.length < 3) {
          Button($r('app.string.add_clarification'))
            .width('100%')
            .height(48)
            .fontColor(DesignTokens.PURPLE)
            .backgroundColor(DesignTokens.SURFACE)
            .border({ width: 1, color: DesignTokens.PURPLE })
            .borderRadius(24)
            .onClick((): void => this.addClarification())
        }
        this.GoldButton(this.currentSaved ? $r('app.string.saved_to_history') : $r('app.string.save_to_history'), (): void => this.saveCurrent())
        Button($r('app.string.draw_again'))
          .width('100%')
          .height(48)
          .fontColor(DesignTokens.GOLD_LIGHT)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: DesignTokens.GOLD })
          .borderRadius(14)
          .onClick((): void => {
            this.page = 'drawMode';
          })
      }
      .padding({ left: 16, right: 16, bottom: 28 })
    }
    .layoutWeight(1)
  }

  @Builder
  ResultSection(title: ResourceStr, content: ResourceStr) {
    Column({ space: 8 }) {
      Text(title).fontSize(17).fontColor(DesignTokens.GOLD_LIGHT)
      Text(content)
        .fontSize(15)
        .fontColor(DesignTokens.TEXT)
        .lineHeight(24)
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(DesignTokens.SURFACE)
    .borderRadius(14)
  }

  @Builder
  CatalogPage() {
    if (this.selectedCardId.length > 0) {
      this.CardDetailPage()
    } else {
      Column({ space: 10 }) {
        this.Header($r('app.string.catalog'))
        TextInput({ text: this.searchText, placeholder: $r('app.string.search_placeholder') })
          .height(44)
          .fontColor(DesignTokens.TEXT)
          .placeholderColor(DesignTokens.PLACEHOLDER)
          .backgroundColor(DesignTokens.SURFACE)
          .borderRadius(12)
          .onChange((value: string): void => {
            this.searchText = value;
          })
        Scroll() {
          Row({ space: 8 }) {
            ForEach(CATALOG_FILTERS, (item: [string, Resource]) => {
              Button(item[1])
                .height(36)
                .fontSize(12)
                .fontColor(this.catalogFilter === item[0] ? DesignTokens.TEXT_ON_GOLD : DesignTokens.TEXT_SECONDARY)
                .backgroundColor(this.catalogFilter === item[0] ? DesignTokens.GOLD_LIGHT : DesignTokens.CARD)
                .borderRadius(18)
                .onClick((): void => {
                  this.catalogFilter = item[0];
                })
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        Grid() {
          ForEach(this.filteredCards(), (card: TarotCard) => {
            GridItem() {
              Column({ space: 6 }) {
                Image(tarotThemeMedia(this.currentTheme, card.id))
                  .width('100%')
                  .aspectRatio(0.667)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                Text(card.nameZhCn)
                  .fontSize(13)
                  .fontColor(DesignTokens.TEXT)
                  .maxLines(1)
                Text(card.upright.keywords.slice(0, 2).join(' · '))
                  .fontSize(10)
                  .fontColor(DesignTokens.TEXT_SECONDARY)
                  .maxLines(1)
              }
              .width('100%')
              .padding(8)
              .backgroundColor(DesignTokens.SURFACE)
              .borderRadius(12)
              .onClick((): void => {
                this.openCard(card.id);
              })
            }
          }, (card: TarotCard): string => card.id)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .layoutWeight(1)
      }
      .padding({ left: 14, right: 14 })
    }
  }

  @Builder
  CardDetailPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header($r('app.string.card_detail_title'), true)
        Image(tarotThemeMedia(this.currentTheme, this.selectedCardId))
          .width(220)
          .height(330)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
        Text(this.cardById(this.selectedCardId).nameZhCn)
          .fontSize(28)
          .fontColor(DesignTokens.GOLD_LIGHT)
        Text(this.cardById(this.selectedCardId).nameEn)
          .fontSize(14)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        Button(this.favorites.includes(this.selectedCardId) ? $r('app.string.favorite_btn_active') : $r('app.string.favorite_btn'))
          .width('100%')
          .height(44)
          .fontColor(DesignTokens.GOLD_LIGHT)
          .backgroundColor(DesignTokens.CARD)
          .border({ width: 1, color: DesignTokens.GOLD })
          .borderRadius(12)
          .onClick((): void => {
            this.toggleFavorite(this.selectedCardId);
          })
        this.ResultSection($r('app.string.section_upright'), this.cardById(this.selectedCardId).upright.meaning)
        this.ResultSection($r('app.string.section_reversed'), this.cardById(this.selectedCardId).reversed.meaning)
        this.ResultSection($r('app.string.section_symbolism'), this.cardById(this.selectedCardId).symbolism)
        Column({ space: 8 }) {
          Text($r('app.string.note_title'))
            .width('100%')
            .fontSize(17)
            .fontColor(DesignTokens.GOLD_LIGHT)
          TextArea({ text: this.noteDraft, placeholder: $r('app.string.note_placeholder') })
            .width('100%')
            .height(112)
            .fontSize(14)
            .fontColor(DesignTokens.TEXT)
            .placeholderColor(DesignTokens.PLACEHOLDER)
            .backgroundColor(DesignTokens.PURPLE_DARK)
            .borderRadius(10)
            .onChange((value: string): void => {
              this.noteDraft = value.slice(0, 300);
            })
          Text(`${this.noteDraft.length}/300`)
            .width('100%')
            .fontSize(11)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .textAlign(TextAlign.End)
          this.GoldButton($r('app.string.save_note_btn'), (): void => {
            this.saveCardNote(this.selectedCardId);
          })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(DesignTokens.SURFACE)
        .borderRadius(14)
        Button($r('app.string.back_to_catalog'))
          .width('100%')
          .height(48)
          .fontColor(DesignTokens.GOLD_LIGHT)
          .backgroundColor(DesignTokens.CARD)
          .borderRadius(14)
          .onClick((): void => {
            this.selectedCardId = '';
            this.noteDraft = '';
          })
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .id(`card-detail-${this.selectedCardId}`)
    .layoutWeight(1)
  }

  @Builder
  HistoryPage() {
    Column({ space: 14 }) {
      this.Header($r('app.string.history_title'))
      if (this.history.length === 0 && this.records.length === 0) {
        Blank()
        Image($r('app.media.card_placeholder'))
          .width(148)
          .height(222)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
        Text($r('app.string.history_empty'))
          .fontSize(18)
          .fontColor(DesignTokens.TEXT)
        Text($r('app.string.history_empty_hint'))
          .fontSize(13)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
        Blank()
      } else {
        List({ space: 10 }) {
          ForEach(this.records, (record: StoredReadingRecord) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(tarotThemeMedia(record.themeId, record.cards[0].cardId))
                  .width(48)
                  .height(72)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(6)
                  .rotate({ angle: record.cards[0].orientation === 'reversed' ? 180 : 0 })
                Column({ space: 6 }) {
                  if (record.question.length > 0) {
                    Text(record.question).fontSize(15).fontColor(DesignTokens.TEXT).maxLines(2)
                  } else {
                    Text($r('app.string.untitled_reading')).fontSize(15).fontColor(DesignTokens.TEXT)
                  }
                  Text(record.cards.map((card: DrawnCard): string => this.cardById(card.cardId).nameZhCn).join(' · '))
                    .fontSize(12)
                    .fontColor(DesignTokens.TEXT_SECONDARY)
                    .maxLines(1)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(DesignTokens.SURFACE)
              .borderRadius(12)
            }
          }, (record: StoredReadingRecord): string => record.id)
          ForEach(this.history, (item: string, index: number) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(tarotThemeBack(this.currentTheme))
                  .width(48)
                  .height(72)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(6)
                Column({ space: 6 }) {
                  Text(item).fontSize(15).fontColor(DesignTokens.TEXT)
                  Text(this.historyCountLabel(index))
                    .fontSize(12)
                    .fontColor(DesignTokens.TEXT_SECONDARY)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(DesignTokens.SURFACE)
              .borderRadius(12)
            }
          })
        }
        .layoutWeight(1)
      }
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  SettingsPage() {
    Scroll() {
      Column({ space: 12 }) {
        this.Header($r('app.string.settings_title'))
        Text($r('app.string.theme_section_title'))
          .width('100%')
          .fontSize(18)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 12 }) {
          this.ThemeChoice('moon_garden', $r('app.string.theme_moon_garden'), $r('app.string.theme_moon_garden_desc'))
          this.ThemeChoice('stained_glass', $r('app.string.theme_stained_glass'), $r('app.string.theme_stained_glass_desc'))
        }
        .width('100%')
        this.SettingRow($r('app.string.setting_reversals'), $r('app.string.setting_reversals_desc'), this.reversalsEnabled, (value: boolean): void => {
          this.reversalsEnabled = value;
          this.localStore.saveBoolean('reversals', value).catch((): void => {
          });
        })
        this.SettingRow($r('app.string.setting_sound'), $r('app.string.setting_sound_desc'), this.soundEnabled, (value: boolean): void => {
          this.soundEnabled = value;
          this.localStore.saveBoolean('sound', value).catch((): void => {
          });
        })
        this.SettingRow($r('app.string.setting_haptic'), $r('app.string.setting_haptic_desc'), this.hapticEnabled, (value: boolean): void => {
          this.hapticEnabled = value;
          this.localStore.saveBoolean('haptic', value).catch((): void => {
          });
        })
        this.SettingRow($r('app.string.setting_themes'), $r('app.string.setting_themes_desc'), this.recentThemesEnabled, (value: boolean): void => {
          this.recentThemesEnabled = value;
          this.localStore.saveBoolean('recentThemes', value).catch((): void => {
          });
        })
        this.ResultSection($r('app.string.privacy_section'), $r('app.string.privacy_desc'))
        this.ResultSection($r('app.string.usage_section'), $r('app.string.usage_desc'))
        this.ResultSection($r('app.string.about_section'), $r('app.string.about_desc'))
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  ThemeChoice(themeId: TarotThemeId, title: ResourceStr, description: ResourceStr) {
    Column({ space: 7 }) {
      Image(tarotThemeBack(themeId))
        .width(72)
        .height(108)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
      Text(title)
        .fontSize(14)
        .fontColor(DesignTokens.TEXT)
      Text(description)
        .fontSize(10)
        .fontColor(DesignTokens.TEXT_SECONDARY)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(174)
    .padding(10)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(themeId === this.currentTheme ? DesignTokens.CARD : DesignTokens.SURFACE)
    .borderRadius(16)
    .border({ width: themeId === this.currentTheme ? 2 : 1, color: themeId === this.currentTheme ? DesignTokens.PURPLE : DesignTokens.PURPLE_BORDER })
    .onClick((): void => {
      this.currentTheme = themeId;
      this.localStore.saveTheme(themeId).catch((): void => {
      });
    })
  }

  @Builder
  SettingRow(title: ResourceStr, subtitle: ResourceStr, enabled: boolean, change: (value: boolean) => void) {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(title).fontSize(16).fontColor(DesignTokens.TEXT)
        Text(subtitle).fontSize(12).fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .selectedColor(DesignTokens.TOGGLE_ON)
        .onChange(change)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(DesignTokens.SURFACE)
    .borderRadius(14)
  }

  @Builder
  CurrentPage() {
    if (this.page === 'home') {
      this.HomePage()
    } else if (this.page === 'drawMode') {
      this.DrawModePage()
    } else if (this.page === 'question') {
      this.QuestionPage()
    } else if (this.page === 'shuffle') {
      this.ShufflePage()
    } else if (this.page === 'result') {
      this.ResultPage()
    } else if (this.page === 'catalog') {
      this.CatalogPage()
    } else if (this.page === 'history') {
      this.HistoryPage()
    } else {
      this.SettingsPage()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        this.CurrentPage()
        if (this.page === 'home' || this.page === 'catalog' || this.page === 'history' || this.page === 'settings') {
          this.NavBar()
        }
      }
      .width('100%')
      .height('100%')
      .constraintSize({ maxWidth: 720 })
      .backgroundColor(DesignTokens.BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.OUTER_BG)
  }
}
