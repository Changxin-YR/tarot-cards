import { DesignTokens } from '../common/DesignTokens';

@Component
export struct AppHeader {
  title: ResourceStr = '';
  @Prop menuOpen: boolean = false;
  onBack: () => void = (): void => {};
  onToggleMenu: () => void = (): void => {};
  onOpenHistory: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row() {
        Button($r('app.string.header_back_icon'))
          .type(ButtonType.Normal)
          .width(DesignTokens.TOUCH_TARGET)
          .height(DesignTokens.TOUCH_TARGET)
          .fontSize(30)
          .fontColor(DesignTokens.PURPLE)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.back_accessibility'))
          .onClick(this.onBack)
        Text(this.title)
          .layoutWeight(1)
          .fontSize(23)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.TEXT)
          .textAlign(TextAlign.Center)
        Button($r('app.string.header_settings_icon'))
          .type(ButtonType.Normal)
          .width(DesignTokens.TOUCH_TARGET)
          .height(DesignTokens.TOUCH_TARGET)
          .fontSize(22)
          .fontColor(DesignTokens.PURPLE)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.more_menu_accessibility'))
          .onClick(this.onToggleMenu)
      }
      .width('100%')
      .height(DesignTokens.HEADER_HEIGHT)
      if (this.menuOpen) {
        Column() {
          Button($r('app.string.history_title'))
            .type(ButtonType.Normal)
            .width('100%')
            .height(DesignTokens.TOUCH_TARGET)
            .fontSize(15)
            .fontColor(DesignTokens.TEXT)
            .backgroundColor(Color.Transparent)
            .onClick(this.onOpenHistory)
        }
        .width(156)
        .margin({ right: 4 })
        .translate({ y: DesignTokens.HEADER_HEIGHT })
        .padding(4)
        .backgroundColor(DesignTokens.SURFACE)
        .border({ width: 1, color: DesignTokens.PURPLE_BORDER })
        .borderRadius(DesignTokens.RADIUS_MEDIUM)
        .shadow({ radius: 16, color: DesignTokens.CARD_SHADOW })
        .zIndex(20)
      }
    }
    .width('100%')
    .height(DesignTokens.HEADER_HEIGHT)
    .zIndex(20)
  }
}
