import { common } from '@kit.AbilityKit';
import { nexiApi } from '../common/api/NexiApiService';
import { API_BASE_URL } from '../common/config/ApiConfig';
import { PrivacyPreferences } from '../common/storage/PrivacyPreferences';
import { GraphNode, GraphResponse, EMPTY_GRAPH, LinkSettingsResponse, LinkSettingsUpdate, DEFAULT_LINK_SETTINGS } from '../common/model/GraphTypes';
import { ClayInput } from '../components/ClayInput';
import { GraphCanvas } from '../components/GraphCanvas';
import { LinkSettingsPanel } from '../components/LinkSettingsPanel';
import { getNodeRelations, NodeDetailPanel, NodeRelation } from '../components/NodeDetailPanel';
import { PrivacyGateOverlay } from '../components/PrivacyGateOverlay';
import { formatLinkStrategy } from '../common/util/StrategyLabel';

@Entry
@Component
struct Index {
  @State noteInput: string = '';
  @State isLoading: boolean = false;
  @State statusText: string = '';
  @State graphData: GraphResponse = EMPTY_GRAPH;
  @State highlightNodeId: number = -1;
  @State selectedNode: GraphNode | null = null;
  @State nodeRelations: NodeRelation[] = [];
  @State showDetail: boolean = false;
  @State appReady: boolean = false;
  @State showPrivacyGate: boolean = false;
  @State showGraph: boolean = false;
  @State showSettings: boolean = false;
  @State linkSettings: LinkSettingsResponse = DEFAULT_LINK_SETTINGS;

  aboutToAppear(): void {
    this.checkPrivacyAndBootstrap();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Text('Nexi')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E0E0FF')
          Blank()
          if (this.appReady) {
            Button({ type: ButtonType.Circle }) {
              Text('⚙')
                .fontSize(16)
                .fontColor('#888899')
            }
            .width(36)
            .height(36)
            .backgroundColor('#FFFFFF10')
            .margin({ right: 8 })
            .onClick(() => this.openSettings())
          }
          if (this.appReady && this.graphData.nodes.length > 0) {
            Text(`${this.graphData.nodes.length} 节点 · ${this.graphData.edges.length} 边`)
              .fontSize(12)
              .fontColor('#555577')
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12 })

        if (this.statusText.length > 0) {
          Text(this.statusText)
            .fontSize(12)
            .fontColor(this.appReady ? '#80FFAA' : '#FF8080')
            .width('100%')
            .padding({ left: 20, right: 20, top: 4 })
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.appReady && this.showGraph) {
          GraphCanvas({
            graphData: this.graphData,
            highlightNodeId: this.highlightNodeId,
            onNodeSelected: (nodeId: number) => this.onNodeSelected(nodeId)
          })
            .layoutWeight(1)
            .width('100%')
        } else if (this.appReady) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#6C5CE7')
            Text('正在加载图谱…')
              .fontSize(14)
              .fontColor('#555577')
              .margin({ top: 12 })
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color('#6C5CE7')
            Text('正在初始化…')
              .fontSize(14)
              .fontColor('#555577')
              .margin({ top: 12 })
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0D0D14')

      if (this.appReady) {
        Column() {
          if (this.showDetail && this.selectedNode !== null) {
            NodeDetailPanel({
              node: this.selectedNode,
              relations: this.nodeRelations,
              onClose: () => this.closeDetail(),
              onPeerClick: (nodeId: number) => this.onNodeSelected(nodeId)
            })
          }

          ClayInput({
            text: $noteInput,
            isLoading: this.isLoading,
            placeholder: '倒进去就行…',
            onSubmit: () => this.uploadNote()
          })
            .padding({ left: 16, right: 16, bottom: 24, top: 8 })
        }
        .width('100%')
      }

      if (this.showPrivacyGate) {
        PrivacyGateOverlay({
          onAgree: () => this.onPrivacyAccepted(),
          onDecline: () => this.onPrivacyDeclined()
        })
      }

      if (this.showSettings) {
        Column() {
          Blank()
          LinkSettingsPanel({
            settings: this.linkSettings,
            onSave: (update: LinkSettingsUpdate) => this.saveLinkSettings(update),
            onClose: () => { this.showSettings = false; }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#99000000')
      }
    }
    .width('100%')
    .height('100%')
  }

  private async checkPrivacyAndBootstrap(): Promise<void> {
    try {
      const context = getContext(this) as Context;
      const accepted = await PrivacyPreferences.isAccepted(context);
      if (accepted) {
        await this.onPrivacyAccepted();
      } else {
        this.showPrivacyGate = true;
      }
    } catch (err) {
      this.statusText = `初始化失败：${(err as Error).message}`;
    }
  }

  private async onPrivacyAccepted(): Promise<void> {
    this.showPrivacyGate = false;

    const context = getContext(this) as Context;
    await PrivacyPreferences.setAccepted(context, true);
    this.appReady = true;
    await this.bootstrapApp();
    setTimeout(() => {
      this.showGraph = true;
    }, 300);
  }

  private onPrivacyDeclined(): void {
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }

  private async bootstrapApp(): Promise<void> {
    try {
      await nexiApi.healthCheck();
      this.linkSettings = await nexiApi.getLinkSettings();
      this.statusText = '';
      await this.loadGraph();
    } catch (_err) {
      this.statusText =
        `无法连接后端 ${API_BASE_URL}\n请确认 backend 已启动（./run.sh）` +
        (API_BASE_URL.includes('10.0.2.2')
          ? '；模拟器勿用 127.0.0.1，应走 10.0.2.2'
          : API_BASE_URL.includes('127.0.0.1')
            ? '；真机请改 ApiConfig API_TARGET 为 device'
            : '');
    }
  }

  private onNodeSelected(nodeId: number): void {
    const node = this.graphData.nodes.find((n: GraphNode) => n.id === nodeId);
    if (!node) {
      return;
    }
    this.selectedNode = node;
    this.nodeRelations = getNodeRelations(nodeId, this.graphData);
    this.showDetail = true;
    this.highlightNodeId = nodeId;
  }

  private closeDetail(): void {
    this.showDetail = false;
    this.selectedNode = null;
    this.nodeRelations = [];
  }

  private async uploadNote(): Promise<void> {
    const content = this.noteInput.trim();
    if (content.length === 0 || this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.statusText = '正在分析语义并调用 AI 匹配关联…';
    this.closeDetail();

    try {
      const result = await nexiApi.uploadNote(content);
      this.noteInput = '';
      this.highlightNodeId = result.id;
      const strategyLabel = formatLinkStrategy(result.strategy);
      this.statusText = result.links.length > 0
        ? `已录入 #${result.id} · ${strategyLabel} · ${result.links.length} 条关联`
        : `已录入 #${result.id} · ${strategyLabel}`;
      await this.loadGraph();
    } catch (err) {
      this.statusText = `录入失败：${(err as Error).message}`;
    } finally {
      this.isLoading = false;
    }
  }

  private async loadGraph(): Promise<void> {
    try {
      this.graphData = await nexiApi.getGraph();
    } catch (err) {
      this.statusText = `图谱加载失败：${(err as Error).message}`;
    }
  }

  private async openSettings(): Promise<void> {
    try {
      this.linkSettings = await nexiApi.getLinkSettings();
      this.showSettings = true;
    } catch (err) {
      this.statusText = `读取设置失败：${(err as Error).message}`;
    }
  }

  private async saveLinkSettings(update: LinkSettingsUpdate): Promise<void> {
    this.linkSettings = await nexiApi.updateLinkSettings(update);
  }
}
