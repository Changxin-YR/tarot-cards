export class SafetyService {
  private static readonly HIGH_RISK_TERMS: string[] = [
    '疾病',
    '得什么病',
    '癌症',
    '死亡',
    '寿命',
    '法律',
    '判刑',
    '起诉',
    '股票',
    '投资',
    '基金',
    '诊断',
    '药物',
    '伤害自己',
    '自杀',
    '轻生',
    '伤害别人',
    '停药',
    '官司',
    '买哪只股票'
  ];

  static isHighRisk(question: string): boolean {
    const normalized: string = question.replace(/\s+/g, '').toLowerCase();
    return SafetyService.HIGH_RISK_TERMS.some(
      (term: string): boolean => normalized.includes(term.toLowerCase())
    );
  }

  static noticeFor(question: string): string {
    if (!SafetyService.isHighRisk(question)) {
      return '';
    }
    return '提示卡不能替代专业判断。你可以把这次自我反思作为整理情绪的方式，但具体问题应咨询相应专业人士。';
  }

  static soften(content: string): string {
    let result: string = content;
    const replacements: string[][] = [
      ['一定会', '可能会'],
      ['一定', '可以'],
      ['注定', '当前更像是'],
      ['必然', '更可能'],
      ['保证', '提示']
    ];
    replacements.forEach((pair: string[]): void => {
      result = result.split(pair[0]).join(pair[1]);
    });
    return result;
  }
}
