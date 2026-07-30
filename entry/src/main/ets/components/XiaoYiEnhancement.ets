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
        Text('小艺增强')
          .fontSize(17)
          .fontColor(DesignTokens.GOLD_LIGHT)
      }
      .width('100%')
      Text('本地解读始终可用。开启增强时，只发送当前问题、抽牌和本次解读摘要。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(DesignTokens.TEXT_SECONDARY)
      if (XIAOYI_AGENT_ID.length > 0) {
        FunctionComponent({
          agentId: XIAOYI_AGENT_ID,
          options: {
            title: '向小艺继续问',
            queryText: this.queryText,
            buttonType: ButtonType.CAPSULE,
            isShowShadow: true,
            backgroundColor: DesignTokens.GOLD_LIGHT,
            titleColors: ['#20172E']
          } as FunctionOptions,
          onError: (error: BusinessError): void => {
            this.lastError = `暂时无法拉起小艺（${error.code}）`;
          }
        })
      } else {
        Text('当前离线构建尚未写入正式智能体 ID')
          .width('100%')
          .padding(12)
          .fontSize(13)
          .fontColor(DesignTokens.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .backgroundColor('#17152A')
          .borderRadius(12)
      }
      if (this.lastError.length > 0) {
        Text(this.lastError)
          .fontSize(12)
          .fontColor('#D9A5A5')
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#2A2142')
    .borderRadius(14)
    .border({ width: 1, color: '#6B5A9A' })
  }
}

