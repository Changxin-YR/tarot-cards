import drawServiceTest from './DrawService.test';
import interpretationServiceTest from './InterpretationService.test';
import questionClassifierTest from './QuestionClassifier.test';
import safetyServiceTest from './SafetyService.test';

export default function testsuite(): void {
  drawServiceTest();
  questionClassifierTest();
  safetyServiceTest();
  interpretationServiceTest();
}

