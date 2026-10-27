import router from '@ohos.router';
import { C } from '../common/Constants';
import { RecommendPage } from './RecommendPage';
import { CirclePage } from './CirclePage';
import { MessagePage } from './MessagePage';
import { MinePage } from './MinePage';

interface TabItem {
  icon: string
  label: string
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State currentTime: string = '9:41'
  private timerId: number = -1

  private tabs: TabItem[] = [
    { icon: '🏠', label: '推荐' },
    { icon: '👥', label: '圈子' },
    { icon: '💬', label: '消息' },
    { icon: '👤', label: '我的' }
  ]

  aboutToAppear(): void {
    this.updateTime()
    this.timerId = setInterval(() => { this.updateTime() }, 30000)
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  updateTime(): void {
    const d = new Date()
    const h = d.getHours()
    const m = d.getMinutes()
    this.currentTime = `${h}:${m < 10 ? '0' + m : m}`
  }

  @Builder
  StatusBar() {
    Row() {
      Text(this.currentTime)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(C.ink)

      Blank()

      Row() {
        Row() {
          Column().width(2).height(4).backgroundColor(C.ink).borderRadius(1)
          Column().width(2).height(6).backgroundColor(C.ink).borderRadius(1)
          Column().width(2).height(8).backgroundColor(C.ink).borderRadius(1)
          Column().width(2).height(10).backgroundColor(C.ink).borderRadius(1)
        }
        .alignItems(VerticalAlign.Bottom)
        .gap(2)
        .height(10)

        Text("WiFi").fontSize(9).fontColor(C.ink).margin({ left: 6 })

        Row() {
          Column()
            .width(18).height(9)
            .border({ width: 1, color: C.ink })
            .borderRadius(2)
          Column()
            .width(2).height(4)
            .backgroundColor(C.ink)
            .borderRadius(1)
            .margin({ left: 1 })
        }
        .alignItems(VerticalAlign.Center)
        .margin({ left: 6 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(34)
    .padding({ left: 26, right: 26 })
    .backgroundColor(C.bg)
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(this.tabs, (tab: TabItem, i: number) => {
        Column() {
          Text(tab.icon)
            .fontSize(22)
            .translateY(this.currentTab === i ? -3 : 0)
            .animation({ duration: 250, curve: Curve.EaseOut })
          Text(tab.label)
            .fontSize(11)
            .fontWeight(this.currentTab === i ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === i ? C.primary : C.ink3)
            .margin({ top: 3 })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
            this.currentTab = i
          })
        })
      }, (tab: TabItem, i: number) => `${i}`)
    }
    .width('100%')
    .height(62)
    .backgroundColor(C.card)
    .border({ width: { top: 1 }, color: { top: C.line } })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.StatusBar()

        Stack() {
          RecommendPage({
            onGoCategory: (): void => {
              router.pushUrl({ url: 'pages/CategoryPage' })
            }
          })
            .opacity(this.currentTab === 0 ? 1 : 0)
            .visibility(this.currentTab === 0 ? Visibility.Visible : Visibility.Hidden)

          CirclePage()
            .opacity(this.currentTab === 1 ? 1 : 0)
            .visibility(this.currentTab === 1 ? Visibility.Visible : Visibility.Hidden)

          MessagePage()
            .opacity(this.currentTab === 2 ? 1 : 0)
            .visibility(this.currentTab === 2 ? Visibility.Visible : Visibility.Hidden)

          MinePage()
            .opacity(this.currentTab === 3 ? 1 : 0)
            .visibility(this.currentTab === 3 ? Visibility.Visible : Visibility.Hidden)
        }
        .layoutWeight(1)
        .width('100%')
        .alignContent(Alignment.Top)

        this.TabBar()
      }
      .width(420)
      .height(780)
      .borderRadius(44)
      .backgroundColor(C.bg)
      .border({ width: 10, color: '#1C2630' })
      .shadow({ radius: 60, color: 'rgba(20,50,80,0.35)', offsetX: 0, offsetY: 20 })
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#EEF3F8', 0], ['#E6EDF5', 1]] })
  }
}