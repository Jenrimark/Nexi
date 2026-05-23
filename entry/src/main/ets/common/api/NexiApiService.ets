import http from '@ohos.net.http';
import { API_BASE_URL, API_TIMEOUT_MS } from '../config/ApiConfig';
import {
  GraphResponse,
  HealthResponse,
  HttpJsonHeader,
  UploadNoteRequest,
  UploadNoteResponse
} from '../model/GraphTypes';

export class NexiApiService {
  private baseUrl: string;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
  }

  async healthCheck(): Promise<HealthResponse> {
    return this.request<HealthResponse>(http.RequestMethod.GET, '/health');
  }

  async uploadNote(content: string): Promise<UploadNoteResponse> {
    const body: UploadNoteRequest = { content: content };
    return this.request<UploadNoteResponse>(http.RequestMethod.POST, '/upload_note', body);
  }

  async getGraph(): Promise<GraphResponse> {
    return this.request<GraphResponse>(http.RequestMethod.GET, '/get_graph');
  }

  private async request<T>(
    method: http.RequestMethod,
    path: string,
    body?: UploadNoteRequest
  ): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const header: HttpJsonHeader = { 'Content-Type': 'application/json' };
      const options: http.HttpRequestOptions = {
        method: method,
        header: header,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: API_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_MS,
        expectDataType: http.HttpDataType.STRING
      };
      const response = await httpRequest.request(`${this.baseUrl}${path}`, options);

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }

      return JSON.parse(response.result as string) as T;
    } finally {
      httpRequest.destroy();
    }
  }
}

export const nexiApi = new NexiApiService();
