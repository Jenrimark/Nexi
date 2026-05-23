@Component
export struct ClayInput {
  @Link text: string;
  @Prop isLoading: boolean = false;
  @Prop placeholder: string = '倒进去就行…';
  onSubmit: () => void = () => {};

  @State isPressed: boolean = false;
  @State isFocused: boolean = false;

  build() {
    Column() {
      Row() {
        TextInput({
          text: this.text,
          placeholder: this.placeholder
        })
          .layoutWeight(1)
          .height(52)
          .fontSize(16)
          .fontColor('#E8E8F8')
          .placeholderColor('#666680')
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .padding({ left: 4, right: 4 })
          .onChange((value: string) => {
            this.text = value;
          })
          .onFocus(() => {
            this.isFocused = true;
          })
          .onBlur(() => {
            this.isFocused = false;
          })
          .onSubmit(() => {
            if (!this.isLoading && this.text.trim().length > 0) {
              this.onSubmit();
            }
          })

        Button({ type: ButtonType.Circle }) {
          if (this.isLoading) {
            LoadingProgress()
              .width(22)
              .height(22)
              .color('#6C5CE7')
          } else {
            Text('↑')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
        }
        .width(44)
        .height(44)
        .backgroundColor('#6C5CE7')
        .enabled(!this.isLoading && this.text.trim().length > 0)
        .onClick(() => this.onSubmit())
      }
      .width('100%')
      .padding({ left: 16, right: 8, top: 8, bottom: 8 })
    }
    .width('100%')
    .borderRadius(20)
    .backgroundColor(this.isPressed ? '#1A1A28' : '#222233')
    .border({
      width: 1,
      color: this.isFocused ? '#6C5CE766' : '#FFFFFF14'
    })
    .shadow({
      radius: this.isPressed ? 8 : 20,
      color: this.isPressed ? '#00000040' : '#FFFFFF0A',
      offsetX: this.isPressed ? 1 : -3,
      offsetY: this.isPressed ? 2 : 4
    })
    .scale({
      x: this.isPressed ? 0.98 : 1.0,
      y: this.isPressed ? 0.98 : 1.0
    })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }
}
