# Utilise Python 3.11 slim pour minimiser la taille
FROM python:3.11-slim

# Métadonnées
LABEL maintainer="Master DSBD & IA"
LABEL version="1.0.0"

# Répertoire de travail
WORKDIR /app

# Copier les dépendances en premier (cache Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY . .

# Variable d'environnement
ENV PORT=8080
ENV ENV=production

# Exposer le port 8080 (5000 et 3000 déjà utilisés)
EXPOSE 8080

# Lancer l'application
CMD ["python", "app.py"]
