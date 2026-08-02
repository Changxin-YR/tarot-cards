import { ReadingScene } from '../models/TarotModels';

export interface SceneLens {
  focus: string;
  strength: string;
  caution: string;
  actionFrame: string;
}

export class SceneKnowledgeService {
  static forScene(scene: ReadingScene): SceneLens {
    if (scene === 'study') {
      return {
        focus: '学习与准备',
        strength: '已有方法和可以继续积累的能力',
        caution: '节奏、理解盲点与压力分配',
        actionFrame: '选一项最能推进理解的练习'
      };
    }
    if (scene === 'career') {
      return {
        focus: '工作与推进',
        strength: '现有资源和可以影响的环节',
        caution: '沟通、优先级与边界',
        actionFrame: '明确一个可以交付的下一步'
      };
    }
    if (scene === 'relationship') {
      return {
        focus: '关系与沟通',
        strength: '真实感受和连接意愿',
        caution: '期待差异、边界与表达方式',
        actionFrame: '进行一次不预设结果的沟通'
      };
    }
    if (scene === 'social') {
      return {
        focus: '相处与支持',
        strength: '可以建立的信任和共同点',
        caution: '角色压力与互惠失衡',
        actionFrame: '确认一项双方都舒服的边界'
      };
    }
    if (scene === 'growth') {
      return {
        focus: '个人成长',
        strength: '觉察、选择和调整能力',
        caution: '惯性、自我否定与过度要求',
        actionFrame: '完成一个足够小的改变'
      };
    }
    return {
      focus: '今天的状态',
      strength: '当下可以使用的精力和注意力',
      caution: '忽略休息或被琐事牵引',
      actionFrame: '安排一件真正重要的小事'
    };
  }

  static questionFocus(question: string, scene: ReadingScene): string {
    const value: string = question.trim().replace(/\s+/g, ' ');
    return value.length === 0 ? SceneKnowledgeService.forScene(scene).focus : value.slice(0, 48);
  }
}
