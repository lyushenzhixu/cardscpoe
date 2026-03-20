# CardScope API Key 申请与配置

## 1) eBay Developer API

1. 打开: https://developer.ebay.com/
2. 注册开发者账号并创建应用。
3. 获取 `App ID`，并配置 OAuth token 流程。
4. 申请 Production 权限（通常 1-2 周）。
5. 将服务端凭据仅配置在 Supabase Edge Function 的 Secret 中，不要写入 iOS 客户端。

## 2) PriceCharting API

1. 打开: https://www.pricecharting.com/api
2. 注册并获取 API Key。
3. 将 Key 写入 Xcode Build Settings 的 `INFOPLIST_KEY_PRICECHARTING_API_KEY`（仅开发环境）。

## 3) Supabase

1. 在 Supabase 项目中执行 `supabase/migrations/20260313_cardscope_schema.sql`。
2. 部署 Edge Function: `supabase/functions/fetch-prices/index.ts`。
3. 复制 Project URL 和 anon key。
4. 在 Xcode Build Settings 中配置：
   - `INFOPLIST_KEY_SUPABASE_URL`
   - `INFOPLIST_KEY_SUPABASE_ANON_KEY`

## 4) 运行前检查

- `INFOPLIST_KEY_NSCameraUsageDescription` / `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` 已设置。
- 未申请到真实 key 时，App 会自动 fallback 到本地 MockData + OCR 识别流程。
