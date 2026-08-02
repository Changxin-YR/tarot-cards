import { QuestionCategory, ReadingScene } from '../models/TarotModels';

export class QuestionClassifier {
  static sceneFor(question: string, selected: ReadingScene): ReadingScene {
    const normalized: string = question.trim().toLowerCase();
    if (QuestionClassifier.containsAny(
      normalized,
      ['考试', '复习', '学习', '课程', '作业', '论文', '学校']
    )) {
      return 'study';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['工作', '汇报', '项目', '职业', '同事', '老板', '升职', '面试']
    )) {
      return 'career';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['伴侣', '感情', '恋爱', '复合', '婚姻', '约会', '喜欢的人']
    )) {
      return 'relationship';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['朋友', '同学', '团队', '社交', '人际', '圈子', '相处']
    )) {
      return 'social';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['成长', '习惯', '自己', '内心', '改变', '目标']
    )) {
      return 'growth';
    }
    return selected;
  }

  static classify(question: string): QuestionCategory {
    const normalized: string = question.trim().toLowerCase();
    if (normalized.length === 0) {
      return 'daily';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['关系', '感情', '恋爱', '伴侣', '对方', '朋友', '相处', '沟通']
    )) {
      return 'relationship';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['工作', '汇报', '同事', '老板', '学习', '考试', '课程', '项目', '职业']
    )) {
      return 'workStudy';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['选择', '决定', '应该', '是否', '两个', '方向', '取舍']
    )) {
      return 'decision';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['压力', '焦虑', '难过', '情绪', '疲惫', '害怕', '紧张']
    )) {
      return 'emotion';
    }
    if (QuestionClassifier.containsAny(
      normalized,
      ['成长', '改变', '自己', '习惯', '目标', '内心']
    )) {
      return 'growth';
    }
    return 'daily';
  }

  private static containsAny(value: string, keywords: string[]): boolean {
    return keywords.some((keyword: string): boolean => value.includes(keyword));
  }
}
