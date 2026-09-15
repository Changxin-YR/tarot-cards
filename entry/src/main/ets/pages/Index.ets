import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { TAROT_CARDS } from '../common/TarotCatalogData';
import { DesignTokens } from '../common/DesignTokens';
import { tarotThemeBack, tarotThemeMedia } from '../common/TarotThemeMedia';
import {
  DrawnCard,
  CardReadingSection,
  ClarificationReading,
  Orientation,
  ReadingDepth,
  ReadingScene,
  ReadingContext,
  ReadingResult,
  TarotCard,
  AppPage,
  AppRootPage
} from '../models/TarotModels';
import { SpreadType, TarotThemeId } from '../models/TarotModels';
import { DrawService } from '../services/DrawService';
import { InterpretationService } from '../services/InterpretationService';
import { LocalAppStore } from '../repositories/LocalAppStore';
import { StoredAppData } from '../repositories/AppDataRepository';
import { StoredCardNote, StoredReadingRecord } from '../repositories/LocalDataCodec';
import { QuestionClassifier } from '../services/QuestionClassifier';
import { SpreadService } from '../services/SpreadService';
import { ReadingCollections } from '../services/ReadingRecordService';
import { AppDataService } from '../services/AppDataService';
import { GreetingCopy, GreetingService } from '../services/GreetingService';
import { NavigationService } from '../services/NavigationService';
import { DrawFlowService } from '../services/DrawFlowService';
import { NativeReadingFeedbackPort, ReadingFeedbackService } from '../services/ReadingFeedbackService';
import { AppLogger } from '../common/AppLogger';
import { ResponsiveLayout } from '../common/ResponsiveLayout';
import { AppHeader } from '../components/AppHeader';
import { BottomNavigation } from '../components/BottomNavigation';

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
  @State page: AppPage = 'home';
  @State spread: SpreadType = 'single';
  @State question: string = '';
  @State mood: string = '';
  @State drawn: DrawnCard[] = [];
  @State clarifications: DrawnCard[] = [];
  @State clarificationReadings: ClarificationReading[] = [];
  @State summary: string = '';
  @State connection: string = '';
  @State actionText: string = '';
  @State reflection: string = '';
  @State safetyNotice: string = '';
  @State resultSections: CardReadingSection[] = [];
  @State resultAlgorithmVersion: number = 1;
  @State storageError: boolean = false;
  @State history: string[] = [];
  @State favorites: string[] = [];
  @State notes: StoredCardNote[] = [];
  @State noteDraft: string = '';
  @State catalogFilter: string = 'all';
  @State searchText: string = '';
  @State selectedCardId: string = '';
  @State reversalsEnabled: boolean = true;
  @State soundEnabled: boolean = false;
  @State hapticEnabled: boolean = true;
  @State recentThemesEnabled: boolean = true;
  @State currentTheme: TarotThemeId = 'moon_garden';
  @State records: StoredReadingRecord[] = [];
  @State currentSaved: boolean = false;
  @State saveInProgress: boolean = false;
  @State savedRecordId: string = '';
  @State readingScene: ReadingScene = 'growth';
  @State readingDepth: ReadingDepth = 'concise';
  @State menuOpen: boolean = false;
  @State greetingTitle: string = '';
  @State greetingSubtitle: string = '';
  @State safeTop: number = DesignTokens.SAFE_TOP_FALLBACK;
  @State safeBottom: number = DesignTokens.SAFE_BOTTOM_FALLBACK;
  @State shuffleCount: number = 0;
  @State candidateCardIds: string[] = [];
  @State selectedDrawIds: string[] = [];
  @State pendingDraw: DrawnCard[] = [];
  @State revealedCount: number = 0;
  @State clarificationFlow: boolean = false;
  @State viewportWidth: number = 360;
  @State initializationFailed: boolean = false;
  private appDataService: AppDataService = new AppDataService(new LocalAppStore());
  private navigationService: NavigationService = new NavigationService('home');
  private drawFlowService: DrawFlowService = new DrawFlowService(1);
  private feedbackPort: NativeReadingFeedbackPort = new NativeReadingFeedbackPort();
  private feedback: ReadingFeedbackService = new ReadingFeedbackService(this.feedbackPort);
  private lastHomeBackAt: number = 0;
  private configuredWindow: window.Window | null = null;
  private windowSizeChangeCallback: (size: window.Size) => void = (size: window.Size): void => {
    this.viewportWidth = this.getUIContext().px2vp(size.width);
  };

  async aboutToAppear(): Promise<void> {
    this.refreshGreeting();
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await this.configureWindow(context);
    this.feedbackPort.initialize(context).catch((error: Error): void => {
      AppLogger.error('Index', 'initializeFeedback', error);
    });
    try {
      const data: StoredAppData = await this.appDataService.initialize(context);
      this.history = data.history;
      this.favorites = data.favorites;
      this.notes = data.notes;
      this.reversalsEnabled = data.reversalsEnabled;
      this.soundEnabled = data.soundEnabled;
      this.hapticEnabled = data.hapticEnabled;
      this.recentThemesEnabled = data.recentThemesEnabled;
      this.currentTheme = data.themeId;
      this.records = data.records;
      this.initializationFailed = false;
    } catch (error) {
      AppLogger.error('Index', 'initialize', error);
      this.storageError = true;
      this.initializationFailed = true;
    }
  }

  onPageShow(): void {
    this.refreshGreeting();
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.configureWindow(context);
    }
  }

  aboutToDisappear(): void {
    if (this.configuredWindow !== null) {
      this.configuredWindow.off('windowSizeChange', this.windowSizeChangeCallback);
      this.configuredWindow = null;
    }
  }

  onBackPress(): boolean {
    this.goBack();
    return true;
  }

  private refreshGreeting(): void {
    const greeting: GreetingCopy = GreetingService.forHour(new Date().getHours());
    this.greetingTitle = greeting.title;
    this.greetingSubtitle = greeting.subtitle;
  }

  private async configureWindow(context: common.Context): Promise<void> {
    try {
      const appWindow: window.Window = await window.getLastWindow(context);
      if (this.configuredWindow !== appWindow) {
        if (this.configuredWindow !== null) {
          this.configuredWindow.off('windowSizeChange', this.windowSizeChangeCallback);
        }
        this.configuredWindow = appWindow;
        appWindow.on('windowSizeChange', this.windowSizeChangeCallback);
      }
      this.viewportWidth = this.getUIContext().px2vp(appWindow.getWindowProperties().windowRect.width);
      await appWindow.setWindowLayoutFullScreen(true);
      const systemArea: window.AvoidArea =
        appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const cutoutArea: window.AvoidArea =
        appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      const gestureArea: window.AvoidArea =
        appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
      const indicatorArea: window.AvoidArea =
        appWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.safeTop = Math.max(DesignTokens.SAFE_TOP_FALLBACK, this.getUIContext().px2vp(Math.max(
        systemArea.topRect.height,
        cutoutArea.topRect.height
      )));
      this.safeBottom = Math.max(DesignTokens.SAFE_BOTTOM_FALLBACK, this.getUIContext().px2vp(Math.max(
        systemArea.bottomRect.height,
        gestureArea.bottomRect.height,
        indicatorArea.bottomRect.height
      )));
      await appWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: DesignTokens.TEXT,
        navigationBarContentColor: DesignTokens.TEXT
      });
    } catch (error) {
      AppLogger.error('Index', 'configureWindow', error);
      this.safeTop = DesignTokens.SAFE_TOP_FALLBACK;
      this.safeBottom = DesignTokens.SAFE_BOTTOM_FALLBACK;
    }
  }

  private openPage(page: AppPage): void {
    this.menuOpen = false;
    this.transitionTo(this.navigationService.push(page));
  }

  private replacePage(page: AppPage): void {
    this.menuOpen = false;
    this.transitionTo(this.navigationService.replace(page));
  }

  private selectRoot(page: AppRootPage): void {
    this.menuOpen = false;
    this.selectedCardId = '';
    this.page = this.navigationService.selectRoot(page);
  }

  private transitionTo(page: AppPage): void {
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, (): void => {
      this.page = page;
    });
  }

  private exitReadingFlow(): void {
    this.spread = 'single';
    this.question = '';
    this.mood = '';
    this.readingScene = 'growth';
    this.readingDepth = 'concise';
    this.drawn = [];
    this.clarifications = [];
    this.clarificationReadings = [];
    this.pendingDraw = [];
    this.candidateCardIds = [];
    this.selectedDrawIds = [];
    this.summary = '';
    this.connection = '';
    this.actionText = '';
    this.reflection = '';
    this.safetyNotice = '';
    this.resultSections = [];
    this.resultAlgorithmVersion = 1;
    this.currentSaved = false;
    this.saveInProgress = false;
    this.savedRecordId = '';
    this.shuffleCount = 0;
    this.revealedCount = 0;
    this.clarificationFlow = false;
    this.drawFlowService = new DrawFlowService(1);
    this.selectRoot('home');
  }

  private goBack(): void {
    if (this.menuOpen) {
      this.menuOpen = false;
      return;
    }
    if (this.navigationService.depth() > 1) {
      if (this.page === 'reveal') {
        this.drawFlowService.returnToSelection();
        this.pendingDraw = [];
        this.revealedCount = 0;
      }
      if (this.page === 'cardDetail') {
        this.selectedCardId = '';
        this.noteDraft = '';
      }
      this.transitionTo(this.navigationService.back());
      return;
    }
    if (this.page !== 'home') {
      this.selectRoot('home');
      return;
    }
    const now: number = Date.now();
    if (!NavigationService.isSecondBack(this.lastHomeBackAt, now, 1500)) {
      this.lastHomeBackAt = now;
      try {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.back_again_to_exit'),
          duration: 1500
        });
      } catch (error) {
        AppLogger.error('Index', 'showExitToast', error);
      }
      return;
    }
    this.lastHomeBackAt = 0;
    this.confirmExit();
  }

  private confirmExit(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.exit_title'),
      message: $r('app.string.exit_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.exit_action'),
        action: (): void => {
          this.terminateApp();
        }
      }
    });
  }

  private terminateApp(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      (context as common.UIAbilityContext).terminateSelf().catch((error: Error): void => {
        AppLogger.error('Index', 'terminateSelf', error);
      });
    }
  }

  private confirmRecoverFromInitializationFailure(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.recover_local_data_title'),
      message: $r('app.string.recover_local_data_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.recover_local_data_confirm'),
        fontColor: DesignTokens.ERROR_TEXT,
        action: (): void => {
          this.recoverFromInitializationFailure();
        }
      }
    });
  }

  private async recoverFromInitializationFailure(): Promise<void> {
    try {
      await this.appDataService.clearAll();
      this.resetAfterClearingLocalData();
      this.storageError = false;
      this.initializationFailed = false;
    } catch (error) {
      AppLogger.error('Index', 'recoverFromInitializationFailure', error);
      this.storageError = true;
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
    if (!this.recentThemesEnabled) {
      return [];
    }
    return InterpretationService.recentThemesFromRecords(
      this.records,
      (cardId: string, orientation: Orientation): string[] => {
        const card: TarotCard = this.cardById(cardId);
        return orientation === 'reversed' ? card.reversed.keywords : card.upright.keywords;
      }
    );
  }

  private noteFor(cardId: string): string {
    const note: StoredCardNote | undefined =
      this.notes.find((item: StoredCardNote): boolean => item.cardId === cardId);
    return note?.content ?? '';
  }

  private openCard(cardId: string): void {
    this.selectedCardId = cardId;
    this.noteDraft = this.noteFor(cardId);
    this.openPage('cardDetail');
  }

  private async toggleFavorite(cardId: string): Promise<void> {
    try {
      this.favorites = await this.appDataService.toggleFavorite(this.favorites, cardId);
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'toggleFavorite', error);
      this.storageError = true;
    }
  }

  private async saveCardNote(cardId: string): Promise<void> {
    try {
      this.notes = await this.appDataService.saveCardNote(this.notes, cardId, this.noteDraft);
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'saveCardNote', error);
      this.storageError = true;
    }
  }

  private async saveBooleanSetting(key: string, value: boolean): Promise<void> {
    try {
      const saved: boolean = await this.appDataService.saveBoolean(key, value);
      if (key === 'reversals') {
        this.reversalsEnabled = saved;
      } else if (key === 'sound') {
        this.soundEnabled = saved;
      } else if (key === 'haptic') {
        this.hapticEnabled = saved;
      } else if (key === 'recentThemes') {
        this.recentThemesEnabled = saved;
      }
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'saveBooleanSetting', error);
      this.storageError = true;
    }
  }

  private async selectTheme(themeId: TarotThemeId): Promise<void> {
    try {
      this.currentTheme = await this.appDataService.saveTheme(themeId);
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'selectTheme', error);
      this.storageError = true;
    }
  }

  private chooseSpread(spread: SpreadType): void {
    this.spread = spread;
    this.question = '';
    this.openPage('question');
  }

  private confirmSpread(spread: SpreadType): void {
    this.spread = spread;
    this.prepareDrawFlow(false);
    this.openPage('shuffle');
  }

  private spreadPositions(): string[] {
    if (this.spread === 'daily') {
      return [this.dailyPosition()];
    }
    const stored: SpreadType = SpreadService.storedValue(this.spread) as SpreadType;
    return SpreadService.byId(stored).positions;
  }

  private dailyPosition(): string {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    try {
      return context.resourceManager.getStringSync($r('app.string.daily_inspiration').id);
    } catch (error) {
      AppLogger.error('Index', 'dailyPosition', error);
      return '';
    }
  }

  private clarificationPosition(index: number): string {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    try {
      return context.resourceManager.getStringSync($r('app.string.clarification_position').id, index);
    } catch (error) {
      AppLogger.error('Index', 'clarificationPosition', error);
      return '';
    }
  }

  private prepareDrawFlow(clarification: boolean): void {
    const required: number = clarification ? 1 : this.spreadPositions().length;
    const excluded: string[] = clarification
      ? this.drawn.map((draw: DrawnCard): string => draw.cardId)
        .concat(this.clarifications.map((draw: DrawnCard): string => draw.cardId))
      : [];
    const available: string[] = TAROT_CARDS
      .map((card: TarotCard): string => card.id)
      .filter((cardId: string): boolean => !excluded.includes(cardId));
    const start: number = available.length === 0 ? 0 : Date.now() % available.length;
    const rotated: string[] = available.slice(start).concat(available.slice(0, start));
    this.drawFlowService = new DrawFlowService(required);
    this.candidateCardIds = rotated.slice(0, Math.min(18, rotated.length));
    this.selectedDrawIds = [];
    this.pendingDraw = [];
    this.shuffleCount = 0;
    this.revealedCount = 0;
    this.clarificationFlow = clarification;
  }

  private performShuffle(): void {
    const previous: number = this.shuffleCount;
    this.shuffleCount = this.drawFlowService.shuffle();
    if (this.shuffleCount > previous) {
      this.feedback.emit('shuffle', this.soundEnabled, this.hapticEnabled);
    }
  }

  private continueToSelection(): void {
    if (this.drawFlowService.canSelect()) {
      this.openPage('select');
    }
  }

  private toggleDrawSelection(cardId: string): void {
    if (this.drawFlowService.toggle(cardId)) {
      this.selectedDrawIds = this.drawFlowService.selectedIds();
      this.feedback.emit('selection', this.soundEnabled, this.hapticEnabled);
    }
  }

  private confirmDrawSelection(): void {
    if (!this.drawFlowService.confirm()) {
      return;
    }
    this.feedback.emit('selection', this.soundEnabled, this.hapticEnabled);
    const positions: string[] = this.clarificationFlow
      ? [this.clarificationPosition(this.clarifications.length + 1)]
      : this.spreadPositions();
    this.pendingDraw = this.selectedDrawIds.map((cardId: string, index: number): DrawnCard => {
      const orientation: Orientation = DrawService.drawSingle([cardId], this.reversalsEnabled).orientation;
      return { cardId, orientation, position: positions[index] };
    });
    this.revealedCount = 0;
    this.openPage('reveal');
  }

  private revealNextCard(): void {
    const previous: number = this.revealedCount;
    this.revealedCount = this.drawFlowService.revealNext();
    if (this.revealedCount > previous) {
      this.feedback.emit('reveal', this.soundEnabled, this.hapticEnabled);
    }
  }

  private finishReveal(): void {
    if (!this.drawFlowService.allRevealed()) {
      return;
    }
    if (this.clarificationFlow) {
      this.clarifications = this.clarifications.concat(this.pendingDraw);
      this.updateReading(this.drawn);
      this.currentSaved = false;
    } else {
      this.drawn = this.pendingDraw;
      this.clarifications = [];
      this.clarificationReadings = [];
      this.currentSaved = false;
      this.savedRecordId = '';
      this.updateReading(this.drawn);
    }
    this.openPage('result');
  }

  private updateReading(cards: DrawnCard[]): void {
    const context: ReadingContext = {
      question: this.question,
      category: QuestionClassifier.classify(this.question),
      mood: this.mood,
      recentThemes: this.deriveRecentThemes(),
      cards,
      clarifications: this.clarifications,
      scene: this.readingScene,
      depth: this.readingDepth
    };
    const result: ReadingResult = InterpretationService.build(context, TAROT_CARDS);
    this.summary = result.summary;
    this.connection = result.connection ?? '';
    this.actionText = result.action;
    this.reflection = result.reflection;
    this.safetyNotice = result.safetyNotice ?? '';
    this.resultSections = result.sections;
    this.clarificationReadings = result.clarificationReadings ?? [];
    this.resultAlgorithmVersion = result.algorithmVersion;
  }

  private addClarification(): void {
    if (this.saveInProgress || this.clarifications.length >= 3) {
      return;
    }
    this.prepareDrawFlow(true);
    this.openPage('shuffle');
  }

  private async saveCurrent(): Promise<void> {
    if (this.currentSaved || this.saveInProgress) {
      return;
    }
    this.saveInProgress = true;
    if (this.savedRecordId.length === 0) {
      this.savedRecordId = `reading-${Date.now()}`;
    }
    const recordId: string = this.savedRecordId;
    const existing: StoredReadingRecord | undefined = this.records.find(
      (item: StoredReadingRecord): boolean => item.id === recordId
    );
    const record: StoredReadingRecord = {
      schemaVersion: 4,
      id: recordId,
      createdAt: existing?.createdAt ?? Date.now(),
      question: this.question,
      mood: this.mood,
      scene: this.readingScene,
      depth: this.readingDepth,
      spreadType: SpreadService.storedValue(this.spread),
      themeId: this.currentTheme,
      cards: this.drawn,
      clarifications: this.clarifications,
      result: {
        summary: this.summary,
        sections: this.resultSections,
        connection: this.connection.length > 0 ? this.connection : undefined,
        action: this.actionText,
        reflection: this.reflection,
        clarificationReadings: this.clarificationReadings,
        safetyNotice: this.safetyNotice.length > 0 ? this.safetyNotice : undefined,
        algorithmVersion: this.resultAlgorithmVersion
      },
      note: '',
      favorite: false
    };
    try {
      const next: ReadingCollections = await this.appDataService.upsertRecord(record);
      this.records = next.records;
      this.history = next.history;
      this.currentSaved = true;
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'saveCurrent', error);
      this.storageError = true;
    } finally {
      this.saveInProgress = false;
    }
  }

  private openRecord(record: StoredReadingRecord): void {
    this.spread = record.spreadType as SpreadType;
    this.question = record.question;
    this.mood = record.mood;
    this.readingScene = record.scene;
    this.readingDepth = record.depth;
    this.currentTheme = record.themeId;
    this.drawn = record.cards;
    this.clarifications = record.clarifications;
    this.summary = record.result.summary;
    this.connection = record.result.connection ?? '';
    this.actionText = record.result.action;
    this.reflection = record.result.reflection;
    this.safetyNotice = record.result.safetyNotice ?? '';
    this.resultSections = record.result.sections;
    this.clarificationReadings = record.result.clarificationReadings ?? [];
    this.resultAlgorithmVersion = record.result.algorithmVersion;
    this.savedRecordId = record.id;
    this.currentSaved = true;
    this.openPage('result');
  }

  private async deleteRecord(recordId: string): Promise<void> {
    try {
      const next: ReadingCollections = await this.appDataService.removeRecord(recordId);
      this.records = next.records;
      this.history = next.history;
      if (this.savedRecordId === recordId) {
        this.savedRecordId = '';
        this.currentSaved = false;
      }
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'deleteRecord', error);
      this.storageError = true;
    }
  }

  private confirmDeleteRecord(recordId: string): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_record_title'),
      message: $r('app.string.delete_record_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.delete_action'),
        fontColor: DesignTokens.ERROR_TEXT,
        action: (): void => {
          this.deleteRecord(recordId);
        }
      }
    });
  }

  private async deleteLegacyHistory(index: number): Promise<void> {
    try {
      const next: ReadingCollections = await this.appDataService.removeLegacyRecord(index);
      this.records = next.records;
      this.history = next.history;
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'deleteLegacyHistory', error);
      this.storageError = true;
    }
  }

  private confirmDeleteLegacyHistory(index: number): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_record_title'),
      message: $r('app.string.delete_record_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.delete_action'),
        fontColor: DesignTokens.ERROR_TEXT,
        action: (): void => {
          this.deleteLegacyHistory(index);
        }
      }
    });
  }

  private async clearRecords(): Promise<void> {
    try {
      const cleared: ReadingCollections = await this.appDataService.clearRecords();
      this.records = cleared.records;
      this.history = cleared.history;
      this.savedRecordId = '';
      this.currentSaved = false;
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'clearRecords', error);
      this.storageError = true;
    }
  }

  private confirmClearRecords(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.clear_records_title'),
      message: $r('app.string.clear_records_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.clear_action'),
        fontColor: DesignTokens.ERROR_TEXT,
        action: (): void => {
          this.clearRecords();
        }
      }
    });
  }

  private async clearAllLocalData(): Promise<void> {
    try {
      await this.appDataService.clearAll();
      this.resetAfterClearingLocalData();
      this.storageError = false;
    } catch (error) {
      AppLogger.error('Index', 'clearAllLocalData', error);
      this.storageError = true;
    }
  }

  private resetAfterClearingLocalData(): void {
    this.history = [];
    this.records = [];
    this.favorites = [];
    this.notes = [];
    this.reversalsEnabled = true;
    this.soundEnabled = false;
    this.hapticEnabled = true;
    this.recentThemesEnabled = true;
    this.currentTheme = 'moon_garden';
    this.savedRecordId = '';
    this.currentSaved = false;
    this.initializationFailed = false;
  }

  private confirmClearAllLocalData(): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.clear_all_data_title'),
      message: $r('app.string.clear_all_data_message'),
      primaryButton: {
        value: $r('app.string.cancel_action'),
        action: (): void => {
        }
      },
      secondaryButton: {
        value: $r('app.string.clear_action'),
        fontColor: DesignTokens.ERROR_TEXT,
        action: (): void => {
          this.clearAllLocalData();
        }
      }
    });
  }

  private historyCountLabel(index: number): string {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    try {
      return context.resourceManager.getStringSync(
        $r('app.string.history_count').id,
        this.history.length - index
      );
    } catch (error) {
      AppLogger.error('Index', 'historyCountLabel', error);
      return '';
    }
  }

  @Builder
  Header(title: ResourceStr, showBack: boolean = false) {
    AppHeader({
      title,
      menuOpen: this.menuOpen,
      onBack: (): void => this.goBack(),
      onToggleMenu: (): void => {
        this.menuOpen = !this.menuOpen;
      },
      onOpenHistory: (): void => this.openPage('history')
    })
  }

  @Builder
  StorageErrorNotice() {
    if (this.storageError) {
      Column({ space: 8 }) {
        Text($r('app.string.storage_error'))
          .width('100%')
          .fontSize(13)
          .fontColor(DesignTokens.ERROR_TEXT)
        if (this.initializationFailed) {
          Button($r('app.string.recover_local_data_action'))
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontColor(DesignTokens.ERROR_TEXT)
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: DesignTokens.ERROR_TEXT })
            .borderRadius(DesignTokens.RADIUS_MEDIUM)
            .onClick((): void => this.confirmRecoverFromInitializationFailure())
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor(DesignTokens.SURFACE)
      .borderRadius(8)
    }
  }

  @Builder
  GoldButton(label: ResourceStr, action: () => void) {
    Button(label)
      .width('100%')
      .height(50)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(DesignTokens.TEXT_ON_PRIMARY)
      .backgroundColor(DesignTokens.PRIMARY)
      .borderRadius(14)
      .onClick(action)
  }

  @Builder
  SafeAreaSpacer(height: number) {
    Row()
      .width('100%')
      .height(height)
  }

  @Builder
  NavBar() {
    BottomNavigation({
      currentPage: this.page,
      safeBottom: this.safeBottom,
      onSelect: (target: AppRootPage): void => {
        this.selectRoot(target);
      }
    })
  }

  @Builder
  ReadingExitButton() {
    Button($r('app.string.exit_reading'))
      .type(ButtonType.Normal)
      .width('100%')
      .height(48)
      .fontSize(15)
      .fontColor(DesignTokens.PURPLE)
      .backgroundColor(Color.Transparent)
      .accessibilityText($r('app.string.exit_reading'))
      .onClick((): void => this.exitReadingFlow())
  }

  @Builder
  HomePage() {
    Scroll() {
      Column({ space: 16 }) {
        this.Header($r('app.string.app_title'))
        Column({ space: 5 }) {
          Text(this.greetingTitle)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(DesignTokens.TEXT)
          Text(this.greetingSubtitle)
            .fontSize(14)
            .fontColor(DesignTokens.TEXT_SECONDARY)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text($r('app.string.daily_draw_title'))
            .fontSize(20)
            .fontColor(DesignTokens.PRIMARY)
          Text($r('app.string.daily_draw_hint'))
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
          Image(tarotThemeBack(this.currentTheme))
            .width(132)
            .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
            .objectFit(ImageFit.Cover)
            .accessibilityText($r('app.string.card_back_accessibility'))
            .borderRadius(DesignTokens.CARD_RADIUS)
            .shadow({ radius: 18, color: DesignTokens.CARD_SHADOW })
          Button($r('app.string.draw_one_card_btn'))
            .width(190)
            .height(46)
            .fontColor(DesignTokens.TEXT_ON_PRIMARY)
            .backgroundColor(DesignTokens.PRIMARY)
            .borderRadius(14)
            .onClick((): void => this.chooseSpread('daily'))
        }
        .width('100%')
        .padding(18)
        .backgroundColor(DesignTokens.CARD)
        .borderRadius(DesignTokens.RADIUS_MEDIUM)
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
            .fontColor(DesignTokens.PRIMARY)
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
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  QuickCard(icon: string, title: ResourceStr, subtitle: ResourceStr, target: string) {
    Column({ space: 0 }) {
      Text(icon)
        .width('100%')
        .height(DesignTokens.QUICK_ENTRY_ICON_HEIGHT)
        .fontSize(25)
        .fontColor(DesignTokens.ACCENT_GOLD)
        .textAlign(TextAlign.Center)
        .lineHeight(DesignTokens.QUICK_ENTRY_ICON_HEIGHT)
      Text(title)
        .width('100%')
        .height(DesignTokens.QUICK_ENTRY_TITLE_HEIGHT)
        .fontSize(14)
        .fontColor(DesignTokens.TEXT)
        .textAlign(TextAlign.Center)
        .lineHeight(DesignTokens.QUICK_ENTRY_TITLE_HEIGHT)
      Text(subtitle)
        .width('100%')
        .height(DesignTokens.QUICK_ENTRY_SUBTITLE_HEIGHT)
        .fontSize(10)
        .fontColor(DesignTokens.TEXT_SECONDARY)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(112)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(8)
    .backgroundColor(DesignTokens.SURFACE)
    .borderRadius(14)
    .border({ width: 1, color: DesignTokens.PURPLE_BORDER })
    .onClick((): void => {
      if (target === 'catalog') {
        this.selectRoot('catalog');
      } else {
        this.chooseSpread(target as SpreadType);
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
        this.ReadingExitButton()
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  SpreadCard(icon: string, title: ResourceStr, description: ResourceStr, spread: SpreadType) {
    Row({ space: 16 }) {
      Text(icon).fontSize(34).fontColor(DesignTokens.ACCENT_GOLD)
      Column({ space: 6 }) {
        Text(title).fontSize(19).fontColor(DesignTokens.TEXT)
        Text(description).fontSize(13).fontColor(DesignTokens.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text($r('app.string.spread_arrow')).fontSize(28).fontColor(DesignTokens.ACCENT_GOLD)
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
        Text(this.question.length >= 300
          ? $r('app.string.question_limit_reached')
          : $r('app.string.question_length_counter', this.question.length))
          .width('100%')
          .textAlign(TextAlign.End)
          .fontSize(12)
          .fontColor(this.question.length >= 300 ? DesignTokens.ERROR_TEXT : DesignTokens.TEXT_SECONDARY)
        Text($r('app.string.scene_label'))
          .width('100%')
          .fontSize(16)
          .fontColor(DesignTokens.TEXT)
        Row({ space: 8 }) {
          ForEach(SCENE_OPTIONS.slice(0, 3), (item: [Resource, ReadingScene]) => {
            this.SceneChip(item[0], item[1])
          }, (item: [Resource, ReadingScene]): string => item[1])
        }
        .width('100%')
        Row({ space: 8 }) {
          ForEach(SCENE_OPTIONS.slice(3), (item: [Resource, ReadingScene]) => {
            this.SceneChip(item[0], item[1])
          }, (item: [Resource, ReadingScene]): string => item[1])
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
              .fontColor(this.mood === item[1] ? DesignTokens.TEXT_ON_PRIMARY : DesignTokens.TEXT_SECONDARY)
              .backgroundColor(this.mood === item[1] ? DesignTokens.PRIMARY : DesignTokens.CARD)
              .borderRadius(19)
              .onClick((): void => {
                this.mood = item[1];
              })
          }, (item: [Resource, string]): string => item[1])
        }
        this.GoldButton(this.question.trim().length > 0 ? $r('app.string.next_step') : $r('app.string.skip_to_draw'), (): void => {
          this.openPage('drawMode');
        })
        this.ReadingExitButton()
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  SceneChip(label: ResourceStr, value: ReadingScene) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(12)
      .fontColor(this.readingScene === value ? DesignTokens.TEXT_ON_PRIMARY : DesignTokens.TEXT_SECONDARY)
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
      .fontColor(this.readingDepth === value ? DesignTokens.TEXT_ON_PRIMARY : DesignTokens.TEXT_SECONDARY)
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
          .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
          .objectFit(ImageFit.Cover)
          .accessibilityText($r('app.string.card_back_accessibility'))
          .borderRadius(DesignTokens.CARD_RADIUS)
          .rotate({ angle: -8 - this.shuffleCount * 2 })
        Image(tarotThemeBack(this.currentTheme))
          .width(156)
          .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
          .objectFit(ImageFit.Cover)
          .accessibilityText($r('app.string.card_back_accessibility'))
          .borderRadius(DesignTokens.CARD_RADIUS)
          .rotate({ angle: 8 + this.shuffleCount * 2 })
          .translate({ x: 18 + this.shuffleCount * 3 })
      }
      .height(265)
      .onClick((): void => this.performShuffle())
      Text($r('app.string.shuffle_progress', this.shuffleCount))
        .fontSize(14)
        .fontColor(DesignTokens.TEXT_SECONDARY)
      Blank()
      if (this.shuffleCount < 3) {
        this.GoldButton($r('app.string.shuffle_once'), (): void => this.performShuffle())
      } else {
        this.GoldButton($r('app.string.continue_select'), (): void => this.continueToSelection())
      }
      this.ReadingExitButton()
    }
    .layoutWeight(1)
    .padding({ left: 28, right: 28, bottom: 32 })
  }

  @Builder
  SelectCardsPage() {
    Column({ space: 14 }) {
      this.Header($r('app.string.select_cards_title'), true)
      Text($r('app.string.select_cards_hint'))
        .width('100%')
        .fontSize(14)
        .fontColor(DesignTokens.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
      Text($r(
        'app.string.selected_count',
        this.selectedDrawIds.length,
        this.clarificationFlow ? 1 : this.spreadPositions().length
      ))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.PURPLE)
      Grid() {
        ForEach(this.candidateCardIds, (cardId: string, index: number) => {
          GridItem() {
            Column({ space: 5 }) {
              Image(tarotThemeBack(this.currentTheme))
                .width('100%')
                .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                .objectFit(ImageFit.Cover)
                .accessibilityText($r('app.string.candidate_card_accessibility', index + 1))
                .borderRadius(DesignTokens.CARD_RADIUS)
                .translate({ y: this.selectedDrawIds.includes(cardId) ? -10 : 0 })
                .border({
                  width: this.selectedDrawIds.includes(cardId) ? 2 : 1,
                  color: this.selectedDrawIds.includes(cardId) ? DesignTokens.PURPLE : DesignTokens.PURPLE_BORDER
                })
              if (this.selectedDrawIds.includes(cardId)) {
                Text(this.clarificationFlow
                  ? $r('app.string.clarification_position', this.clarifications.length + 1)
                  : this.spreadPositions()[this.selectedDrawIds.indexOf(cardId)])
                  .fontSize(11)
                  .fontColor(DesignTokens.PURPLE)
                  .maxLines(1)
              } else {
                Text($r('app.string.candidate_card_position', index + 1))
                  .fontSize(11)
                  .fontColor(DesignTokens.TEXT_SECONDARY)
                  .maxLines(1)
              }
            }
            .width('100%')
            .padding({ top: 12, left: 4, right: 4, bottom: 4 })
            .onClick((): void => this.toggleDrawSelection(cardId))
          }
        }, (cardId: string): string => cardId)
      }
      .columnsTemplate(ResponsiveLayout.selectionTemplate(this.viewportWidth))
      .columnsGap(8)
      .rowsGap(8)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      Button($r('app.string.confirm_selection'))
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontColor(DesignTokens.TEXT_ON_PRIMARY)
        .backgroundColor(DesignTokens.PURPLE)
        .borderRadius(DesignTokens.RADIUS_MEDIUM)
        .enabled(this.selectedDrawIds.length === (this.clarificationFlow ? 1 : this.spreadPositions().length))
        .onClick((): void => this.confirmDrawSelection())
      this.ReadingExitButton()
    }
    .layoutWeight(1)
    .padding({ left: DesignTokens.PAGE_PADDING, right: DesignTokens.PAGE_PADDING, bottom: 16 })
  }

  @Builder
  RevealPage() {
    Column({ space: 16 }) {
      this.Header($r('app.string.reveal_title'), true)
      Text(this.question.trim().length > 0 ? $r('app.string.question_quote', this.question) : $r('app.string.breathe_hint'))
        .fontSize(14)
        .fontColor(DesignTokens.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(3)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.pendingDraw, (draw: DrawnCard, index: number) => {
          Column({ space: 6 }) {
            Image(index < this.revealedCount
              ? tarotThemeMedia(this.currentTheme, draw.cardId)
              : tarotThemeBack(this.currentTheme))
              .width(this.pendingDraw.length === 1 ? 190 : this.pendingDraw.length <= 3 ? 98 : 72)
              .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
              .objectFit(ImageFit.Cover)
              .accessibilityText(index < this.revealedCount
                ? $r('app.string.card_image_accessibility', this.cardById(draw.cardId).nameZhCn)
                : $r('app.string.card_back_accessibility'))
              .borderRadius(DesignTokens.CARD_RADIUS)
              .rotate({ angle: index < this.revealedCount && draw.orientation === 'reversed' ? 180 : 0 })
              .opacity(index <= this.revealedCount ? 1 : 0.72)
            Text(draw.position)
              .fontSize(11)
              .fontColor(DesignTokens.PURPLE)
              .maxLines(1)
            if (index < this.revealedCount) {
              Text(this.cardById(draw.cardId).nameZhCn)
                .fontSize(13)
                .fontColor(DesignTokens.TEXT)
            }
          }
          .width(this.pendingDraw.length === 1 ? 210 : this.pendingDraw.length <= 3 ? 108 : 82)
          .margin({ bottom: 10 })
        }, (draw: DrawnCard): string => `${draw.cardId}-${draw.position}`)
      }
      .layoutWeight(1)
      if (this.revealedCount < this.pendingDraw.length) {
        this.GoldButton($r('app.string.reveal_next'), (): void => this.revealNextCard())
      } else {
        this.GoldButton($r('app.string.view_reading'), (): void => this.finishReveal())
      }
      this.ReadingExitButton()
    }
    .layoutWeight(1)
    .padding({ left: DesignTokens.PAGE_PADDING, right: DesignTokens.PAGE_PADDING, bottom: 16 })
  }

  @Builder
  ResultPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header(this.drawn.length > 1 ? $r('app.string.three_result_title') : $r('app.string.single_result_title'), true)
        this.StorageErrorNotice()
        if (this.question.trim().length > 0) {
          Text($r('app.string.question_quote', this.question))
            .fontSize(13)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          ForEach(this.drawn, (draw: DrawnCard) => {
            Column({ space: 6 }) {
              Image(tarotThemeMedia(this.currentTheme, draw.cardId))
                .width(this.drawn.length === 1 ? 190 : this.drawn.length <= 3 ? 98 : 72)
                .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                .objectFit(ImageFit.Cover)
                .accessibilityText($r('app.string.card_image_accessibility', this.cardById(draw.cardId).nameZhCn))
                .borderRadius(DesignTokens.CARD_RADIUS)
                .rotate({ angle: draw.orientation === 'reversed' ? 180 : 0 })
              Text(draw.position)
                .fontSize(12)
                .fontColor(DesignTokens.ACCENT_GOLD)
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
        if (this.clarificationReadings.length > 0) {
          Text($r('app.string.clarification_reading_title'))
            .width('100%')
            .fontSize(17)
            .fontColor(DesignTokens.TEXT)
          ForEach(this.clarificationReadings, (reading: ClarificationReading) => {
            Column({ space: 10 }) {
              Row({ space: 12 }) {
                Image(tarotThemeMedia(this.currentTheme, reading.cardId))
                  .width(78)
                  .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                  .objectFit(ImageFit.Cover)
                  .accessibilityText($r('app.string.card_image_accessibility', reading.cardName))
                  .borderRadius(DesignTokens.CARD_RADIUS)
                  .rotate({ angle: reading.orientation === 'reversed' ? 180 : 0 })
                Column({ space: 5 }) {
                  Text(`${reading.index + 1}. ${reading.cardName}`)
                    .fontSize(16)
                    .fontColor(DesignTokens.TEXT)
                    .fontWeight(FontWeight.Medium)
                  Text(reading.orientation === 'upright'
                    ? $r('app.string.orientation_upright')
                    : $r('app.string.orientation_reversed'))
                    .fontSize(12)
                    .fontColor(DesignTokens.ACCENT_GOLD)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              this.ClarificationField($r('app.string.clarification_focus'), reading.focus)
              this.ClarificationField($r('app.string.clarification_meaning'), reading.meaning)
              this.ClarificationField($r('app.string.clarification_impact'), reading.impact)
              this.ClarificationField($r('app.string.clarification_action'), reading.action)
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .alignItems(HorizontalAlign.Start)
            .border({ width: { bottom: 1 }, color: DesignTokens.DIVIDER })
          }, (reading: ClarificationReading): string => `${reading.cardId}-${reading.index}`)
        }
        if (this.clarifications.length < 3) {
          Button($r('app.string.add_clarification'))
            .width('100%')
            .height(48)
            .fontColor(DesignTokens.PURPLE)
            .backgroundColor(DesignTokens.SURFACE)
            .border({ width: 1, color: DesignTokens.PURPLE })
            .borderRadius(24)
            .enabled(!this.saveInProgress)
            .onClick((): void => this.addClarification())
        }
        Button(this.currentSaved ? $r('app.string.saved_to_history') : $r('app.string.save_to_history'))
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(DesignTokens.TEXT_ON_PRIMARY)
          .backgroundColor(DesignTokens.PRIMARY)
          .borderRadius(14)
          .enabled(!this.saveInProgress && !this.currentSaved)
          .onClick((): void => {
            this.saveCurrent();
          })
        Button($r('app.string.draw_again'))
          .width('100%')
          .height(48)
          .fontColor(DesignTokens.PRIMARY)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: DesignTokens.ACCENT_GOLD })
          .borderRadius(14)
          .onClick((): void => {
            this.openPage('drawMode');
          })
        this.ReadingExitButton()
      }
      .padding({ left: 16, right: 16, bottom: 28 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  ResultSection(title: ResourceStr, content: ResourceStr) {
    Column({ space: 8 }) {
      Text(title).fontSize(17).fontColor(DesignTokens.PRIMARY)
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
  ClarificationField(title: ResourceStr, content: ResourceStr) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(12)
        .fontColor(DesignTokens.ACCENT_GOLD)
      Text(content)
        .fontSize(14)
        .fontColor(DesignTokens.TEXT)
        .lineHeight(22)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CatalogPage() {
    Column({ space: 10 }) {
        this.Header($r('app.string.catalog'))
        this.StorageErrorNotice()
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
                .fontColor(this.catalogFilter === item[0] ? DesignTokens.TEXT_ON_PRIMARY : DesignTokens.TEXT_SECONDARY)
                .backgroundColor(this.catalogFilter === item[0] ? DesignTokens.PRIMARY : DesignTokens.CARD)
                .borderRadius(18)
                .onClick((): void => {
                  this.catalogFilter = item[0];
                })
            }, (item: [string, Resource]): string => item[0])
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        Grid() {
          ForEach(this.filteredCards(), (card: TarotCard) => {
            GridItem() {
              Column({ space: 6 }) {
                Image(tarotThemeMedia(this.currentTheme, card.id))
                  .width('100%')
                  .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                  .objectFit(ImageFit.Cover)
                  .accessibilityText($r('app.string.card_image_accessibility', card.nameZhCn))
                  .borderRadius(DesignTokens.CARD_RADIUS)
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
        .columnsTemplate(ResponsiveLayout.catalogTemplate(this.viewportWidth))
        .columnsGap(10)
        .rowsGap(10)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
    }
    .padding({ left: 14, right: 14 })
    .layoutWeight(1)
  }

  @Builder
  CardDetailPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header($r('app.string.card_detail_title'), true)
        this.StorageErrorNotice()
        Image(tarotThemeMedia(this.currentTheme, this.selectedCardId))
          .width(220)
          .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
          .objectFit(ImageFit.Cover)
          .accessibilityText($r('app.string.card_image_accessibility', this.cardById(this.selectedCardId).nameZhCn))
          .borderRadius(DesignTokens.CARD_RADIUS)
        Text(this.cardById(this.selectedCardId).nameZhCn)
          .fontSize(28)
          .fontColor(DesignTokens.PRIMARY)
        Text(this.cardById(this.selectedCardId).nameEn)
          .fontSize(14)
          .fontColor(DesignTokens.TEXT_SECONDARY)
        Button(this.favorites.includes(this.selectedCardId) ? $r('app.string.favorite_btn_active') : $r('app.string.favorite_btn'))
          .width('100%')
          .height(44)
          .fontColor(DesignTokens.PRIMARY)
          .backgroundColor(DesignTokens.CARD)
          .border({ width: 1, color: DesignTokens.ACCENT_GOLD })
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
            .fontColor(DesignTokens.PRIMARY)
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
          .fontColor(DesignTokens.PRIMARY)
          .backgroundColor(DesignTokens.CARD)
          .borderRadius(14)
          .onClick((): void => {
            this.selectedCardId = '';
            this.noteDraft = '';
            this.goBack();
          })
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .scrollBar(BarState.Off)
    .id(`card-detail-${this.selectedCardId}`)
    .layoutWeight(1)
  }

  @Builder
  HistoryPage() {
    Column({ space: 14 }) {
      this.Header($r('app.string.history_title'))
      this.StorageErrorNotice()
      if (this.history.length > 0 || this.records.length > 0) {
        Button($r('app.string.clear_records_action'))
          .width('100%')
          .height(48)
          .fontColor(DesignTokens.ERROR_TEXT)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: DesignTokens.ERROR_TEXT })
          .borderRadius(14)
          .onClick((): void => this.confirmClearRecords())
      }
      if (this.history.length === 0 && this.records.length === 0) {
        Blank()
        Image($r('app.media.card_placeholder'))
          .width(148)
          .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
          .objectFit(ImageFit.Cover)
          .accessibilityText($r('app.string.history_empty_image_accessibility'))
          .borderRadius(DesignTokens.CARD_RADIUS)
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
                Row({ space: 12 }) {
                  Image(tarotThemeMedia(record.themeId, record.cards[0].cardId))
                    .width(48)
                    .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                    .objectFit(ImageFit.Cover)
                    .accessibilityText($r(
                      'app.string.card_image_accessibility',
                      this.cardById(record.cards[0].cardId).nameZhCn
                    ))
                    .borderRadius(DesignTokens.CARD_RADIUS)
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
                .layoutWeight(1)
                .onClick((): void => this.openRecord(record))
                Button($r('app.string.delete_action'))
                  .height(48)
                  .fontSize(13)
                  .fontColor(DesignTokens.ERROR_TEXT)
                  .backgroundColor(Color.Transparent)
                  .onClick((): void => this.confirmDeleteRecord(record.id))
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
                  .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
                  .objectFit(ImageFit.Cover)
                  .accessibilityText($r('app.string.card_back_accessibility'))
                  .borderRadius(DesignTokens.CARD_RADIUS)
                Column({ space: 6 }) {
                  Text(item).fontSize(15).fontColor(DesignTokens.TEXT)
                  Text(this.historyCountLabel(index))
                    .fontSize(12)
                    .fontColor(DesignTokens.TEXT_SECONDARY)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Button($r('app.string.delete_action'))
                  .height(48)
                  .fontSize(13)
                  .fontColor(DesignTokens.ERROR_TEXT)
                  .backgroundColor(Color.Transparent)
                  .onClick((): void => this.confirmDeleteLegacyHistory(index))
              }
              .width('100%')
              .padding(12)
              .backgroundColor(DesignTokens.SURFACE)
              .borderRadius(12)
            }
          })
        }
        .scrollBar(BarState.Off)
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
        this.StorageErrorNotice()
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
          this.saveBooleanSetting('reversals', value);
        })
        this.SettingRow($r('app.string.setting_sound'), $r('app.string.setting_sound_desc'), this.soundEnabled, (value: boolean): void => {
          this.saveBooleanSetting('sound', value);
        })
        this.SettingRow($r('app.string.setting_haptic'), $r('app.string.setting_haptic_desc'), this.hapticEnabled, (value: boolean): void => {
          this.saveBooleanSetting('haptic', value);
        })
        this.SettingRow($r('app.string.setting_themes'), $r('app.string.setting_themes_desc'), this.recentThemesEnabled, (value: boolean): void => {
          this.saveBooleanSetting('recentThemes', value);
        })
        this.ResultSection($r('app.string.user_agreement_title'), $r('app.string.user_agreement_body'))
        this.ResultSection($r('app.string.usage_section'), $r('app.string.usage_desc'))
        this.ResultSection($r('app.string.about_section'), $r('app.string.about_desc'))
        Button($r('app.string.clear_all_data_action'))
          .width('100%')
          .height(50)
          .fontColor(DesignTokens.ERROR_TEXT)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: DesignTokens.ERROR_TEXT })
          .borderRadius(14)
          .onClick((): void => this.confirmClearAllLocalData())
      }
      .padding({ left: 16, right: 16, bottom: 24 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  ThemeChoice(themeId: TarotThemeId, title: ResourceStr, description: ResourceStr) {
    Column({ space: 7 }) {
      Image(tarotThemeBack(themeId))
        .width(72)
        .aspectRatio(DesignTokens.CARD_ASPECT_RATIO)
        .objectFit(ImageFit.Cover)
        .accessibilityText($r('app.string.card_back_accessibility'))
        .borderRadius(DesignTokens.CARD_RADIUS)
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
      this.selectTheme(themeId);
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
    .alignItems(VerticalAlign.Center)
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
    } else if (this.page === 'select') {
      this.SelectCardsPage()
    } else if (this.page === 'reveal') {
      this.RevealPage()
    } else if (this.page === 'result') {
      this.ResultPage()
    } else if (this.page === 'catalog') {
      this.CatalogPage()
    } else if (this.page === 'cardDetail') {
      this.CardDetailPage()
    } else if (this.page === 'history') {
      this.HistoryPage()
    } else {
      this.SettingsPage()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        this.SafeAreaSpacer(this.safeTop)
        Column() {
          Column() {
            this.CurrentPage()
          }
          .width('100%')
          .layoutWeight(1)
          .id(`page-${this.page}`)
          .transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut }))
          if (this.page === 'home' || this.page === 'question' || this.page === 'catalog' || this.page === 'settings') {
            this.NavBar()
          } else {
            this.SafeAreaSpacer(this.safeBottom)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .constraintSize({ maxWidth: DesignTokens.CONTENT_MAX_WIDTH })
      .backgroundColor(DesignTokens.BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.OUTER_BG)
  }
}
