const PRIVACY_CONTENT: string =
  '欢迎使用 Nexi。在使用本应用前，请仔细阅读以下条款：\n\n' +
  '一、数据收集与使用\n' +
  '1. 您输入的笔记内容仅用于本地知识图谱构建与 AI 语义关联。\n' +
  '2. 笔记数据存储在本地 SQLite 数据库，不会上传至第三方云端。\n' +
  '3. 向量化计算在本地后端服务完成（Ollama / 开发模式 mock）。\n\n' +
  '二、网络权限\n' +
  '1. 应用需访问网络以连接本地后端 API 及加载图谱渲染组件。\n' +
  '2. 我们不会收集您的设备标识符用于广告追踪。\n\n' +
  '三、用户权利\n' +
  '1. 您可随时删除本地数据（卸载应用即可清除）。\n' +
  '2. 拒绝本协议将无法使用应用核心功能。\n\n' +
  '四、免责声明\n' +
  'AI 自动关联结果仅供参考，不构成专业建议。\n\n' +
  '点击「同意并继续」即表示您已阅读并同意《用户协议》与《隐私政策》。';

@Component
export struct PrivacyGateOverlay {
  onAgree: () => void = () => {};
  onDecline: () => void = () => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')

      Column() {
        Text('用户协议与隐私政策')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E0E0FF')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 12 })

        Scroll() {
          Text(PRIVACY_CONTENT)
            .fontSize(13)
            .fontColor('#A0A0C0')
            .lineHeight(22)
            .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)

        Row({ space: 12 }) {
          Button('拒绝')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#C8C8E0')
            .backgroundColor('#2A2A3A')
            .borderRadius(12)
            .onClick(() => this.onDecline())

          Button('同意并继续')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#6C5CE7')
            .borderRadius(12)
            .onClick(() => this.onAgree())
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
      }
      .width('88%')
      .height('72%')
      .backgroundColor('#161622')
      .borderRadius(16)
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
  }
}
