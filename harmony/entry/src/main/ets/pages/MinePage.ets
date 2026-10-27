import router from '@ohos.router';
import { C, MENU, MenuItem } from '../common/Constants';

@Component
export struct MinePage {
  @State nickName: string = '林小渡'
  @State bio: string = '热爱生活，闲置回血中～'
  @State editShow: boolean = false
  @State editName: string = ''
  @State editBio: string = ''
  @State toastMsg: string = ''
  @State toastShow: boolean = false
  private toastTimer: number = -1

  openEdit(): void {
    this.editName = this.nickName
    this.editBio = this.bio
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => { this.editShow = true })
  }

  closeEdit(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => { this.editShow = false })
  }

  saveEdit(): void {
    const n = this.editName.trim()
    const b = this.editBio.trim()
    if (n) this.nickName = n
    this.bio = b || '这个人很懒，什么都没留下～'
    this.closeEdit()
    this.showToast('资料已更新')
  }

  showToast(msg: string): void {
    this.toastMsg = msg
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = true })
    if (this.toastTimer !== -1) clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.toastShow = false })
    }, 2000)
  }

  onMenuClick(item: MenuItem): void {
    if (item.label === '我的发布' || item.label === '我的收藏' || item.label === '历史订单') {
      router.pushUrl({ url: 'pages/CategoryPage' })
    } else {
      this.showToast(`${item.label}功能开发中`)
    }
  }

  @Builder
  MenuItemRow(item: MenuItem) {
    Row() {
      Column() {
        Text(item.icon).fontSize(18)
      }
      .width(34).height(34).borderRadius(10)
      .backgroundColor(C.primarySoft)
      .justifyContent(FlexAlign.Center)

      Text(item.label)
        .fontSize(14).fontWeight(FontWeight.Medium).fontColor(C.ink)
        .margin({ left: 12 }).layoutWeight(1)

      if (item.sub.length > 0) {
        Text(item.sub).fontSize(12).fontColor(C.ink3)
      }
      Text('›').fontSize(18).fontColor(C.ink3).margin({ left: 6 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 15, bottom: 15 })
    .onClick(() => { this.onMenuClick(item) })
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('🦊').fontSize(34)
            }
            .width(64).height(64).borderRadius(32)
            .backgroundColor('rgba(255,255,255,0.22)')
            .border({ width: 2, color: 'rgba(255,255,255,0.4)' })
            .justifyContent(FlexAlign.Center)

            Column() {
              Text(this.nickName).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              Text(this.bio)
                .fontSize(12).fontColor('#FFFFFF').opacity(0.85)
                .margin({ top: 4 }).lineHeight(16)
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .margin({ left: 16 })
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .onClick(() => { this.openEdit() })

            Column() {
              Text('✎').fontSize(16).fontColor('#FFFFFF')
            }
            .width(34).height(34).borderRadius(17)
            .backgroundColor('rgba(255,255,255,0.18)')
            .justifyContent(FlexAlign.Center)
            .onClick(() => { this.openEdit() })
          }
          .width('100%')
          .padding(22)
          .borderRadius(22)
          .linearGradient({ angle: 135, colors: [[C.primary, 0], [C.primaryDeep, 1]] })
          .shadow({ radius: 24, color: 'rgba(27,110,156,0.28)', offsetY: 10 })

          Row() {
            Column() {
              Text('12').fontSize(20).fontWeight(FontWeight.Bold).fontColor(C.primary)
              Text('发布').fontSize(12).fontColor(C.ink3).margin({ top: 2 })
            }.layoutWeight(1).padding({ top: 14, bottom: 14 })
            .onClick(() => { router.pushUrl({ url: 'pages/CategoryPage' }) })
            Column() {
              Text('36').fontSize(20).fontWeight(FontWeight.Bold).fontColor(C.primary)
              Text('收藏').fontSize(12).fontColor(C.ink3).margin({ top: 2 })
            }.layoutWeight(1).padding({ top: 14, bottom: 14 })
            .onClick(() => { router.pushUrl({ url: 'pages/CategoryPage' }) })
            Column() {
              Text('88').fontSize(20).fontWeight(FontWeight.Bold).fontColor(C.primary)
              Text('关注').fontSize(12).fontColor(C.ink3).margin({ top: 2 })
            }.layoutWeight(1).padding({ top: 14, bottom: 14 })
            .onClick(() => { this.showToast('关注列表开发中') })
          }
          .width('100%')
          .margin({ top: 16 })
          .backgroundColor(C.card).borderRadius(16)
          .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })

          Column() {
            ForEach(MENU, (item: MenuItem, idx: number) => {
              this.MenuItemRow(item)
              if (idx < MENU.length - 1) {
                Divider().color(C.line).margin({ left: 18, right: 18 })
              }
            }, (item: MenuItem, idx: number) => `${idx}`)
          }
          .width('100%')
          .margin({ top: 16 })
          .backgroundColor(C.card).borderRadius(18)
          .shadow({ radius: 18, color: 'rgba(27,110,156,0.08)', offsetY: 6 })
          .clip(true)
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 18, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      if (this.editShow) {
        Stack() {
          Column()
            .width('100%').height('100%')
            .backgroundColor('rgba(20,30,45,0.45)')
            .onClick(() => { this.closeEdit() })

          Column() {
            Text('编辑个人资料')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(C.ink)
              .margin({ bottom: 16 })

            Column() {
              Text('昵称').fontSize(12).fontColor(C.ink3).margin({ bottom: 6 })
              TextInput({ text: this.editName })
                .fontSize(14).fontColor(C.ink)
                .height(40).borderRadius(12)
                .border({ width: 1.5, color: C.line })
                .backgroundColor(C.bg)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.editName = v })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 14 })
            .width('100%')

            Column() {
              Text('个人简介').fontSize(12).fontColor(C.ink3).margin({ bottom: 6 })
              TextInput({ text: this.editBio })
                .fontSize(14).fontColor(C.ink)
                .height(40).borderRadius(12)
                .border({ width: 1.5, color: C.line })
                .backgroundColor(C.bg)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.editBio = v })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            Row() {
              Text('取消')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor(C.ink2)
                .layoutWeight(1).height(42).borderRadius(12)
                .border({ width: 1.5, color: C.line })
                .backgroundColor(C.card)
                .textAlign(TextAlign.Center)
                .onClick(() => { this.closeEdit() })
              Text('保存')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                .layoutWeight(1).height(42).borderRadius(12)
                .linearGradient({ angle: 135, colors: [[C.primary, 0], [C.primaryDeep, 1]] })
                .textAlign(TextAlign.Center)
                .margin({ left: 10 })
                .onClick(() => { this.saveEdit() })
            }
            .width('100%')
            .margin({ top: 18 })
          }
          .width(300)
          .padding(22)
          .backgroundColor(C.card)
          .borderRadius(20)
          .shadow({ radius: 30, color: 'rgba(20,30,45,0.3)', offsetY: 10 })
        }
        .width('100%').height('100%')
        .transition({ type: TransitionType.All, opacity: 0 })
      }

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
        .margin({ bottom: 40 })
        .transition({ type: TransitionType.All, opacity: 0, translate: { y: 20 } })
      }
    }
    .width('100%').height('100%')
  }
}