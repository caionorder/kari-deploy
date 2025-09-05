# Guia de Deploy na DigitalOcean

## 1. Criar Droplet na DigitalOcean

### Especificações Recomendadas
- **Imagem**: Ubuntu 22.04 LTS
- **Plano**: Minimum 2GB RAM / 2 vCPUs ($12-18/month)
- **Datacenter**: Escolha o mais próximo (São Paulo recomendado)
- **Autenticação**: SSH Key (mais seguro)
- **Hostname**: kariajuda-production

## 2. Configuração Inicial do Servidor

### Conectar via SSH
```bash
ssh root@seu_ip_droplet
```

### Criar usuário não-root
```bash
# Criar usuário
adduser deploy
usermod -aG sudo deploy

# Copiar SSH key para novo usuário
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy

# Testar login com novo usuário
exit
ssh deploy@seu_ip_droplet
```

### Atualizar sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### Configurar firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## 3. Instalar Docker e Docker Compose

```bash
# Instalar dependências
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Adicionar usuário ao grupo docker
sudo usermod -aG docker deploy

# Reiniciar para aplicar mudanças
sudo systemctl restart docker
exit
ssh deploy@seu_ip_droplet
```

## 4. Configurar DNS na DigitalOcean

### No painel da DigitalOcean:
1. Vá em **Networking** → **Domains**
2. Adicione o domínio: `kariajuda.com`
3. Crie os registros DNS:

```
A     @          → seu_ip_droplet     (kariajuda.com)
A     www        → seu_ip_droplet     (www.kariajuda.com)
A     api        → seu_ip_droplet     (api.kariajuda.com)
A     admin      → seu_ip_droplet     (admin.kariajuda.com)
```

### Apontar nameservers no seu registrador de domínio:
```
ns1.digitalocean.com
ns2.digitalocean.com
ns3.digitalocean.com
```

## 5. Deploy da Aplicação

### Clonar repositório de deploy
```bash
cd /opt
sudo mkdir kariajuda
sudo chown deploy:deploy kariajuda
cd kariajuda

# Configurar SSH key para GitHub (se ainda não tiver)
ssh-keygen -t ed25519 -C "deploy@kariajuda.com"
cat ~/.ssh/id_ed25519.pub
# Adicione esta chave no GitHub: Settings → SSH Keys

# Clonar repositório
git clone --recursive git@github.com:caionorder/kari-deploy.git .
```

### Configurar ambiente
```bash
# Copiar e editar arquivo de ambiente
cp .env.example .env
nano .env
```

### Configurações importantes no .env:
```env
# Database - MUDE ESTAS SENHAS!
DB_NAME=kariajuda
DB_USER=kariajuda  
DB_PASSWORD=uma_senha_muito_forte_aqui

# JWT - Gere uma chave forte
SECRET_KEY=gere_uma_chave_com_openssl_rand_base64_32

# Domain
DOMAIN=kariajuda.com
API_DOMAIN=api.kariajuda.com
ADMIN_DOMAIN=admin.kariajuda.com

# Let's Encrypt
LETSENCRYPT_EMAIL=seu_email@gmail.com

# Traefik Dashboard - Gere senha com htpasswd
# sudo apt install apache2-utils
# htpasswd -nb admin sua_senha
TRAEFIK_USER=admin:$2y$10$...

# Email (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu_email@gmail.com
SMTP_PASSWORD=sua_senha_de_app_gmail
```

### Gerar senhas fortes
```bash
# Para SECRET_KEY
openssl rand -base64 32

# Para DB_PASSWORD
openssl rand -base64 24

# Para TRAEFIK_USER (substitua 'sua_senha')
sudo apt install -y apache2-utils
htpasswd -nb admin sua_senha
```

### Executar setup inicial
```bash
# Dar permissão de execução
chmod +x setup.sh
chmod +x scripts/*.sh

# Rodar setup
./setup.sh
```

### Iniciar aplicação
```bash
# Build das imagens
docker-compose build

# Iniciar serviços
docker-compose up -d

# Verificar se está rodando
docker-compose ps

# Ver logs
docker-compose logs -f
```

### Criar superusuário
```bash
# Aguarde o API estar rodando, então execute:

# OPÇÃO 1 - Usar credenciais padrão (rápido):
docker-compose exec api python create_default_superuser.py

# Credenciais padrão criadas:
#   📧 Email: contato@kariajuda.com
#   👤 Username: kari
#   🔐 Senha: kari0110

# OPÇÃO 2 - Criar com credenciais personalizadas:
docker-compose exec -it api python create_superuser_interactive.py
# O script vai pedir email, username e senha personalizados
```

⚠️ **IMPORTANTE**: Altere a senha padrão após o primeiro login em produção!

## 6. Verificar Deploy

### Testar endpoints
```bash
# Health check da API
curl https://api.kariajuda.com/health

# Site
curl -I https://kariajuda.com

# Admin
curl -I https://admin.kariajuda.com
```

### Verificar certificados SSL
Os certificados SSL serão gerados automaticamente pelo Traefik/Let's Encrypt.
Pode levar alguns minutos na primeira vez.

## 7. Monitoramento e Manutenção

### Logs em tempo real
```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f api
docker-compose logs -f traefik
```

### Backup manual
```bash
./scripts/backup.sh
```

### Health check
```bash
./scripts/health_check.sh
```

### Atualizar aplicação
```bash
# Puxar últimas mudanças
git pull
git submodule update --remote --merge

# Rebuild e restart
docker-compose build
docker-compose up -d
```

## 8. Configurar Backups Automáticos (Opcional)

### Cron para backup diário
```bash
# Editar crontab
crontab -e

# Adicionar linha para backup às 2h da manhã
0 2 * * * cd /opt/kariajuda && ./scripts/backup.sh >> /var/log/kariajuda-backup.log 2>&1
```

## 9. Troubleshooting

### Se os containers não iniciarem
```bash
# Ver logs detalhados
docker-compose logs api
docker-compose logs postgres

# Reiniciar tudo
docker-compose down
docker-compose up -d
```

### Se o SSL não funcionar
```bash
# Verificar logs do Traefik
docker-compose logs traefik

# Verificar se as portas 80/443 estão abertas
sudo ufw status
```

### Problemas de memória
```bash
# Verificar uso de memória
free -h
docker stats

# Se necessário, adicionar swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 10. Segurança Adicional

### Fail2ban para SSH
```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Desabilitar login root SSH
```bash
sudo nano /etc/ssh/sshd_config
# Mude: PermitRootLogin no
sudo systemctl restart sshd
```

### Atualizações automáticas de segurança
```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

## Contatos Importantes

- **DigitalOcean Support**: https://www.digitalocean.com/support
- **Status dos Serviços**: https://status.digitalocean.com
- **Documentação Docker**: https://docs.docker.com
- **Traefik Docs**: https://doc.traefik.io/traefik

---

## Checklist Final

- [ ] Droplet criada e configurada
- [ ] Docker e Docker Compose instalados
- [ ] DNS configurado corretamente
- [ ] Repositório clonado com submodules
- [ ] Arquivo .env configurado com senhas fortes
- [ ] Aplicação rodando com `docker-compose up -d`
- [ ] SSL funcionando (https://)
- [ ] Superusuário criado
- [ ] Backup configurado
- [ ] Firewall configurado
- [ ] Monitoramento ativo

Após completar todos os passos, sua aplicação estará rodando em produção! 🚀