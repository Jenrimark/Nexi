import { webview } from '@kit.ArkWeb';
import { GraphBridge } from '../common/bridge/GraphBridge';
import { GraphResponse, EMPTY_GRAPH } from '../common/model/GraphTypes';

@Component
export struct GraphCanvas {
  @Prop @Watch('onGraphChange') graphData: GraphResponse = EMPTY_GRAPH;
  @Prop @Watch('onGraphChange') highlightNodeId: number = -1;
  onNodeSelected: (nodeId: number) => void = () => {};

  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: GraphBridge = new GraphBridge();
  private pageReady: boolean = false;

  aboutToAppear(): void {
    this.bridge.onNodeClickCallback = (nodeId: number) => {
      this.onNodeSelected(nodeId);
    };
  }

  aboutToDisappear(): void {
    try {
      this.controller.deleteJavaScriptRegister('NexiBridge');
    } catch (_e) {
      // ignore if not registered
    }
  }

  build() {
    Web({ src: $rawfile('graph.html'), controller: this.controller })
      .width('100%')
      .height('100%')
      .backgroundColor('#0D0D14')
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .imageAccess(true)
      .onlineImageAccess(true)
      .javaScriptProxy({
        object: this.bridge,
        name: 'NexiBridge',
        methodList: ['onNodeClick'],
        controller: this.controller
      })
      .onPageEnd(() => {
        this.pageReady = true;
        this.pushGraphData();
      })
  }

  private onGraphChange(): void {
    if (this.pageReady) {
      this.pushGraphData();
    }
  }

  private pushGraphData(): void {
    const payload = JSON.stringify(this.graphData);
    const escaped = JSON.stringify(payload);
    if (this.highlightNodeId > 0) {
      this.controller.runJavaScript(`highlightNode('${this.highlightNodeId}')`);
    }
    this.controller.runJavaScript(`setGraphData(${escaped})`);
  }
}
