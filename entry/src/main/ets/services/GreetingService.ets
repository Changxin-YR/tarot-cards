export interface GreetingCopy {
  title: string;
  subtitle: string;
}

export class GreetingService {
  static forHour(hour: number): GreetingCopy {
    const normalized: number = ((hour % 24) + 24) % 24;
    if (normalized >= 5 && normalized < 9) {
      return { title: '早上好', subtitle: '新的一天，愿你心怀轻盈与期待' };
    }
    if (normalized >= 9 && normalized < 12) {
      return { title: '上午好', subtitle: '愿今天的每一步都从容而清晰' };
    }
    if (normalized >= 12 && normalized < 14) {
      return { title: '中午好', subtitle: '忙碌半日，记得让自己稍作休息' };
    }
    if (normalized >= 14 && normalized < 18) {
      return { title: '下午好', subtitle: '愿午后的时光温柔而充实' };
    }
    if (normalized >= 18 && normalized < 22) {
      return { title: '晚上好', subtitle: '辛苦一天，愿此刻轻松而宁静' };
    }
    return { title: '夜深了', subtitle: '愿你卸下疲惫，安心度过今夜' };
  }
}
