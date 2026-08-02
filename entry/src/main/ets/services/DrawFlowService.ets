import { DrawPhase } from '../models/TarotModels';

export class DrawFlowService {
  private phaseValue: DrawPhase = 'shuffle';
  private shuffleValue: number = 0;
  private selected: string[] = [];
  private revealed: number = 0;
  private required: number;

  constructor(required: number) {
    this.required = Math.max(1, required);
  }

  shuffle(): number {
    if (this.phaseValue === 'shuffle') {
      this.shuffleValue = Math.min(3, this.shuffleValue + 1);
    }
    return this.shuffleValue;
  }

  shuffleCount(): number {
    return this.shuffleValue;
  }

  canSelect(): boolean {
    return this.shuffleValue >= 3 &&
      this.phaseValue !== 'reveal' && this.phaseValue !== 'complete';
  }

  toggle(cardId: string): boolean {
    if (!this.canSelect()) {
      return false;
    }
    this.phaseValue = 'select';
    const index: number = this.selected.indexOf(cardId);
    if (index >= 0) {
      this.selected.splice(index, 1);
      return true;
    }
    if (this.selected.length >= this.required) {
      return false;
    }
    this.selected.push(cardId);
    return true;
  }

  confirm(): boolean {
    if (this.phaseValue !== 'select' || this.selected.length !== this.required) {
      return false;
    }
    this.phaseValue = 'reveal';
    return true;
  }

  revealNext(): number {
    if (this.phaseValue !== 'reveal') {
      return this.revealed;
    }
    this.revealed = Math.min(this.required, this.revealed + 1);
    if (this.revealed === this.required) {
      this.phaseValue = 'complete';
    }
    return this.revealed;
  }

  allRevealed(): boolean {
    return this.phaseValue === 'complete';
  }

  selectedIds(): string[] {
    return this.selected.slice();
  }

  selectedCount(): number {
    return this.selected.length;
  }

  revealedCount(): number {
    return this.revealed;
  }

  phase(): DrawPhase {
    return this.phaseValue;
  }
}
