# Configuração de CORS - Kari Ajuda

## O que é CORS?

CORS (Cross-Origin Resource Sharing) é um mecanismo de segurança que permite ou bloqueia requisições entre diferentes domínios.

## Configuração Atual

A API está configurada para aceitar requisições dos seguintes domínios:

### Produção:
- `https://kariajuda.com` - Site principal
- `https://www.kariajuda.com` - Site com www
- `https://admin.kariajuda.com` - Painel administrativo

### Desenvolvimento:
- `http://localhost:3000` - Site em desenvolvimento
- `http://localhost:3002` - Admin em desenvolvimento
- `http://localhost:8000` - API local

## Como Funciona

```
┌─────────────────┐       CORS Headers      ┌──────────────────┐
│   kariajuda.com │ ◄──────────────────────► │ api.kariajuda.com│
│   (Frontend)    │       Allowed ✓          │     (Backend)    │
└─────────────────┘                          └──────────────────┘

┌─────────────────┐       CORS Headers      ┌──────────────────┐
│ admin.kariajuda │ ◄──────────────────────► │ api.kariajuda.com│
│     .com        │       Allowed ✓          │     (Backend)    │
└─────────────────┘                          └──────────────────┘

┌─────────────────┐       CORS Headers      ┌──────────────────┐
│  outro-site.com │ ◄───────────X───────────► │ api.kariajuda.com│
│                 │       Blocked ✗          │     (Backend)    │
└─────────────────┘                          └──────────────────┘
```

## Configuração no Docker Compose

No arquivo `docker-compose.yml`:

```yaml
environment:
  BACKEND_CORS_ORIGINS: '["https://kariajuda.com","https://admin.kariajuda.com",...]'
```

## Configuração no .env

No arquivo `.env` de produção:

```env
BACKEND_CORS_ORIGINS=["https://kariajuda.com","https://www.kariajuda.com","https://admin.kariajuda.com"]
```

## Headers CORS Enviados pela API

A API envia os seguintes headers quando configurada corretamente:

```
Access-Control-Allow-Origin: https://kariajuda.com
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: *
Access-Control-Allow-Headers: *
```

## Testando CORS

### 1. Via curl
```bash
# Teste de preflight
curl -X OPTIONS https://api.kariajuda.com/api/v1/campaigns \
  -H "Origin: https://kariajuda.com" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

### 2. Via browser console
```javascript
// No console do browser em kariajuda.com
fetch('https://api.kariajuda.com/api/v1/campaigns')
  .then(r => r.json())
  .then(data => console.log(data))
```

## Troubleshooting

### Erro: "CORS policy blocked"

1. **Verifique se o domínio está na lista de origins permitidos**
   ```bash
   docker-compose exec api env | grep BACKEND_CORS_ORIGINS
   ```

2. **Reinicie o container da API após mudanças**
   ```bash
   docker-compose restart api
   ```

3. **Verifique se está usando HTTPS em produção**
   - CORS pode bloquear requisições mistas (HTTP → HTTPS)

### Erro: "Credentials flag is true but Access-Control-Allow-Credentials is not present"

Certifique-se de que `allow_credentials=True` está configurado no FastAPI:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,  # ← Importante!
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Segurança

### ⚠️ NUNCA faça isso em produção:

```python
# INSEGURO - Permite qualquer origem
allow_origins=["*"]
```

### ✅ Sempre especifique domínios exatos:

```python
allow_origins=["https://kariajuda.com", "https://admin.kariajuda.com"]
```

## Adicionar Novo Domínio

Para adicionar um novo domínio (ex: `app.kariajuda.com`):

1. Edite o arquivo `.env`:
   ```env
   BACKEND_CORS_ORIGINS=["https://kariajuda.com","https://app.kariajuda.com",...]
   ```

2. Reinicie o container:
   ```bash
   docker-compose restart api
   ```

3. Teste a conexão:
   ```bash
   curl -X OPTIONS https://api.kariajuda.com/health \
     -H "Origin: https://app.kariajuda.com" \
     -v
   ```

## Resumo

✅ **Não terá problemas de CORS** porque:
1. Todos os domínios estão configurados no `BACKEND_CORS_ORIGINS`
2. FastAPI está configurado com `CORSMiddleware`
3. Credenciais estão permitidas (`allow_credentials=True`)
4. Todos os métodos HTTP estão liberados
5. Todos os headers estão liberados

A configuração atual permite que:
- `kariajuda.com` acesse `api.kariajuda.com` ✓
- `admin.kariajuda.com` acesse `api.kariajuda.com` ✓
- `localhost:3000` acesse `localhost:8000` (desenvolvimento) ✓