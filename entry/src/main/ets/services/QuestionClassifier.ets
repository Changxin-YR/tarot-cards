import { QuestionCategory } from '../models/TarotModels';

export class QuestionClassifier {
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

