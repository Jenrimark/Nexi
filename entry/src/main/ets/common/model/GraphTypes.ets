export interface GraphLink {
  target_id: number;
  similarity: number;
}

export interface UploadNoteRequest {
  content: string;
}

export interface UploadNoteResponse {
  id: number;
  links: GraphLink[];
}

export interface GraphNode {
  id: number;
  content: string;
  created_at: string;
}

export interface GraphEdge {
  source: number;
  target: number;
  relation: string;
  similarity: number;
}

export interface GraphResponse {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface HealthResponse {
  status: string;
}

export interface HttpJsonHeader {
  'Content-Type': string;
}

export const EMPTY_GRAPH: GraphResponse = { nodes: [], edges: [] };
