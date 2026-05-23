import { GraphEdge, GraphNode, GraphResponse } from '../common/model/GraphTypes';

export interface NodeRelation {
  peerId: number;
  peerContent: string;
  similarity: number;
  relation: string;
  reason: string;
  direction: 'out' | 'in';
}

export function getNodeRelations(nodeId: number, graph: GraphResponse): NodeRelation[] {
  const nodeMap = new Map<number, GraphNode>();
  graph.nodes.forEach((n: GraphNode) => nodeMap.set(n.id, n));

  const relations: NodeRelation[] = [];
  graph.edges.forEach((edge: GraphEdge) => {
    if (edge.source === nodeId) {
      const peer = nodeMap.get(edge.target);
      relations.push({
        peerId: edge.target,
        peerContent: peer?.content ?? `#${edge.target}`,
        similarity: edge.similarity,
        relation: edge.relation,
        reason: edge.reason,
        direction: 'out'
      });
    } else if (edge.target === nodeId) {
      const peer = nodeMap.get(edge.source);
      relations.push({
        peerId: edge.source,
        peerContent: peer?.content ?? `#${edge.source}`,
        similarity: edge.similarity,
        relation: edge.relation,
        reason: edge.reason,
        direction: 'in'
      });
    }
  });

  relations.sort((a, b) => b.similarity - a.similarity);
  return relations;
}

export function buildRelationSummary(relations: NodeRelation[]): string {
  if (relations.length === 0) {
    return '暂无关联节点，继续录入相关内容后会自动建立连接。';
  }

  const top = relations[0];
  if (top.reason.length > 0) {
    return top.reason;
  }
  if (top.relation.length > 0) {
    return `${top.relation}（相似度 ${Math.round(top.similarity * 100)}%），共 ${relations.length} 条关联。`;
  }
  const simPct = Math.round(top.similarity * 100);
  return `与「${truncate(top.peerContent, 20)}」语义最接近（相似度 ${simPct}%），共 ${relations.length} 条关联。`;
}

function truncate(text: string, max: number): string {
  if (text.length <= max) {
    return text;
  }
  return `${text.slice(0, max)}…`;
}

@Component
export struct NodeDetailPanel {
  @Prop node: GraphNode | null = null;
  @Prop relations: NodeRelation[] = [];
  onClose: () => void = () => {};
  onPeerClick: (nodeId: number) => void = () => {};

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(`节点 #${this.node?.id ?? ''}`)
            .fontSize(12)
            .fontColor('#6C5CE7')
            .fontWeight(FontWeight.Medium)
          Text(this.node?.content ?? '')
            .fontSize(16)
            .fontColor('#E8E8F8')
            .fontWeight(FontWeight.Bold)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button({ type: ButtonType.Circle }) {
          Text('✕')
            .fontSize(14)
            .fontColor('#888899')
        }
        .width(32)
        .height(32)
        .backgroundColor('#FFFFFF10')
        .onClick(() => this.onClose())
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(this.node?.created_at ?? '')
        .fontSize(11)
        .fontColor('#555566')
        .margin({ top: 8 })

      Divider()
        .color('#FFFFFF12')
        .margin({ top: 12, bottom: 12 })

      Text('关联理由')
        .fontSize(13)
        .fontColor('#00CEC9')
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Text(buildRelationSummary(this.relations))
        .fontSize(13)
        .fontColor('#A0A0C0')
        .lineHeight(20)
        .margin({ top: 6 })
        .width('100%')

      if (this.relations.length > 0) {
        List({ space: 8 }) {
          ForEach(this.relations, (rel: NodeRelation) => {
            ListItem() {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(`${Math.round(rel.similarity * 100)}%`)
                    .fontSize(12)
                    .fontColor('#00CEC9')
                    .width(36)
                  Text(truncate(rel.peerContent, 24))
                    .fontSize(13)
                    .fontColor('#C8C8E0')
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                if (rel.relation.length > 0) {
                  Text(rel.relation)
                    .fontSize(11)
                    .fontColor('#6C5CE7')
                    .width('100%')
                    .padding({ left: 44 })
                }
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .onClick(() => this.onPeerClick(rel.peerId))
            }
          }, (rel: NodeRelation) => `${rel.peerId}_${rel.direction}`)
        }
        .width('100%')
        .height(Math.min(this.relations.length * 56, 200))
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#161622F0')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .border({ width: { top: 1 }, color: '#FFFFFF18' })
    .shadow({ radius: 24, color: '#00000080', offsetY: -4 })
  }
}
