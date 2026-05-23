export function formatLinkStrategy(strategy: string): string {
  if (strategy === 'llm') {
    return 'AI 已分析关联';
  }
  if (strategy === 'vector_fallback') {
    return 'AI 未生效，已用向量关联';
  }
  if (strategy === 'vector_only') {
    return '仅向量模式';
  }
  return strategy;
}
