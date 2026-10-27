import router from '@ohos.router';
import { C, GRADIENTS, MSGS, MsgItem } from '../common/Constants';

@Component
export struct MessagePage {
  @Builder
  MsgCard(item: MsgItem) {
    Row() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          Text(item.emoji).fontSize(22).fontColor('#FFFFFF')
        }
        .width(46).height(46).borderRadius(23)
        .linearGradient({ angle: 135, colors: [[GRADIENTS[item.grad].from, 0], [GRADIENTS[item.grad].to, 1]] })
        .justifyContent(FlexAlign.Center)

        if (item.badge > 0) {
          Text(item.badge > 9 ? '9+' : `${item.badge}`)
            .fontSize(10).fontColor('#FFFFFF')
            .backgroundColor(C.danger).borderRadius(8)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .minWidth(16).height(16)
            .textAlign(TextAlign.Center)
        }
      }
      .width(46).height(46)

      Column() {
        Text(item.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor(C.ink)
        Text(item.last)
          .fontSize(12).fontColor(C.ink3)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(item.time).fontSize(11).fontColor(C.ink3)
    }
    .width('100%')
    .backgroundColor(C.card)
    .borderRadius(18)
    .padding(14)
    .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ChatPage', params: { name: item.name, grad: item.grad, emoji: item.emoji } })
    })
  }

  build() {
    Column() {
      Row() {
        Text('消息').fontSize(22).fontWeight(FontWeight.Bold).fontColor(C.ink)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 12 })

      List() {
        ForEach(MSGS, (item: MsgItem, idx: number) => {
          ListItem() {
            this.MsgCard(item)
          }
          .margin({ bottom: 12 })
        }, (item: MsgItem, idx: number) => `${idx}`)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16, top: 4, bottom: 20 })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
  }
}