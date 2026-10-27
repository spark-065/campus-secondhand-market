import router from '@ohos.router';
import { C, GRADIENTS, CIRCLE, CircleItem } from '../common/Constants';

@Component
export struct CirclePage {
  @Builder
  CircleCard(item: CircleItem) {
    Column() {
      Row() {
        Column() {
          Text(item.avatarEmoji).fontSize(18).fontColor('#FFFFFF')
        }
        .width(38).height(38).borderRadius(19)
        .linearGradient({ angle: 135, colors: [[GRADIENTS[item.avatarGrad].from, 0], [GRADIENTS[item.avatarGrad].to, 1]] })
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(item.seller).fontSize(14).fontWeight(FontWeight.Bold).fontColor(C.ink)
          Text(item.time).fontSize(11).fontColor(C.ink3).margin({ top: 1 })
        }
        .margin({ left: 10 })
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Blank()
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        Text(item.coverEmoji).fontSize(46)
      }
      .width('100%').height(130).borderRadius(14)
      .linearGradient({ angle: 135, colors: [[GRADIENTS[item.coverGrad].from, 0], [GRADIENTS[item.coverGrad].to, 1]] })
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 10 })

      Text(item.text)
        .fontSize(13).fontColor(C.ink2)
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20)
        .width('100%')
    }
    .backgroundColor(C.card)
    .borderRadius(18)
    .padding(14)
    .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
    .onClick(() => {
      const idx = CIRCLE.indexOf(item)
      router.pushUrl({ url: 'pages/GoodsDetailPage', params: { index: idx } })
    })
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('圈子').fontSize(22).fontWeight(FontWeight.Bold).fontColor(C.ink)
          Text('我关注的卖家').fontSize(12).fontColor(C.ink3).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 12 })

      List() {
        ForEach(CIRCLE, (item: CircleItem, idx: number) => {
          ListItem() {
            this.CircleCard(item)
          }
          .margin({ bottom: 14 })
        }, (item: CircleItem, idx: number) => `${idx}`)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16, top: 4, bottom: 20 })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
  }
}