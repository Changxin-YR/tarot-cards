import appStateTest from './AppState.test';
import appDataServiceTest from './AppDataService.test';
import drawServiceTest from './DrawService.test';
import interpretationServiceTest from './InterpretationService.test';
import localDataCodecTest from './LocalDataCodec.test';
import questionClassifierTest from './QuestionClassifier.test';
import safetyServiceTest from './SafetyService.test';
import spreadServiceTest from './SpreadService.test';
import readingRecordServiceTest from './ReadingRecordService.test';
import greetingServiceTest from './GreetingService.test';
import navigationServiceTest from './NavigationService.test';
import drawFlowServiceTest from './DrawFlowService.test';
import readingRelationshipServiceTest from './ReadingRelationshipService.test';

export default function testsuite(): void {
  appDataServiceTest();
  appStateTest();
  drawServiceTest();
  questionClassifierTest();
  safetyServiceTest();
  interpretationServiceTest();
  localDataCodecTest();
  spreadServiceTest();
  readingRecordServiceTest();
  greetingServiceTest();
  navigationServiceTest();
  drawFlowServiceTest();
  readingRelationshipServiceTest();
}
