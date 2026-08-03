import { DesignTokens } from '../common/DesignTokens';
import { AppPage, AppRootPage } from '../models/TarotModels';

@Component
export struct BottomNavigation {
  @Prop currentPage: AppPage = 'home';
  @Prop safeBottom: number = DesignTokens.SAFE_BOTTOM_FALLBACK;
  onSelect: (page: AppRootPage) => void = (_page: AppRootPage): void => {};

  @Builder
  NavItem(icon: ResourceStr, label: ResourceStr, target: AppRootPage) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(22)
        .fontColor(this.currentPage === target ? DesignTokens.PRIMARY : DesignTokens.TEXT_SECONDARY)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentPage === target ? DesignTokens.PRIMARY : DesignTokens.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .height(DesignTokens.NAV_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .onClick((): void => this.onSelect(target))
  }

  build() {
    Column() {
      Row() {
        this.NavItem($r('app.string.nav_home_icon'), $r('app.string.nav_home'), 'home')
        this.NavItem($r('app.string.nav_draw_icon'), $r('app.string.nav_draw'), 'question')
        this.NavItem($r('app.string.nav_catalog_icon'), $r('app.string.nav_catalog'), 'catalog')
        this.NavItem($r('app.string.nav_profile_icon'), $r('app.string.nav_profile'), 'settings')
      }
      .width('100%')
      .height(DesignTokens.NAV_HEIGHT)
      .padding({ left: 8, right: 8 })
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
