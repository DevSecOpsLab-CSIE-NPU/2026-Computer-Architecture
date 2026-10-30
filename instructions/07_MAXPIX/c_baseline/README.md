# 07_MAXPIX/c_baseline/

- 對應 Checkpoint:CP1
- 內容:C 參考實作與測試程式

`maxpix(uint32_t pixel_word)` 將輸入視為四個由低位元組到高位元組排列的無號 8-bit 像素，回傳四者最大值。函式不會以 `char` 解讀像素，避免平台上的 signedness 影響結果。

執行測試：

```sh
make test
```

測試程式使用 `uint32_t` 固定輸入寬度，並將失敗案例寫到標準錯誤。完整測資與預期值另見 [`../tests/vectors.csv`](../tests/vectors.csv)。
