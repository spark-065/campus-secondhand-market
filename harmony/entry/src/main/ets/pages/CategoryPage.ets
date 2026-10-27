import router from '@ohos.router';
import { C, GRADIENTS, GOODS, GoodsItem, CATEGORIES, PRICES, REGIONS, TYPES, priceInRange } from '../common/Constants';

@Entry
@Component
struct CategoryPage {
  @State selCate: string[] = []
  @State selPrice: string[] = []
  @State selRegion: string[] = []
  @State selType: string[] = []
  @State filteredGoods: GoodsItem[] = []
  @State toastMsg: string = ''
  @State toastShow: boolean = false
  private toastTimer: number = -1

  aboutToAppear(): void {
    this.filteredGoods = GOODS.slice()
  }

  getGroupItems(group: number): string[] {
    if (group === 0) return CATEGORIES
    if (group === 1) return PRICES
    if (group === 2) return REGIONS
    return TYPES
  }

  isSelected(group: number, val: string): boolean {
    if (group === 0) return this.selCate.indexOf(val) >= 0
    if (group === 1) return this.selPrice.indexOf(val) >= 0
    if (group === 2) return this.selRegion.indexOf(val) >= 0
    return this.selType.indexOf(val) >= 0
  }

  applyFilter(): void {
    this.filteredGoods = GOODS.filter((g: GoodsItem) => {
      if (this.selCate.length > 0 && this.selCate.indexOf(g.category) < 0) return false
      if (this.selPrice.length > 0 && !priceInRange(g.price, this.selPrice[0])) return false
      if (this.selRegion.length > 0 && this.selRegion.indexOf(g.region) < 0) return false
      if (this.selType.length > 0 && this.selType[0] !== g.tradeType) return false
      return true
    })
  }

  toggle(group: number, val: string, multi: boolean): void {
    if (group === 0) {
      const arr = this.selCate.slice()
      const i = arr.indexOf(val)
      if (i >= 0) arr.splice(i, 1); else arr.push(val)
      this.selCate = arr
    } else if (group === 1) {
      const arr = this.selPrice.slice()
      const i = arr.indexOf(val)
      arr.length = 0; if (i < 0) arr.push(val)
      this.selPrice = arr
    } else if (group === 2) {
      const arr = this.selRegion.slice()
      const i = arr.indexOf(val)
      if (i >= 0) arr.splice(i, 1); else arr.push(val)
      this.selRegion = arr
    } else {
      const arr = this.selType.slice()
      const i = arr.indexOf(val)
      arr.length = 0; if (i < 0) arr.push(val)
      this.selType = arr
    }
    this.applyFilter()
  }

  showToast(msg: string): void {
    this.toastMsg = msg
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = true })
    if (this.toastTimer !== -1) clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = false })
    }, 2000)
  }

  @Builder
  ChipRow(group: number, multi: boolean) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.getGroupItems(group), (item: string, idx: number) => {
        Row() {
          Column()
            .width(14).height(14)
            .borderRadius(multi ? 4 : 7)
            .border({ width: 1.5, color: this.isSelected(group, item) ? C.primary : C.ink3 })
            .backgroundColor(this.isSelected(group, item) ? C.primary : Color.Transparent)
            .margin({ right: 6 })
          Text(item)
            .fontSize(13)
            .fontWeight(this.isSelected(group, item) ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.isSelected(group, item) ? C.primaryDeep : C.ink2)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(20)
        .border({ width: 1.5, color: this.isSelected(group, item) ? C.primary : C.line })
        .backgroundColor(this.isSelected(group, item) ? C.primarySoft : C.bg)
        .margin({ right: 10, bottom: 10 })
        .onClick(() => { this.toggle(group, item, multi) })
        .animation({ duration: 180, curve: Curve.EaseOut })
      }, (item: string) => item)
    }
    .width('100%')
  }

  @Builder
  FilterGroup(index: number, title: string, hint: string, group: number, multi: boolean) {
    Column() {
      Row() {
        Text(`${index}`)
          .width(22).height(22).borderRadius(11)
          .backgroundColor(C.primary).fontColor('#FFFFFF')
          .fontSize(12).fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
        Text(title).fontSize(15).fontWeight(FontWeight.Bold).margin({ left: 8 })
        Blank()
        Text(hint)
          .fontSize(11).fontColor(C.ink3)
          .backgroundColor(C.bg).borderRadius(10)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width('100%').margin({ bottom: 14 })

      this.ChipRow(group, multi)
    }
    .backgroundColor(C.card)
    .borderRadius(18)
    .padding(16)
    .margin({ bottom: 14 })
    .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
  }

  @Builder
  GoodsCard(item: GoodsItem) {
    Column() {
      Column() {
        Text(item.emoji).fontSize(40)
      }
      .width('100%').height(118)
      .linearGradient({ angle: 135, colors: [[GRADIENTS[item.grad].from, 0], [GRADIENTS[item.grad].to, 1]] })
      .justifyContent(FlexAlign.Center)

      Column() {
        Text(item.name)
          .fontSize(13).fontWeight(FontWeight.Medium)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%').lineHeight(18)
        Row() {
          Text('¥').fontSize(11).fontColor(C.primary).margin({ top: 4 })
          Text(`${item.price}`).fontSize(17).fontWeight(FontWeight.Bold).fontColor(C.primary)
        }
        .margin({ top: 4 }).alignItems(VerticalAlign.Top)
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
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Column() {
            Text('‹').fontSize(22).fontColor(C.ink)
          }
          .width(38).height(38).borderRadius(19)
          .backgroundColor(C.card)
          .shadow({ radius: 8, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => { router.back() })
          Text('分类筛选').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 10 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 6, bottom: 12 })

        Scroll() {
          Column() {
            this.FilterGroup(1, '类别', '可多选', 0, true)
            this.FilterGroup(2, '价格区间', '单选', 1, false)
            this.FilterGroup(3, '地区', '可多选', 2, true)
            this.FilterGroup(4, '交易类型', '单选', 3, false)

            Row() {
              Text('商品列表').fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              Text(`共 ${this.filteredGoods.length} 件`)
                .fontSize(12).fontColor(C.ink3)
            }
            .width('100%')
            .padding({ left: 4, right: 4, top: 6, bottom: 12 })

            if (this.filteredGoods.length > 0) {
              Grid() {
                ForEach(this.filteredGoods, (item: GoodsItem, idx: number) => {
                  GridItem() {
                    this.GoodsCard(item)
                  }
                }, (item: GoodsItem, idx: number) => `${item.name}_${idx}`)
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(14)
              .rowsGap(14)
              .padding({ left: 4, right: 4 })
              .width('100%')
            } else {
              Column() {
                Text('🔍').fontSize(40).fontColor(C.ink3)
                Text('没有符合条件的商品').fontSize(14).fontColor(C.ink3).margin({ top: 10 })
              }
              .width('100%')
              .padding({ top: 40, bottom: 40 })
              .alignItems(HorizontalAlign.Center)
            }

            Column().height(20)
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 100 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row() {
          Text('重置')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.primary)
            .layoutWeight(1).height(48).borderRadius(14)
            .border({ width: 1.5, color: C.primary })
            .backgroundColor(C.card)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.selCate = []; this.selPrice = []; this.selRegion = []; this.selType = []
              this.applyFilter()
              this.showToast('已重置筛选条件')
            })

          Text('确定')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            .layoutWeight(1.4).height(48).borderRadius(14)
            .linearGradient({ angle: 135, colors: [[C.primary, 0], [C.primaryDeep, 1]] })
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.32)', offsetY: 6 })
            .textAlign(TextAlign.Center)
            .margin({ left: 12 })
            .onClick(() => {
              this.applyFilter()
              this.showToast(`已为你筛选 ${this.filteredGoods.length} 件商品`)
            })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 14, bottom: 18 })
        .backgroundColor(C.bg)
      }
      .width('100%').height('100%')

      if (this.toastShow) {
        Row() {
          Text(this.toastMsg)
            .fontSize(13).fontColor('#FFFFFF')
            .backgroundColor('rgba(26,35,50,0.92)')
            .borderRadius(12)
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 80 })
        .transition({ type: TransitionType.All, opacity: 0, translate: { y: 20 } })
      }
    }
    .width('100%').height('100%')
  }
}