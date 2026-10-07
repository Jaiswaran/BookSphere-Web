export const AUTHOR_SHARE = 0.70;
export const PLATFORM_SHARE = 0.30;

export function revenueSplit(price: number) {
  const amount = Math.max(0, Number(price) || 0);
  return {
    author: Number((amount * AUTHOR_SHARE).toFixed(2)),
    platform: Number((amount * PLATFORM_SHARE).toFixed(2))
  };
}
