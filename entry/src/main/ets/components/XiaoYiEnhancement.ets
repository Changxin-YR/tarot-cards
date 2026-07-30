import { common } from '@kit.AbilityKit';
import { ButtonType, FunctionComponent, FunctionOptions } from '@kit.AgentFrameworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DesignTokens } from '../common/DesignTokens';
import { XIAOYI_AGENT_ID } from '../common/XiaoYiConfig';

@Component
export struct XiaoYiEnhancement {
  queryText: string = '';
  @State lastError: string = '';

  build() {
    Column({ space: 9 }) {
      Row({ space: 8 }) {
        Text('✦').fontSize(22).fontColor(DesignTokens.GOLD_LIGHT)
        Text($r('app.string.xiaoyi_title'))
          .fontSize(17)
          .fontColor(DesignTokens.GOLD_LIGHT)
      }
      .width('100%')
      Text($r('app.string.xiaoyi_description'))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(DesignTokens.TEXT_SECONDARY)
      if (XIAOYI_AGENT_ID.length > 0) {
        FunctionComponent({
          agentId: XIAOYI_AGENT_ID,
          options: {
            title: this.resolvedString($r('app.string.xiaoyi_button_title')),
            queryText: this.queryText,
            buttonType: ButtonType.CAPSULE,
            isShowShadow: true,
            backgroundColor: DesignTokens.GOLD_LIGHT,
            titleColors: [DesignTokens.TEXT_ON_GOLD]
          } as FunctionOptions,
          onError: (error: BusinessError): void => {
            const prefix: string = this.resolvedString($r('app.string.xiaoyi_error_prefix'));
            this.lastError = `${prefix}（${error.code}）`;
          }
        })
      } else {
        Text($r('app.string.xiaoyi_unavailable'))
          .width('100%')
          .padding(12)
          .fontSize(13)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .backgroundColor(DesignTokens.PURPLE_DARK)
          .borderRadius(12)
      }
      if (this.lastError.length > 0) {
        Text(this.lastError)
          .fontSize(12)
          .fontColor(DesignTokens.ERROR_TEXT)
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(DesignTokens.XIAOYI_BG)
    .borderRadius(14)
    .border({ width: 1, color: DesignTokens.XIAOYI_BORDER })
  }

  private resolvedString(resource: Resource): string {
    try {
      const ctx: common.Context | undefined = this.getUIContext().getHostContext();
      if (ctx !== undefined) {
        return ctx.resourceManager.getStringSync(resource);
      }
    } catch {
    }
    return '';
  }
}
