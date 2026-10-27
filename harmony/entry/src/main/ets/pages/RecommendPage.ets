import router from '@ohos.router';
import { C, GRADIENTS, GOODS, GoodsItem } from '../common/Constants';

@Component
export struct RecommendPage {
  onGoCategory: () => void = () => {}
  @State searchText: string = ''
  @State isFocus: boolean = false
  @State showBackTop: boolean = false
  private scroller: Scroller = new Scroller()

  @Builder
  GoodsCover(idx: number, emoji: string) {
    Column() {
      Text(emoji).fontSize(40)
    }
    .width('100%').height(118)
    .linearGradient({ angle: 135, colors: [[GRADIENTS[idx].from, 0], [GRADIENTS[idx].to, 1]] })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  GoodsCard(item: GoodsItem) {
    Column() {
      this.GoodsCover(item.grad, item.emoji)

      Column() {
        Text(item.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .lineHeight(18)
        Row() {
          Text('¥').fontSize(11).fontColor(C.primary).margin({ top: 4 })
          Text(`${item.price}`).fontSize(17).fontWeight(FontWeight.Bold).fontColor(C.primary)
        }
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Top)
      }
      .padding({ left: 12, right: 12, top: 10, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(C.card)
    .borderRadius(18)
    .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
    .onClick(() => {
      const idx = GOODS.indexOf(item)
      router.pushUrl({ url: 'pages/GoodsDetailPage', params: { index: idx } })
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Row() {
            Text('🔍').fontSize(16).fontColor(C.ink3)
            TextInput({ text: this.searchText, placeholder: '搜索二手好物' })
              .placeholderColor(C.ink3)
              .placeholderFont({ size: 14 })
              .fontSize(14)
              .fontColor(C.ink)
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .margin({ left: 8 })
              .onChange((v: string) => { this.searchText = v })
              .onFocus(() => { this.isFocus = true })
              .onBlur(() => { this.isFocus = false })
          }
          .height(42)
          .padding({ left: 16, right: 16 })
          .borderRadius(21)
          .backgroundColor(C.card)
          .border({ width: 1.5, color: this.isFocus ? C.primary : Color.Transparent })
          .shadow(this.isFocus
            ? { radius: 14, color: 'rgba(27,110,156,0.18)', offsetX: 0, offsetY: 0 }
            : { radius: 8, color: 'rgba(27,110,156,0.08)', offsetX: 0, offsetY: 6 })
          .layoutWeight(1)

          Column() {
            Text('⊞').fontSize(18).fontColor(C.primary)
          }
          .width(42).height(42).borderRadius(21)
          .backgroundColor(C.card)
          .shadow({ radius: 8, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
          .margin({ left: 12 })
          .onClick(() => { this.onGoCategory() })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 6, bottom: 12 })

        Scroll(this.scroller) {
          Column() {
            Column().height(6)

            Grid() {
              ForEach(GOODS, (item: GoodsItem, idx: number) => {
                GridItem() {
                  this.GoodsCard(item)
                }
              }, (item: GoodsItem, idx: number) => `${idx}`)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(14)
            .rowsGap(14)
            .padding({ left: 4, right: 4 })
            .width('100%')

            Text('没有更多了 ~')
              .fontSize(12).fontColor(C.ink3)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 22, bottom: 8 })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onScroll((x: number, y: number) => {
          const should = y > 240
          if (should !== this.showBackTop) {
            animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
              this.showBackTop = should
            })
          }
        })
      }
      .width('100%').height('100%')

      if (this.showBackTop) {
        Column() {
          Text('↑').fontSize(22).fontColor('#FFFFFF')
        }
        .width(46).height(46).borderRadius(23)
        .linearGradient({ angle: 135, colors: [[C.primary, 0], [C.primaryDeep, 1]] })
        .shadow({ radius: 18, color: 'rgba(27,110,156,0.35)', offsetY: 6 })
        .margin({ right: 18, bottom: 18 })
        .onClick(() => {
          animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
            this.scroller.scrollEdge(ScrollEdge.Top)
          })
        })
        .transition({ type: TransitionType.All, opacity: 0, translate: { y: 10 } })
      }
    }
    .width('100%').height('100%')
  }
}