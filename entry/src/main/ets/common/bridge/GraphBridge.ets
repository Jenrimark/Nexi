export class GraphBridge {
  onNodeClickCallback: (nodeId: number) => void = () => {};

  onNodeClick(nodeId: string): void {
    const id = parseInt(nodeId, 10);
    if (!isNaN(id)) {
      this.onNodeClickCallback(id);
    }
  }
}
