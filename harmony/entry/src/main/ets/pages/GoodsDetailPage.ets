import router from '@ohos.router';
import { C, GRADIENTS, GOODS, GoodsItem, COMMENTS, CommentItem } from '../common/Constants';

@Entry
@Component
struct GoodsDetailPage {
  @State index: number = 0
  @State goods: GoodsItem = GOODS[0]
  @State commentList: CommentItem[] = []
  @State inputText: string = ''
  @State toastMsg: string = ''
  @State toastShow: boolean = false
  private toastTimer: number = -1

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params.index !== undefined && params.index !== null) {
      this.index = Number(params.index)
    }
    if (this.index >= 0 && this.index < GOODS.length) {
      this.goods = GOODS[this.index]
    }
    this.commentList = COMMENTS.slice()
  }

  getSimilar(): GoodsItem[] {
    const same: GoodsItem[] = []
    const others: GoodsItem[] = []
    for (let i = 0; i < GOODS.length; i++) {
      if (i === this.index) continue
      if (GOODS[i].category === this.goods.category) same.push(GOODS[i])
      else others.push(GOODS[i])
    }
    return same.concat(others).slice(0, 6)
  }

  showToast(msg: string): void {
    this.toastMsg = msg
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = true })
    if (this.toastTimer !== -1) clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = false })
    }, 2000)
  }

  sendComment(): void {
    const t = this.inputText.trim()
    if (t.length === 0) { this.showToast('请输入评论内容'); return }
    const newC: CommentItem = { name: '我', avatar: '🦊', grad: 0, content: t, time: '刚刚', isSeller: false }
    this.commentList = this.commentList.concat([newC])
    this.inputText = ''
    this.showToast('评论已发送')
  }

  @Builder
  CommentRow(item: CommentItem) {
    Row() {
      Column() {
        Text(item.avatar).fontSize(18).fontColor('#FFFFFF')
      }
      .width(36).height(36).borderRadius(18)
      .linearGradient({ angle: 135, colors: [[GRADIENTS[item.grad].from, 0], [GRADIENTS[item.grad].to, 1]] })
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(item.name).fontSize(13).fontWeight(FontWeight.Bold).fontColor(C.ink)
          if (item.isSeller) {
            Text('卖家').fontSize(9).fontColor('#FFFFFF')
              .backgroundColor(C.primary).borderRadius(4)
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .margin({ left: 6 })
          }
        }
        Text(item.content).fontSize(13).fontColor(C.ink2).margin({ top: 5 }).lineHeight(18)
        Text(item.time).fontSize(11).fontColor(C.ink3).margin({ top: 4 })
      }
      .margin({ left: 10 }).alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  SimilarCard(item: GoodsItem) {
    Column() {
      Column() {
        Text(item.emoji).fontSize(32)
      }
      .width('100%').height(90)
      .linearGradient({ angle: 135, colors: [[GRADIENTS[item.grad].from, 0], [GRADIENTS[item.grad].to, 1]] })
      .justifyContent(FlexAlign.Center)

      Column() {
        Text(item.name).fontSize(12).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text(`¥${item.price}`).fontSize(14).fontWeight(FontWeight.Bold).fontColor(C.primary).margin({ top: 4 })
      }
      .padding({ left: 8, right: 8, top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width(130)
    .backgroundColor(C.card).borderRadius(14)
    .shadow({ radius: 12, color: 'rgba(27,110,156,0.08)', offsetY: 4 })
    .onClick(() => {
      const idx = GOODS.indexOf(item)
      router.replaceUrl({ url: 'pages/GoodsDetailPage', params: { index: idx } })
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Column() { Text('‹').fontSize(22).fontColor(C.ink) }
            .width(38).height(38).borderRadius(19)
            .backgroundColor(C.card)
            .shadow({ radius: 8, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
            .justifyContent(FlexAlign.Center)
            .onClick(() => { router.back() })
          Text('商品详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 10 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 6, bottom: 12 })

        Scroll() {
          Column() {
            Row() {
              Column() { Text(this.goods.sellerAvatar).fontSize(20).fontColor('#FFFFFF') }
                .width(44).height(44).borderRadius(22)
                .linearGradient({ angle: 135, colors: [[GRADIENTS[this.goods.sellerGrad].from, 0], [GRADIENTS[this.goods.sellerGrad].to, 1]] })
                .justifyContent(FlexAlign.Center)
              Column() {
                Text(this.goods.seller).fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.ink)
                Text(this.goods.publishTime).fontSize(12).fontColor(C.ink3).margin({ top: 2 })
              }
              .margin({ left: 12 }).alignItems(HorizontalAlign.Start).layoutWeight(1)
              Blank()
            }
            .width('100%').padding(16)
            .backgroundColor(C.card).borderRadius(18)
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

            Column() {
              Text(this.goods.emoji).fontSize(80)
            }
            .width('100%').height(220).borderRadius(18)
            .linearGradient({ angle: 135, colors: [[GRADIENTS[this.goods.grad].from, 0], [GRADIENTS[this.goods.grad].to, 1]] })
            .justifyContent(FlexAlign.Center)
            .margin({ top: 14 })

            Column() {
              Text('简介').fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.ink)
              Text(this.goods.desc).fontSize(13).fontColor(C.ink2).margin({ top: 8 }).lineHeight(22)
            }
            .width('100%').alignItems(HorizontalAlign.Start)
            .padding(16).margin({ top: 14 })
            .backgroundColor(C.card).borderRadius(18)
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

            Column() {
              Text('标签').fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.ink)
              Row() {
                Row() {
                  Text('¥').fontSize(11).fontColor(C.primary)
                  Text(`${this.goods.price}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.primary)
                }
                .backgroundColor(C.primarySoft).borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })

                Row() {
                  Text('📉').fontSize(12)
                  Text(this.goods.condition).fontSize(13).fontColor('#D97706').margin({ left: 4 })
                }
                .backgroundColor('#FEF3C7').borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ left: 10 })

                Row() {
                  Text('🏷️').fontSize(12)
                  Text(this.goods.category).fontSize(13).fontColor('#7C3AED').margin({ left: 4 })
                }
                .backgroundColor('#EDE9FE').borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ left: 10 })
              }
              .margin({ top: 10 })
            }
            .width('100%').alignItems(HorizontalAlign.Start)
            .padding(16).margin({ top: 14 })
            .backgroundColor(C.card).borderRadius(18)
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

            Column() {
              Row() {
                Text('商品评论').fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.ink)
                Blank()
                Text(`${this.commentList.length} 条`).fontSize(12).fontColor(C.ink3)
              }
              .width('100%').margin({ bottom: 4 })

              ForEach(this.commentList, (item: CommentItem, idx: number) => {
                this.CommentRow(item)
                if (idx < this.commentList.length - 1) {
                  Divider().color(C.line)
                }
              }, (item: CommentItem, idx: number) => `${idx}_${item.time}`)
            }
            .width('100%')
            .padding(16).margin({ top: 14 })
            .backgroundColor(C.card).borderRadius(18)
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

            Column() {
              Text('相似推荐').fontSize(15).fontWeight(FontWeight.Bold).fontColor(C.ink).margin({ bottom: 12 })
              List({ space: 12 }) {
                ForEach(this.getSimilar(), (item: GoodsItem, idx: number) => {
                  ListItem() {
                    this.SimilarCard(item)
                  }
                }, (item: GoodsItem, idx: number) => `${idx}_${item.name}`)
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
            }
            .width('100%').alignItems(HorizontalAlign.Start)
            .padding(16).margin({ top: 14, bottom: 80 })
            .backgroundColor(C.card).borderRadius(18)
            .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

            Column().height(20)
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 4 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row() {
          TextInput({ text: this.inputText, placeholder: '说点什么…' })
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
            .onClick(() => { this.sendComment() })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 10, bottom: 14 })
        .backgroundColor(C.card)
        .border({ width: { top: 1 }, color: { top: C.line } })
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
        .margin({ bottom: 70 })
        .transition({ type: TransitionType.All, opacity: 0, translate: { y: 20 } })
      }
    }
    .width('100%').height('100%')
  }
}