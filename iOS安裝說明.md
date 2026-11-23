# 一久防水 iOS 安裝版（iPhone／iPad）

此版本與 Android 共用同一套程式及 Supabase 雲端資料庫；不是另一套獨立資料庫。iOS 不需要 APK，也不需要上架 App Store，使用 Safari 將 PWA 加到主畫面。

## 1. 先完成一次網站部署
1. 將此資料夾部署到支援 HTTPS 的靜態網站主機（例如 Cloudflare Pages 或 Netlify）。
2. 在 `config.js` 填入 Supabase Project URL 與 anon/public key。
3. 在 Supabase SQL Editor 執行 `supabase-schema.sql`。
4. 開啟部署後的 HTTPS 網址，先註冊／登入並測試新增報價及雲端同步。

## 2. iPhone 安裝步驟
1. 在 iPhone 使用 **Safari** 開啟網站 HTTPS 網址（不要用 LINE 或其他 App 的內建瀏覽器）。
2. 點 Safari 下方的「分享」圖示（方框向上箭頭）。
3. 向下找到「加入主畫面」。
4. 名稱輸入「一久防水」，確認「以網頁 App 方式開啟」（若畫面有此選項）。
5. 點右上角「新增」。桌面會出現一久防水圖示。
6. 從桌面圖示開啟，使用同一個 Supabase 帳號登入。

## 3. iPad 安裝
以 Safari 開啟 HTTPS 網址 → 分享 → 加入主畫面 → 新增。

## 4. Android 與 iOS 共用資料
- Android Chrome 與 iPhone Safari 都使用相同網站網址及 Supabase 專案。
- 兩邊登入同一帳號，工程估價資料可跨裝置同步。
- 不要把 `service_role` key 放進 `config.js`；只使用 anon/public key。
- 本版本採每個帳號個人資料隔離。若要你與弟弟共用同一公司工程資料，下一版需加入公司／團隊成員與角色權限，不能單純共用個人帳號。

## 5. iOS 使用注意
- PWA 可加入主畫面並以獨立視窗開啟，但它不是 App Store 原生 App。
- 離線時可載入快取介面；雲端資料讀寫仍需網路。
- PDF 估價單會使用 iOS 列印／分享流程；可在預覽畫面用分享功能存到「檔案」或傳送給客戶。
- 第一次部署後若已安裝舊版，更新網站後可關閉再重開；必要時刪除主畫面圖示後重新加入。
