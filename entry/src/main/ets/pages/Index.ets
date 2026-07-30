import { common } from '@kit.AbilityKit';
import { TAROT_CARDS } from '../common/TarotCatalogData';
import { DesignTokens } from '../common/DesignTokens';
import { tarotMedia } from '../common/TarotMedia';
import {
  DrawnCard,
  ReadingContext,
  ReadingResult,
  TarotCard
} from '../models/TarotModels';
import { DrawService } from '../services/DrawService';
import { InterpretationService } from '../services/InterpretationService';
import { LocalAppStore, StoredAppData } from '../repositories/LocalAppStore';
import { StoredCardNote } from '../repositories/LocalDataCodec';
import { QuestionClassifier } from '../services/QuestionClassifier';
import { XiaoYiEnhancement } from '../components/XiaoYiEnhancement';

@Entry
@Component
struct Index {
  @State page: string = 'home';
  @State spread: string = 'single';
  @State question: string = '';
  @State mood: string = '';
  @State drawn: DrawnCard[] = [];
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
    this.page = spread === 'daily' ? 'shuffle' : 'question';
  }

  private completeDraw(): void {
    const ids: string[] = TAROT_CARDS.map((card: TarotCard): string => card.id);
    if (this.spread === 'three') {
      this.drawn = DrawService.drawThree(ids, this.reversalsEnabled);
    } else if (this.spread === 'daily') {
      const now: Date = new Date();
      const key: string =
        `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
      this.drawn = [DrawService.dailyDraw(ids, key, this.reversalsEnabled)];
    } else {
      this.drawn = [DrawService.drawSingle(ids, this.reversalsEnabled)];
    }
    const context: ReadingContext = {
      question: this.question,
      category: QuestionClassifier.classify(this.question),
      mood: this.mood,
      recentThemes: this.deriveRecentThemes(),
      cards: this.drawn
    };
    const result: ReadingResult = InterpretationService.build(context, TAROT_CARDS);
    this.summary = result.summary;
    this.connection = result.connection ?? '';
    this.actionText = result.action;
    this.reflection = result.reflection;
    this.safetyNotice = result.safetyNotice ?? '';
    this.page = 'result';
  }

  private saveCurrent(): void {
    const names: string = this.drawn
      .map((draw: DrawnCard): string => this.cardById(draw.cardId).nameZhCn)
      .join(' · ');
    const title: string = `${this.spread === 'three' ? '三牌阵' : '单牌'} · ${names}`;
    this.history = [title].concat(this.history);
    this.localStore.saveHistory(this.history).catch((): void => {
    });
  }

  @Builder
  Header(title: string, showBack: boolean = false) {
    Row() {
      if (showBack) {
        Button('‹')
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
        Text('☾')
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
      Button('⚙')
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
  GoldButton(label: string, action: () => void) {
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
      this.NavItem('⌂', '首页', 'home')
      this.NavItem('✦', '抽牌', 'drawMode')
      this.NavItem('▤', '牌库', 'catalog')
      this.NavItem('▧', '记录', 'history')
    }
    .width('100%')
    .height(66)
    .padding({ left: 8, right: 8 })
    .backgroundColor(DesignTokens.NAV_BG)
    .border({ width: { top: 1 }, color: DesignTokens.NAV_BORDER })
  }

  @Builder
  NavItem(icon: string, label: string, target: string) {
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
        this.Header('塔罗灵感牌')
        Column({ space: 5 }) {
          Text('晚上好，愿你在星光里听见自己')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(DesignTokens.TEXT)
          Text('所有问题与记录仅保存在这台设备')
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('每日一抽')
            .fontSize(20)
            .fontColor(DesignTokens.GOLD_LIGHT)
          Text('听从直觉，抽一张今日指引')
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
          Image($r('app.media.card_back'))
            .width(132)
            .height(198)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .shadow({ radius: 18, color: DesignTokens.CARD_SHADOW })
          Button('抽一张牌')
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

        Text('快速入口')
          .width('100%')
          .fontSize(18)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 10 }) {
          this.QuickCard('✧', '单牌', '一个清晰方向', 'single')
          this.QuickCard('♢', '三牌阵', '过去·现在·行动', 'three')
          this.QuickCard('▤', '牌库', '探索 78 张牌', 'catalog')
        }
        .width('100%')

        Column({ space: 7 }) {
          Text('今日灵感')
            .fontSize(16)
            .fontColor(DesignTokens.GOLD_LIGHT)
          Text('“你已经走在寻找答案的路上，先看见此刻真正能做的一步。”')
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
  QuickCard(icon: string, title: string, subtitle: string, target: string) {
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
    Column({ space: 18 }) {
      this.Header('选择牌阵', true)
      Text('专注当下，选择适合此刻问题的方式')
        .fontSize(14)
        .fontColor(DesignTokens.TEXT_SECONDARY)
      this.SpreadCard('✧', '单牌', '快速获得一个思考方向', 'single')
      this.SpreadCard('♢', '三牌阵', '从过去、现在与行动建议看见联系', 'three')
      this.SpreadCard('☾', '每日灵感', '每天固定一张，只属于今天的提醒', 'daily')
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  SpreadCard(icon: string, title: string, description: string, spread: string) {
    Row({ space: 16 }) {
      Text(icon).fontSize(34).fontColor(DesignTokens.GOLD)
      Column({ space: 6 }) {
        Text(title).fontSize(19).fontColor(DesignTokens.TEXT)
        Text(description).fontSize(13).fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›').fontSize(28).fontColor(DesignTokens.GOLD)
    }
    .width('100%')
    .height(112)
    .padding(18)
    .backgroundColor(DesignTokens.CARD)
    .borderRadius(16)
    .border({ width: 1, color: DesignTokens.PURPLE_BORDER_LIGHT })
    .onClick((): void => this.chooseSpread(spread))
  }

  @Builder
  QuestionPage() {
    Scroll() {
      Column({ space: 16 }) {
        this.Header('输入你的问题', true)
        Text('清晰的问题，更容易带来贴近当下的启发')
          .fontSize(14)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        TextArea({ text: this.question, placeholder: '例如：我目前最需要关注什么？' })
          .height(150)
          .fontColor(DesignTokens.TEXT)
          .placeholderColor(DesignTokens.PLACEHOLDER)
          .backgroundColor(DesignTokens.SURFACE)
          .borderRadius(14)
          .padding(14)
          .maxLength(120)
          .onChange((value: string): void => {
            this.question = value;
          })
        Text(`${this.question.length}/120`)
          .width('100%')
          .textAlign(TextAlign.End)
          .fontSize(12)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        Text('此刻的心情（可选）')
          .width('100%')
          .fontSize(16)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 8 }) {
          ForEach(['平静', '期待', '紧张', '困惑', '低落'], (value: string) => {
            Button(value)
              .layoutWeight(1)
              .height(38)
              .fontSize(12)
              .fontColor(this.mood === value ? '#20172E' : DesignTokens.TEXT_SECONDARY)
              .backgroundColor(this.mood === value ? DesignTokens.GOLD_LIGHT : DesignTokens.CARD)
              .borderRadius(19)
              .onClick((): void => {
                this.mood = value;
              })
          })
        }
        this.GoldButton(this.question.trim().length > 0 ? '下一步' : '跳过问题，直接抽牌', (): void => {
          this.page = 'shuffle';
        })
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  ShufflePage() {
    Column({ space: 18 }) {
      this.Header('静下心来', true)
      Blank()
      Text('在心中默念你的问题')
        .fontSize(18)
        .fontColor(DesignTokens.TEXT)
      Stack() {
        Image($r('app.media.card_back'))
          .width(156)
          .height(234)
          .objectFit(ImageFit.Cover)
          .borderRadius(14)
          .rotate({ angle: -8 })
        Image($r('app.media.card_back'))
          .width(156)
          .height(234)
          .objectFit(ImageFit.Cover)
          .borderRadius(14)
          .rotate({ angle: 8 })
          .translate({ x: 18 })
      }
      .height(265)
      Blank()
      this.GoldButton(this.spread === 'three' ? '抽取三张牌' : '抽一张牌', (): void => {
        this.completeDraw();
      })
    }
    .layoutWeight(1)
    // Keep the primary action above the area occupied by the persistent
    // navigation on the previous page. This also avoids stale hit targets
    // during the page transition on physical devices.
    .padding({ left: 28, right: 28, bottom: 190 })
  }

  @Builder
  ResultPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header(this.spread === 'three' ? '三牌阵解读' : '你的灵感牌', true)
        if (this.question.trim().length > 0) {
          Text(`“${this.question}”`)
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
        Row({ space: 10 }) {
          ForEach(this.drawn, (draw: DrawnCard) => {
            Column({ space: 6 }) {
              Image(tarotMedia(draw.cardId))
                .width(this.drawn.length === 3 ? 98 : 190)
                .height(this.drawn.length === 3 ? 147 : 285)
                .objectFit(ImageFit.Cover)
                .borderRadius(10)
                .rotate({ angle: draw.orientation === 'reversed' ? 180 : 0 })
              Text(draw.position)
                .fontSize(12)
                .fontColor(DesignTokens.GOLD)
              Text(this.cardById(draw.cardId).nameZhCn)
                .fontSize(14)
                .fontColor(DesignTokens.TEXT)
              Text(draw.orientation === 'upright' ? '正位' : '逆位')
                .fontSize(11)
                .fontColor(DesignTokens.TEXT_SECONDARY)
            }
            .layoutWeight(1)
          }, (draw: DrawnCard): string => `${draw.cardId}-${draw.position}`)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        this.ResultSection('灵感解读', this.summary)
        if (this.connection.length > 0) {
          this.ResultSection('三牌联系', this.connection)
        }
        this.ResultSection('可以尝试', this.actionText)
        this.ResultSection('留给自己的问题', this.reflection)
        if (this.safetyNotice.length > 0) {
          this.ResultSection('温和提醒', this.safetyNotice)
        }
        XiaoYiEnhancement({
          queryText: `${this.question.length > 0 ? this.question : '塔罗灵感解读'} · ${this.drawn.map((draw: DrawnCard): string => this.cardById(draw.cardId).nameZhCn).join('、')}`
        })
        this.GoldButton('保存到记录', (): void => this.saveCurrent())
        Button('再抽一次')
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
  ResultSection(title: string, content: string) {
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
        this.Header('牌库')
        TextInput({ text: this.searchText, placeholder: '搜索中文牌名或英文名' })
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
            ForEach([
              ['all', '全部'],
              ['favorite', '收藏'],
              ['major', '大阿'],
              ['wands', '权杖'],
              ['cups', '圣杯'],
              ['swords', '宝剑'],
              ['pentacles', '星币']
            ], (item: string[]) => {
              Button(item[1])
                .height(36)
                .fontSize(12)
                .fontColor(this.catalogFilter === item[0] ? '#20172E' : DesignTokens.TEXT_SECONDARY)
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
                Image(tarotMedia(card.id))
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
        this.Header('牌义详情', true)
        Image(tarotMedia(this.selectedCardId))
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
        Button(this.favorites.includes(this.selectedCardId) ? '★ 已收藏' : '☆ 收藏')
          .width('100%')
          .height(44)
          .fontColor(DesignTokens.GOLD_LIGHT)
          .backgroundColor(DesignTokens.CARD)
          .border({ width: 1, color: DesignTokens.GOLD })
          .borderRadius(12)
          .onClick((): void => {
            this.toggleFavorite(this.selectedCardId);
          })
        this.ResultSection('正位', this.cardById(this.selectedCardId).upright.meaning)
        this.ResultSection('逆位', this.cardById(this.selectedCardId).reversed.meaning)
        this.ResultSection('象征', this.cardById(this.selectedCardId).symbolism)
        Column({ space: 8 }) {
          Text('我的牌义笔记')
            .width('100%')
            .fontSize(17)
            .fontColor(DesignTokens.GOLD_LIGHT)
          TextArea({ text: this.noteDraft, placeholder: '记下这张牌此刻带给你的联想…' })
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
          this.GoldButton('保存牌义笔记', (): void => {
            this.saveCardNote(this.selectedCardId);
          })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(DesignTokens.SURFACE)
        .borderRadius(14)
        Button('返回牌库')
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
      this.Header('灵感记录')
      if (this.history.length === 0) {
        Blank()
        Image($r('app.media.card_placeholder'))
          .width(148)
          .height(222)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
        Text('还没有保存过解读')
          .fontSize(18)
          .fontColor(DesignTokens.TEXT)
        Text('完成一次抽牌后，可以把有共鸣的结果留在这里')
          .fontSize(13)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
        Blank()
      } else {
        List({ space: 10 }) {
          ForEach(this.history, (item: string, index: number) => {
            ListItem() {
              Row({ space: 12 }) {
                Image($r('app.media.card_back'))
                  .width(48)
                  .height(72)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(6)
                Column({ space: 6 }) {
                  Text(item).fontSize(15).fontColor(DesignTokens.TEXT)
                  Text(`第 ${this.history.length - index} 次记录`)
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
        this.Header('设置', true)
        this.SettingRow('启用逆位', '关闭后所有抽牌只出现正位', this.reversalsEnabled, (value: boolean): void => {
          this.reversalsEnabled = value;
          this.localStore.saveBoolean('reversals', value).catch((): void => {
          });
        })
        this.SettingRow('音效', '洗牌与翻牌时的轻柔声音', this.soundEnabled, (value: boolean): void => {
          this.soundEnabled = value;
          this.localStore.saveBoolean('sound', value).catch((): void => {
          });
        })
        this.SettingRow('振动', '重要操作的触感反馈', this.hapticEnabled, (value: boolean): void => {
          this.hapticEnabled = value;
          this.localStore.saveBoolean('haptic', value).catch((): void => {
          });
        })
        this.SettingRow('近期主题个性化', '仅在本机参考近期主题', this.recentThemesEnabled, (value: boolean): void => {
          this.recentThemesEnabled = value;
          this.localStore.saveBoolean('recentThemes', value).catch((): void => {
          });
        })
        this.ResultSection('隐私与安全', '问题、心情、笔记和抽牌结果默认只保存在当前设备。小艺增强需要用户主动确认，且不会自动发送历史记录。')
        this.ResultSection('使用说明', '塔罗用于娱乐、自我探索和情绪整理，不代表对未来的确定预测，也不能替代医疗、法律、心理咨询或投资建议。')
        this.ResultSection('关于', '塔罗灵感牌 V1.0 · HarmonyOS 原生单机版')
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .layoutWeight(1)
  }

  @Builder
  SettingRow(title: string, subtitle: string, enabled: boolean, change: (value: boolean) => void) {
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
        if (this.page === 'home' || this.page === 'drawMode' || this.page === 'catalog' || this.page === 'history') {
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
