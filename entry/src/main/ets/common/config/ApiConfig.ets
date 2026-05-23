/**
 * 后端 API 地址配置
 *
 * API_TARGET 说明：
 * - emulator：DevEco 本地模拟器 → 用 10.0.2.2（映射到电脑的 127.0.0.1）
 * - preview：DevEco 预览器 → 用 127.0.0.1
 * - device：真机 → 用电脑局域网 IP（DEV_LAN_HOST）
 *
 * 启动后端：cd backend && ./run.sh
 */
export type ApiTarget = 'emulator' | 'preview' | 'device';

/** 当前调试目标，模拟器请保持 emulator */
export const API_TARGET: ApiTarget = 'emulator';

/** 真机调试时填电脑局域网 IP（终端执行 ipconfig getifaddr en0） */
export const DEV_LAN_HOST: string = '192.168.137.7';

export const BACKEND_PORT: number = 8000;

export const API_TIMEOUT_MS: number = 15000;

function buildApiBaseUrl(): string {
  if (API_TARGET === 'emulator') {
    return `http://10.0.2.2:${BACKEND_PORT}/api`;
  }
  if (API_TARGET === 'device') {
    return `http://${DEV_LAN_HOST}:${BACKEND_PORT}/api`;
  }
  return `http://127.0.0.1:${BACKEND_PORT}/api`;
}

export const API_BASE_URL: string = buildApiBaseUrl();
