import { TarotCard, TarotMeaningSide } from '../models/TarotModels';

const THEME_SETS: string[][] = [
  ['开始', '选择', '行动', '信心'],
  ['专注', '表达', '创造', '节奏'],
  ['连接', '倾听', '边界', '理解'],
  ['整理', '平衡', '取舍', '清晰'],
  ['休息', '恢复', '耐心', '照顾'],
  ['成长', '学习', '尝试', '复盘']
];

const SUITE_NAMES: string[] = ['wands', 'cups', 'swords', 'pentacles'];

const CARD_NAMES_ZH_CN: string[] = [
  '愚者', '魔术师', '女祭司', '皇后', '皇帝', '教皇', '恋人', '战车', '力量', '隐者',
  '命运之轮', '正义', '倒吊人', '死神', '节制', '恶魔', '高塔', '星星', '月亮', '太阳',
  '审判', '世界',
  '权杖王牌', '权杖二', '权杖三', '权杖四', '权杖五', '权杖六', '权杖七', '权杖八', '权杖九', '权杖十',
  '权杖侍者', '权杖骑士', '权杖王后', '权杖国王',
  '圣杯王牌', '圣杯二', '圣杯三', '圣杯四', '圣杯五', '圣杯六', '圣杯七', '圣杯八', '圣杯九', '圣杯十',
  '圣杯侍者', '圣杯骑士', '圣杯王后', '圣杯国王',
  '宝剑王牌', '宝剑二', '宝剑三', '宝剑四', '宝剑五', '宝剑六', '宝剑七', '宝剑八', '宝剑九', '宝剑十',
  '宝剑侍者', '宝剑骑士', '宝剑王后', '宝剑国王',
  '星币王牌', '星币二', '星币三', '星币四', '星币五', '星币六', '星币七', '星币八', '星币九', '星币十',
  '星币侍者', '星币骑士', '星币王后', '星币国王'
];

const CARD_NAMES_EN: string[] = [
  'The Fool', 'The Magician', 'The High Priestess', 'The Empress', 'The Emperor', 'The Hierophant',
  'The Lovers', 'The Chariot', 'Strength', 'The Hermit', 'Wheel of Fortune', 'Justice',
  'The Hanged Man', 'Death', 'Temperance', 'The Devil', 'The Tower', 'The Star', 'The Moon',
  'The Sun', 'Judgement', 'The World',
  'Ace of Wands', 'Two of Wands', 'Three of Wands', 'Four of Wands', 'Five of Wands',
  'Six of Wands', 'Seven of Wands', 'Eight of Wands', 'Nine of Wands', 'Ten of Wands',
  'Page of Wands', 'Knight of Wands', 'Queen of Wands', 'King of Wands',
  'Ace of Cups', 'Two of Cups', 'Three of Cups', 'Four of Cups', 'Five of Cups',
  'Six of Cups', 'Seven of Cups', 'Eight of Cups', 'Nine of Cups', 'Ten of Cups',
  'Page of Cups', 'Knight of Cups', 'Queen of Cups', 'King of Cups',
  'Ace of Swords', 'Two of Swords', 'Three of Swords', 'Four of Swords', 'Five of Swords',
  'Six of Swords', 'Seven of Swords', 'Eight of Swords', 'Nine of Swords', 'Ten of Swords',
  'Page of Swords', 'Knight of Swords', 'Queen of Swords', 'King of Swords',
  'Ace of Pentacles', 'Two of Pentacles', 'Three of Pentacles', 'Four of Pentacles', 'Five of Pentacles',
  'Six of Pentacles', 'Seven of Pentacles', 'Eight of Pentacles', 'Nine of Pentacles', 'Ten of Pentacles',
  'Page of Pentacles', 'Knight of Pentacles', 'Queen of Pentacles', 'King of Pentacles'
];

function twoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function cardIdFor(index: number): string {
  if (index < 22) {
    return `major-${twoDigits(index)}`;
  }
  const suiteIndex: number = Math.floor((index - 22) / 14);
  const sequence: number = ((index - 22) % 14) + 1;
  return `${SUITE_NAMES[suiteIndex]}-${twoDigits(sequence)}`;
}

function arcanaFor(index: number): string {
  if (index < 22) {
    return 'major';
  }
  return SUITE_NAMES[Math.floor((index - 22) / 14)];
}

function sequenceFor(index: number): number {
  return index < 22 ? index : ((index - 22) % 14) + 1;
}

function sideFor(index: number, viewLabel: string): TarotMeaningSide {
  const themes: string[] = THEME_SETS[index % THEME_SETS.length];
  return {
    keywords: themes,
    meaning: `${viewLabel}提供一个观察角度：可以先记录与“${themes[0]}”有关的事实，` +
      `再分辨自己能够影响的部分。`,
    actionSeeds: [
      `围绕“${themes[0]}”完成一个今天可以观察到的小步骤。`,
      `为“${themes[1]}”留出一段不被打扰的时间。`
    ],
    reflectionSeeds: [
      `此刻的“${themes[0]}”正在提醒你看见什么？`,
      `关于“${themes[1]}”，你愿意先尝试哪一个小调整？`
    ]
  };
}

function createCard(index: number): TarotCard {
  const cardId: string = cardIdFor(index);
  return {
    id: cardId,
    nameZhCn: CARD_NAMES_ZH_CN[index],
    nameEn: CARD_NAMES_EN[index],
    arcana: arcanaFor(index),
    number: sequenceFor(index),
    element: 'reflection',
    image: `${cardId}.jpg`,
    upright: sideFor(index, '正向视角'),
    reversed: sideFor(index + 1, '侧向视角'),
    symbolism: '这张灵感卡提供一个观察角度，帮助你把注意力带回当下。',
    sourceIds: ['local-reflection']
  };
}

function buildCatalog(): TarotCard[] {
  const cards: TarotCard[] = [];
  for (let index = 0; index < 78; index++) {
    cards.push(createCard(index));
  }
  return cards;
}

export const TAROT_CARDS: TarotCard[] = buildCatalog();
