@Entry
@Component
struct Index {
  build() {
    Column({ space: 18 }) {
      Text($r('app.string.welcome_title'))
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('☾  ✦  ✧')
        .fontSize(42)
        .fontColor($r('app.color.gold'))

      Text($r('app.string.welcome_subtitle'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))

      Text($r('app.string.building_message'))
        .fontSize(13)
        .fontColor($r('app.color.gold'))
        .margin({ top: 28 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding($r('app.float.page_padding'))
    .backgroundColor($r('app.color.background'))
  }
}

