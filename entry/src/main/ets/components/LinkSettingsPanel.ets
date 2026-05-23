import { LinkMode, LinkSettingsResponse, LinkSettingsUpdate, DEFAULT_LINK_SETTINGS } from '../common/model/GraphTypes';

@Component
export struct LinkSettingsPanel {
  @Prop settings: LinkSettingsResponse = DEFAULT_LINK_SETTINGS;
  @State mode: LinkMode = 'hybrid';
  @State topK: string = '8';
  @State useDefaultLlm: boolean = true;
  @State llmBaseUrl: string = '';
  @State llmModel: string = 'deepseek-chat';
  @State llmApiKey: string = '';
  @State saving: boolean = false;
  @State message: string = '';

  onSave: (update: LinkSettingsUpdate) => Promise<void> = async () => {};
  onClose: () => void = () => {};

  aboutToAppear(): void {
    this.mode = this.settings.mode;
    this.topK = `${this.settings.top_k}`;
    this.useDefaultLlm = this.settings.use_default_llm;
    this.llmBaseUrl = this.settings.llm_base_url;
    this.llmModel = this.settings.llm_model;
  }

  build() {
    Column() {
      Row() {
        Text('关联策略')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E0E0FF')
        Blank()
        Button({ type: ButtonType.Circle }) {
          Text('✕').fontSize(14).fontColor('#888899')
        }
        .width(32)
        .height(32)
        .backgroundColor('#FFFFFF10')
        .onClick(() => this.onClose())
      }
      .width('100%')

      Text(this.settings.llm_available ? 'LLM 已就绪' : 'LLM 未配置，将自动降级为向量关联')
        .fontSize(12)
        .fontColor(this.settings.llm_available ? '#80FFAA' : '#FFAA80')
        .width('100%')
        .margin({ top: 8 })

      Text('关联模式')
        .fontSize(13)
        .fontColor('#A0A0C0')
        .width('100%')
        .margin({ top: 16 })

      Row({ space: 8 }) {
        this.modeChip('hybrid', '混合')
        this.modeChip('vector_only', '仅向量')
        this.modeChip('custom_llm', '自定义')
      }
      .width('100%')
      .margin({ top: 8 })

      Text('向量候选数 Top-K')
        .fontSize(13)
        .fontColor('#A0A0C0')
        .width('100%')
        .margin({ top: 16 })

      TextInput({ text: this.topK, placeholder: '8' })
        .type(InputType.Number)
        .width('100%')
        .height(44)
        .borderRadius(10)
        .backgroundColor('#1E1E2E')
        .fontColor('#FFFFFF')
        .onChange((v: string) => { this.topK = v; })

      if (this.mode !== 'vector_only') {
        Row() {
          Text('使用后端默认 LLM')
            .fontSize(13)
            .fontColor('#C8C8E0')
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: this.useDefaultLlm })
            .onChange((on: boolean) => { this.useDefaultLlm = on; })
        }
        .width('100%')
        .margin({ top: 16 })

        if (!this.useDefaultLlm) {
          Text('API Base URL')
            .fontSize(13)
            .fontColor('#A0A0C0')
            .width('100%')
            .margin({ top: 12 })
          TextInput({ text: this.llmBaseUrl, placeholder: 'https://api.deepseek.com' })
            .width('100%')
            .height(44)
            .borderRadius(10)
            .backgroundColor('#1E1E2E')
            .fontColor('#FFFFFF')
            .onChange((v: string) => { this.llmBaseUrl = v; })

          Text('Model')
            .fontSize(13)
            .fontColor('#A0A0C0')
            .width('100%')
            .margin({ top: 12 })
          TextInput({ text: this.llmModel, placeholder: 'deepseek-chat' })
            .width('100%')
            .height(44)
            .borderRadius(10)
            .backgroundColor('#1E1E2E')
            .fontColor('#FFFFFF')
            .onChange((v: string) => { this.llmModel = v; })
        }

        Text('API Key（留空则不修改）')
          .fontSize(13)
          .fontColor('#A0A0C0')
          .width('100%')
          .margin({ top: 12 })
        TextInput({ text: this.llmApiKey, placeholder: 'sk-...' })
          .type(InputType.Password)
          .width('100%')
          .height(44)
          .borderRadius(10)
          .backgroundColor('#1E1E2E')
          .fontColor('#FFFFFF')
          .onChange((v: string) => { this.llmApiKey = v; })
      }

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(12)
          .fontColor('#80FFAA')
          .width('100%')
          .margin({ top: 8 })
      }

      Button(this.saving ? '保存中…' : '保存设置')
        .width('100%')
        .height(44)
        .margin({ top: 20 })
        .backgroundColor('#6C5CE7')
        .enabled(!this.saving)
        .onClick(() => this.handleSave())
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#161622')
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  modeChip(value: LinkMode, label: string) {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .fontSize(13)
      .fontColor(this.mode === value ? '#FFFFFF' : '#888899')
      .backgroundColor(this.mode === value ? '#6C5CE7' : '#2A2A3A')
      .onClick(() => { this.mode = value; })
  }

  private async handleSave(): Promise<void> {
    const parsedTopK = parseInt(this.topK, 10);
    const topK = isNaN(parsedTopK) ? 8 : Math.max(3, Math.min(20, parsedTopK));

    const update: LinkSettingsUpdate = {
      mode: this.mode,
      top_k: topK,
      use_default_llm: this.useDefaultLlm,
      llm_base_url: this.llmBaseUrl.trim(),
      llm_model: this.llmModel.trim()
    };
    if (this.llmApiKey.trim().length > 0) {
      update.llm_api_key = this.llmApiKey.trim();
    }

    this.saving = true;
    this.message = '';
    try {
      await this.onSave(update);
      this.message = '已保存';
      this.llmApiKey = '';
    } catch (err) {
      this.message = `保存失败：${(err as Error).message}`;
    } finally {
      this.saving = false;
    }
  }
}
