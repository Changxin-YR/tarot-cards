import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppLogger } from '../common/AppLogger';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index').catch((error: Error): void => {
      AppLogger.error('EntryAbility', 'loadContent', error);
    });
  }
}
