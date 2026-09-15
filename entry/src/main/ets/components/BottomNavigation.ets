import { DesignTokens } from '../common/DesignTokens';
import { AppPage, AppRootPage } from '../models/TarotModels';

@Component
export struct BottomNavigation {
  @Prop currentPage: AppPage = 'home';
  @Prop safeBottom: number = DesignTokens.SAFE_BOTTOM_FALLBACK;
  onSelect: (page: AppRootPage) => void = (_page: AppRootPage): void => {};

  @Builder
  NavItem(icon: ResourceStr, label: ResourceStr, target: AppRootPage) {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.Center }) {
        Image(icon)
          .width(DesignTokens.NAV_ICON_SIZE)
          .height(DesignTokens.NAV_ICON_SIZE)
          .objectFit(ImageFit.Contain)
          .fillColor(this.currentPage === target ? DesignTokens.PRIMARY : DesignTokens.TEXT_SECONDARY)
      }
        .width(DesignTokens.NAV_ICON_HEIGHT)
        .height(DesignTokens.NAV_ICON_HEIGHT)
        .backgroundColor(this.currentPage === target ? DesignTokens.PURPLE_DEEP : Color.Transparent)
        .borderRadius(DesignTokens.RADIUS_MEDIUM)
      Text(label)
        .width('100%')
        .height(DesignTokens.NAV_LABEL_HEIGHT)
        .fontSize(DesignTokens.NAV_LABEL_FONT_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentPage === target ? DesignTokens.PRIMARY : DesignTokens.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(DesignTokens.NAV_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => this.onSelect(target))
  }

  build() {
    Column() {
      Row() {
        this.NavItem($r('app.media.nav_home'), $r('app.string.nav_home'), 'home')
        this.NavItem($r('app.media.nav_draw'), $r('app.string.nav_draw'), 'question')
        this.NavItem($r('app.media.nav_catalog'), $r('app.string.nav_catalog'), 'catalog')
        this.NavItem($r('app.media.nav_profile'), $r('app.string.nav_profile'), 'settings')
      }
      .width('100%')
      .height(DesignTokens.NAV_HEIGHT)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      Row()
        .width('100%')
        .height(this.safeBottom)
    }
    .width('100%')
    .height(DesignTokens.NAV_HEIGHT + this.safeBottom)
    .backgroundColor(DesignTokens.NAV_BG)
    .border({ width: { top: 1 }, color: DesignTokens.NAV_BORDER })
  }
}
