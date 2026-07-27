# IMA 知识库双向同步方案

## 可行性确认

IMA 的 OpenAPI 覆盖了知识库和笔记两大模块，支持：

- **读取**知识库内容（搜索、浏览文件列表、获取文件原文）
- **写入**知识库（创建笔记、上传文件、导入网页）
- **管理**知识库（创建文件夹、关联笔记到知识库）

双向同步完全可行。

---

## 获取 API 凭证

1. 访问 [ima.qq.com/agent-interface](https://ima.qq.com/agent-interface)
2. 登录你的 IMA 账号
3. 生成 **Client ID** 和 **API Key**

所有 API 请求都需要在 HTTP Header 中携带：

```
ima-openapi-clientid: 你的ClientID
ima-openapi-apikey: 你的APIKey
Content-Type: application/json
```

---

## 核心 API 端点一览

**Base URL:** `https://ima.qq.com`

### 知识库模块 (`/openapi/wiki/v1/*`)

| 操作 | 端点 | 说明 |
|------|------|------|
| 搜索知识库内容 | `search_knowledge` | 按关键词搜索知识库中的文档 |
| 获取知识库列表 | `get_addable_knowledge_base_list` | 列出你可用的知识库 |
| 获取文件夹内容 | `get_knowledge_list` | 浏览指定文件夹下的文档 |
| 获取知识库信息 | `get_knowledge_base` | 获取知识库元信息 |
| 添加知识 | `add_knowledge` | 将笔记/文件关联到知识库 |
| 创建媒体 | `create_media` | 获取 COS 上传凭证（上传文件用） |
| 导入网页 | `import_urls` | 将网页链接导入知识库 |

### 笔记模块 (`/openapi/note/v1/*`)

| 操作 | 端点 | 说明 |
|------|------|------|
| 创建笔记 | `import_doc` | 创建 Markdown 格式笔记，返回 note_id |
| 搜索笔记 | `search_note` | 按标题或正文检索笔记 |
| 列出笔记本 | `list_notebook` | 获取笔记本列表 |
| 列出笔记 | `list_note` | 获取某笔记本下的笔记列表 |
| 获取笔记内容 | `get_doc_content` | 读取笔记正文 |
| 追加内容 | `append_doc` | 向已有笔记追加内容 |

---

## 双向同步实现方案

### 方向一：IMA 知识库 → 你的软件（读取）

```
1. 调用 get_addable_knowledge_base_list 获取知识库列表
2. 调用 get_knowledge_list 浏览文件夹内容
3. 调用 search_knowledge 搜索特定内容
4. 调用 get_doc_content 获取笔记/文档原文
→ 将内容解析后存入你的软件本地数据库
```

### 方向二：你的软件 → IMA 知识库（写入）

**方式A：纯文本/Markdown 笔记**

```
1. 调用 import_doc 创建笔记（传入 Markdown 内容）→ 拿到 note_id
2. 调用 add_knowledge 将笔记关联到知识库（media_type=11，指定 folder_id）
```

**方式B：上传文件（PDF/Word/图片等）**

```
1. 调用 create_media 获取 COS 临时上传凭证
2. 使用 COS SDK 上传文件到腾讯云对象存储
3. 调用 add_knowledge 将文件关联到知识库
```

---

## 架构建议

```
┌─────────────────┐         ┌──────────────────┐
│   你的软件       │◄──────►│   IMA OpenAPI     │
│                 │  HTTPS  │  ima.qq.com       │
│  ┌───────────┐  │  POST   │                   │
│  │ 本地数据库 │  │         │  ┌──────────────┐ │
│  └───────────┘  │         │  │  知识库存储    │ │
│  ┌───────────┐  │         │  └──────────────┘ │
│  │ 同步引擎   │  │         │  ┌──────────────┐ │
│  │ - 增量检测 │  │         │  │  笔记系统     │ │
│  │ - 冲突处理 │  │         │  └──────────────┘ │
│  │ - 定时任务 │  │         │                   │
│  └───────────┘  │         │                   │
└─────────────────┘         └──────────────────┘
```

### 关键设计要点

1. **增量同步**：记录每个文档的最后修改时间，只同步变更部分，减少 API 调用
2. **冲突处理**：当两端同时修改同一内容时，制定合并策略（以较新时间戳为准，或提示用户手动解决）
3. **定时同步**：设置轮询间隔（如每5分钟），或采用 Webhook 方式（如果 IMA 未来支持）
4. **编码注意**：写入时必须确保 UTF-8 编码，否则会出现乱码

---

## API 调用示例

### 1. 验证连接 — 获取知识库列表

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/get_addable_knowledge_base_list" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"cursor":"","limit":50}'
```

返回 `code: 0` 说明连接成功。

### 2. 搜索知识库内容

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/search_knowledge" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"query":"搜索关键词","cursor":"","knowledge_base_id":"你的知识库ID"}'
```

### 3. 浏览文件夹内容

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/get_knowledge_list" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"cursor":"","limit":20,"knowledge_base_id":"你的知识库ID","folder_id":"文件夹ID"}'
```

### 4. 创建笔记并添加到知识库

**第一步：创建笔记**

```bash
curl -s -X POST "https://ima.qq.com/openapi/note/v1/import_doc" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"content_format":1,"content":"# 笔记标题\n\n笔记正文，支持Markdown格式","folder_name":"目标文件夹名"}'
```

记下返回的 `note_id`。

**第二步：将笔记添加到知识库**

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/add_knowledge" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"media_type":11,"title":"笔记标题","knowledge_base_id":"你的知识库ID","folder_id":"目标文件夹ID","note_info":{"content_id":"上一步返回的note_id"}}'
```

两步都返回 `code: 0` 即为成功。

### 5. 上传文件到知识库

**第一步：创建媒体，获取 COS 上传凭证**

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/create_media" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"file_name":"文件名.md","file_size":5000,"content_type":"text/markdown","knowledge_base_id":"你的知识库ID","file_ext":"md"}'
```

返回关键字段：`media_id` 和 `cos_credential`（含 token、secret_id、secret_key 等）。

**第二步：上传文件到 COS**

使用官方提供的上传脚本（避免签名错误）：

```bash
# 下载官方 Skill 包：https://app-dl.ima.qq.com/skills/ima-skills-1.1.7.zip
# 脚本位置：ima-skill/knowledge-base/scripts/cos-upload.cjs

node cos-upload.cjs \
  --file 本地文件路径 \
  --secret-id "返回的secret_id" \
  --secret-key "返回的secret_key" \
  --token "返回的token" \
  --bucket "返回的bucket_name" \
  --region "返回的region" \
  --cos-key "返回的cos_key" \
  --content-type "text/markdown" \
  --start-time "返回的start_time" \
  --expired-time "返回的expired_time"
```

**第三步：将文件添加到知识库**

```bash
curl -s -X POST "https://ima.qq.com/openapi/wiki/v1/add_knowledge" \
  -H "Content-Type: application/json" \
  -H "ima-openapi-clientid: 你的ClientID" \
  -H "ima-openapi-apikey: 你的APIKey" \
  -d '{"media_type":7,"media_id":"第一步返回的media_id","title":"文件显示标题","knowledge_base_id":"你的知识库ID","folder_id":"目标文件夹ID","file_info":{"cos_key":"第一步返回的cos_key","file_size":5000,"last_modify_time":当前时间戳,"file_name":"文件名.md"}}'
```

---

## 常用文件类型对照

| media_type | 文件类型 | content_type |
|------------|----------|--------------|
| 1 | PDF | `application/pdf` |
| 3 | Word | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |
| 7 | Markdown | `text/markdown` |
| 9 | 图片 | `image/png`, `image/jpeg` |
| 11 | 笔记 | - |
| 13 | TXT | `text/plain` |

---

## 现有参考实现

| 项目 | 说明 |
|------|------|
| **Obsidian ima.copilot Sync 插件** | Obsidian 笔记与 IMA 知识库双向同步，支持增量同步、定时同步 |
| **Hermes + IMA Skill** | AI Agent 集成 IMA API 的完整技能包 |
| **IMA 官方 Skill 包** | 腾讯官方提供的 API 封装脚本，下载：`https://app-dl.ima.qq.com/skills/ima-skills-1.1.7.zip` |

---

## 注意事项

1. **API Key 有效期**：约 3 个月，过期需要重新生成
2. **笔记 ≠ 知识库条目**：创建笔记后，还需要调用 `add_knowledge` 才能将其加入知识库，两步缺一不可
3. **COS 上传**：文件上传不能直接用 curl，需要用官方提供的 `cos-upload.cjs` 脚本或 COS SDK 处理签名
4. **不支持的操作**：目前 API 暂不支持删除笔记/知识库条目，需要在 IMA 客户端手动操作
5. **速率限制**：注意 API 调用频率，避免短时间内大量请求
6. **编码问题**：写入内容必须确保 UTF-8 编码，Windows 环境下尤其注意，否则会出现不可逆乱码

---

## 快速上手

最快的方式是先下载 **IMA 官方 Skill 包**，里面包含完整的 API 调用脚本（`ima_api.cjs`）和 COS 上传脚本（`cos-upload.cjs`），可以直接参考其实现逻辑来编写同步模块。

```bash
# 下载官方 Skill 包
wget https://app-dl.ima.qq.com/skills/ima-skills-1.1.7.zip -O /tmp/ima-skills.zip
unzip /tmp/ima-skills.zip

# 核心脚本位置
# ima-skill/knowledge-base/scripts/ima_api.cjs   — API 调用封装
# ima-skill/knowledge-base/scripts/cos-upload.cjs — COS 文件上传
```
