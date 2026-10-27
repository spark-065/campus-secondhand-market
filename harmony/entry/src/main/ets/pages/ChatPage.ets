import router from '@ohos.router';
import { C, GRADIENTS } from '../common/Constants';

interface ChatMsg {
  text: string
  isMe: boolean
  time: string
}

@Entry
@Component
struct ChatPage {
  @State contactName: string = '陈同学'
  @State contactGrad: number = 2
  @State contactEmoji: string = '🧑'
  @State msgList: ChatMsg[] = []
  @State inputText: string = ''

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      const n = params.name
      if (n) this.contactName = String(n)
      const g = params.grad
      if (g !== undefined && g !== null) this.contactGrad = Number(g)
      const e = params.emoji
      if (e) this.contactEmoji = String(e)
    }
    this.msgList = this.initMessages()
  }

  initMessages(): ChatMsg[] {
    return [
      { text: `你好，${this.contactName}在吗？商品还在吗？`, isMe: true, time: '14:20' },
      { text: '在的，欢迎咨询～', isMe: false, time: '14:22' },
      { text: '能小刀一点吗', isMe: true, time: '14:23' },
      { text: '可以少5块，面交的话', isMe: false, time: '14:25' },
      { text: '好的，明天下午图书馆门口见', isMe: true, time: '14:30' },
      { text: '没问题，到时联系！', isMe: false, time: '14:31' }
    ]
  }

  sendMsg(): void {
    const t = this.inputText.trim()
    if (t.length === 0) return
    const m: ChatMsg = { text: t, isMe: true, time: '刚刚' }
    this.msgList = this.msgList.concat([m])
    this.inputText = ''
  }

  @Builder
  MsgBubble(msg: ChatMsg) {
    Row() {
      if (msg.isMe) {
        Blank()
      }
      Column() {
        Text(msg.text)
          .fontSize(14)
          .fontColor(msg.isMe ? '#FFFFFF' : C.ink)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .borderRadius(16)
          .backgroundColor(msg.isMe ? C.primary : C.card)
          .shadow({ radius: 8, color: 'rgba(27,110,156,0.06)', offsetY: 2 })
        Text(msg.time)
          .fontSize(10).fontColor(C.ink3).margin({ top: 4 })
          .textAlign(msg.isMe ? TextAlign.End : TextAlign.Start)
      }
      .alignItems(msg.isMe ? HorizontalAlign.End : HorizontalAlign.Start)
      .constraintSize({ maxWidth: '75%' })
      if (!msg.isMe) {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
  }

  build() {
    Column() {
      Row() {
        Column() { Text('‹').fontSize(22).fontColor(C.ink) }
          .width(38).height(38).borderRadius(19)
          .backgroundColor(C.card)
          .shadow({ radius: 8, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => { router.back() })
        Column() {
          Text(this.contactEmoji).fontSize(18).fontColor('#FFFFFF')
        }
        .width(34).height(34).borderRadius(17)
        .linearGradient({ angle: 135, colors: [[GRADIENTS[this.contactGrad].from, 0], [GRADIENTS[this.contactGrad].to, 1]] })
        .justifyContent(FlexAlign.Center)
        .margin({ left: 10 })
        Text(this.contactName).fontSize(18).fontWeight(FontWeight.Bold).fontColor(C.ink).margin({ left: 10 })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 6, bottom: 12 })

      List() {
        ForEach(this.msgList, (msg: ChatMsg, idx: number) => {
          ListItem() {
            this.MsgBubble(msg)
          }
        }, (msg: ChatMsg, idx: number) => `${idx}_${msg.time}`)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: 8, bottom: 8 })

      Row() {
        TextInput({ text: this.inputText, placeholder: '输入消息…' })
          .fontSize(14).fontColor(C.ink)
          .layoutWeight(1).height(40).borderRadius(20)
          .backgroundColor(C.bg)
          .padding({ left: 16, right: 16 })
          .onChange((v: string) => { this.inputText = v })
        Text('发送')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          .height(40).borderRadius(20)
          .linearGradient({ angle: 135, colors: [[C.primary, 0], [C.primaryDeep, 1]] })
          .padding({ left: 20, right: 20 })
          .margin({ left: 10 })
          .onClick(() => { this.sendMsg() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 14 })
      .backgroundColor(C.card)
      .border({ width: { top: 1 }, color: { top: C.line } })
    }
    .width('100%').height('100%')
  }
}