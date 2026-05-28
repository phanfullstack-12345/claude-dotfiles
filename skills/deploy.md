---
name: deploy
description: "Use when deploying the application to any environment (staging, production), releasing a new version, or running deployment scripts"
---

# Deploy Skill

## Before Deploying

```bash
# Confirm you're on the right branch
git branch --show-current
git status                    # must be clean — no uncommitted changes

# Confirm tests pass
pnpm test
pnpm lint && tsc --noEmit

# Confirm the target environment
echo $NODE_ENV
cat .env | grep -i env
```

- Never deploy directly to production from a local branch — always go through CI.
- Check if there are pending migrations that need to run alongside the deploy.
- Review the diff since last deploy: `git log origin/main..HEAD --oneline`.

## Deploy Strategies

### Vercel (Next.js)
```bash
# Preview deploy (auto on PR)
vercel

# Production deploy
vercel --prod

# Check deploy status
vercel ls
vercel logs <deployment-url>
```

### Docker + Compose
```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f app
```

### Kubernetes
```bash
# Update image tag
kubectl set image deployment/my-app app=my-image:$TAG -n production

# Rolling deploy status
kubectl rollout status deployment/my-app -n production

# Rollback if needed
kubectl rollout undo deployment/my-app -n production
```

### CI/CD (GitHub Actions / GitLab CI)
```bash
# Trigger via git push
git push origin main

# Monitor pipeline
gh run watch                  # GitHub CLI
gh run list --limit 5
```

### Laravel (PHP)
```bash
php artisan down --message="Deploying..." --retry=60
git pull origin main
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache && php artisan route:cache && php artisan view:cache
php artisan queue:restart
php artisan up
```

## Post-Deploy Checks

```bash
# Health check
curl -f https://your-app.com/health || echo "Health check FAILED"

# Check logs for errors in first 2 minutes
docker compose logs -f app --since 2m
kubectl logs -l app=my-app --since=2m -n production

# Smoke test key endpoints
curl -s https://api.your-app.com/ping | jq .
```

## Rollback

```bash
# Vercel
vercel rollback <previous-deployment-url>

# Docker — re-deploy previous image tag
IMAGE_TAG=<previous-tag> docker compose up -d

# Kubernetes
kubectl rollout undo deployment/my-app -n production

# Laravel
git revert HEAD && git push
php artisan migrate:rollback   # only if migration was part of this deploy
```

## Output Format
Report: (1) environment deployed to, (2) version/tag deployed, (3) health check result, (4) any issues found post-deploy.
