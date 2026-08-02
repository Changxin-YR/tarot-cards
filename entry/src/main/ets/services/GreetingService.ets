export interface GreetingCopy {
  title: string;
  subtitle: string;
}

export class GreetingService {
  static forHour(hour: number): GreetingCopy {
    const normalized: number = ((hour % 24) + 24) % 24;
    if (normalized >= 5 && normalized < 9) {
      return { title: '早上好', subtitle: '愿你带着清醒与从容开始今天' };
    }
    if (normalized >= 9 && normalized < 12) {
      return { title: '上午好', subtitle: '愿你在专注里看见清晰方向' };
    }
    if (normalized >= 12 && normalized < 14) {
      return { title: '中午好', subtitle: '给自己一点停顿与整理的空间' };
    }
    if (normalized >= 14 && normalized < 18) {
      return { title: '下午好', subtitle: '愿你稳稳走向正在靠近的答案' };
    }
    if (normalized >= 18 && normalized < 22) {
      return { title: '晚上好', subtitle: '愿你在安静里听见真实感受' };
    }
    return { title: '夜深了', subtitle: '先照顾自己，再慢慢整理心里的问题' };
  }
}
