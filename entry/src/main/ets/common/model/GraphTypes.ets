export type LinkMode = 'hybrid' | 'vector_only' | 'custom_llm';

export interface GraphLink {
  target_id: number;
  similarity: number;
  relation: string;
  reason: string;
}

export interface UploadNoteRequest {
  content: string;
}

export interface UploadNoteResponse {
  id: number;
  links: GraphLink[];
  strategy: string;
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
  reason: string;
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

export interface LinkSettingsResponse {
  mode: LinkMode;
  top_k: number;
  use_default_llm: boolean;
  llm_base_url: string;
  llm_model: string;
  has_llm_api_key: boolean;
  llm_available: boolean;
}

export interface LinkSettingsUpdate {
  mode: LinkMode;
  top_k: number;
  use_default_llm: boolean;
  llm_base_url: string;
  llm_model: string;
  llm_api_key?: string;
}

export const EMPTY_GRAPH: GraphResponse = { nodes: [], edges: [] };

export const DEFAULT_LINK_SETTINGS: LinkSettingsResponse = {
  mode: 'hybrid',
  top_k: 8,
  use_default_llm: true,
  llm_base_url: '',
  llm_model: 'deepseek-chat',
  has_llm_api_key: false,
  llm_available: false
};
