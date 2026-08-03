import { DesignTokens } from '../common/DesignTokens';

@Component
export struct ComplianceGate {
  @Prop mandatory: boolean = true;
  @Prop view: string = 'summary';
  @Prop storageError: boolean = false;
  @Prop ready: boolean = false;
  @Prop safeTop: number = DesignTokens.SAFE_TOP_FALLBACK;
  @Prop safeBottom: number = DesignTokens.SAFE_BOTTOM_FALLBACK;
  onViewChange: (view: string) => void = (_view: string): void => {};
  onAccept: () => void = (): void => {};
  onDecline: () => void = (): void => {};
  onClose: () => void = (): void => {};

  @Builder
  PolicyPage(title: ResourceStr, body: ResourceStr) {
    Column({ space: 12 }) {
      Text(title)
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.TEXT)
      Scroll() {
        Text(body)
          .width('100%')
          .fontSize(15)
          .fontColor(DesignTokens.TEXT)
          .lineHeight(24)
      }
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
      Button(this.mandatory ? $r('app.string.policy_back') : $r('app.string.close_action'))
        .width('100%')
        .height(48)
        .fontColor(DesignTokens.PRIMARY)
        .backgroundColor(DesignTokens.CARD)
        .border({ width: 1, color: DesignTokens.PRIMARY })
        .borderRadius(DesignTokens.RADIUS_MEDIUM)
        .onClick((): void => {
          if (this.mandatory) {
            this.onViewChange('summary');
          } else {
            this.onClose();
          }
        })
    }
    .height('100%')
  }

  build() {
    Column() {
      Column({ space: 14 }) {
        if (this.view === 'privacy') {
          this.PolicyPage($r('app.string.privacy_policy_title'), $r('app.string.privacy_policy_body'))
        } else if (this.view === 'agreement') {
          this.PolicyPage($r('app.string.user_agreement_title'), $r('app.string.user_agreement_body'))
        } else {
          Blank()
          Text($r('app.string.compliance_title'))
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(DesignTokens.TEXT)
          Text($r('app.string.compliance_subtitle'))
            .fontSize(15)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .lineHeight(23)
            .textAlign(TextAlign.Center)
          Button($r('app.string.review_privacy_policy'))
            .width('100%')
            .height(48)
            .fontColor(DesignTokens.PRIMARY)
            .backgroundColor(DesignTokens.CARD)
            .borderRadius(DesignTokens.RADIUS_MEDIUM)
            .onClick((): void => this.onViewChange('privacy'))
          Button($r('app.string.review_user_agreement'))
            .width('100%')
            .height(48)
            .fontColor(DesignTokens.PRIMARY)
            .backgroundColor(DesignTokens.CARD)
            .borderRadius(DesignTokens.RADIUS_MEDIUM)
            .onClick((): void => this.onViewChange('agreement'))
          if (this.storageError) {
            Text($r('app.string.compliance_storage_error'))
              .fontSize(13)
              .fontColor(DesignTokens.ERROR_TEXT)
              .textAlign(TextAlign.Center)
          }
          Button($r('app.string.agree_and_continue'))
            .width('100%')
            .height(50)
            .fontColor(DesignTokens.TEXT_ON_PRIMARY)
            .backgroundColor(DesignTokens.PRIMARY)
            .borderRadius(DesignTokens.RADIUS_MEDIUM)
            .enabled(this.ready)
            .onClick(this.onAccept)
          Button($r('app.string.decline_and_exit'))
            .width('100%')
            .height(48)
            .fontColor(DesignTokens.TEXT_SECONDARY)
            .backgroundColor(Color.Transparent)
            .onClick(this.onDecline)
          Blank()
        }
      }
      .width('100%')
      .height('100%')
      .constraintSize({ maxWidth: DesignTokens.CONTENT_MAX_WIDTH })
      .padding({
        left: 24,
        right: 24,
        top: this.safeTop + 20,
        bottom: this.safeBottom + 20
      })
      .backgroundColor(DesignTokens.BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(DesignTokens.OUTER_BG)
  }
}
