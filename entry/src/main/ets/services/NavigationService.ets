import { AppPage, AppRootPage } from '../models/TarotModels';

export class NavigationService {
  private stack: AppPage[];

  constructor(initial: AppPage) {
    this.stack = [initial];
  }

  current(): AppPage {
    return this.stack[this.stack.length - 1];
  }

  depth(): number {
    return this.stack.length;
  }

  push(page: AppPage): AppPage {
    this.stack.push(page);
    return page;
  }

  replace(page: AppPage): AppPage {
    this.stack[this.stack.length - 1] = page;
    return page;
  }

  back(): AppPage {
    if (this.stack.length > 1) {
      this.stack.pop();
    }
    return this.current();
  }

  selectRoot(page: AppRootPage): AppPage {
    this.stack = [page];
    return page;
  }

  static isSecondBack(first: number, next: number, windowMs: number): boolean {
    return first > 0 && next >= first && next - first <= windowMs;
  }
}
