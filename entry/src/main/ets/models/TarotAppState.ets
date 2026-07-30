export type AppPage =
  'home' |
  'drawMode' |
  'question' |
  'shuffle' |
  'result' |
  'catalog' |
  'history' |
  'settings';

export type SpreadType = 'single' | 'three' | 'daily';

export class TarotAppState {
  page: AppPage = 'home';
  spread: SpreadType = 'single';
  question: string = '';
  animationRunning: boolean = false;

  chooseSpread(spread: SpreadType): void {
    this.spread = spread;
    this.page = spread === 'daily' ? 'shuffle' : 'question';
  }

  submitQuestion(question: string): void {
    this.question = question.trim();
    this.page = 'shuffle';
  }

  beginShuffle(): boolean {
    if (this.animationRunning) {
      return false;
    }
    this.animationRunning = true;
    return true;
  }

  resetAnimation(): void {
    this.animationRunning = false;
  }
}

