# Utiliser une image GHC récente comme base
FROM haskell:9.4 as builder

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    libffi-dev \
    libgmp-dev \
    zlib1g-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers sources
COPY . .

# Installation de cabal et mise à jour
RUN cabal update

# Configuration de la compilation avec le flag server activé
RUN cabal configure --flags="+server"

# Compilation de pandoc avec support server
RUN cabal install pandoc-cli \
    --install-method=copy \
    --overwrite-policy=always \
    --flags="+server"

# Créer le lien symbolique pour activer le mode serveur
RUN ln -s /root/.cabal/bin/pandoc /root/.cabal/bin/pandoc-server

# Image finale plus légère
FROM debian:bullseye-slim

# Installation des dépendances minimales
RUN apt-get update && apt-get install -y \
    libgmp10 \
    libffi7 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copier l'exécutable compilé
COPY --from=builder /root/.cabal/bin/pandoc /usr/local/bin/
COPY --from=builder /root/.cabal/bin/pandoc-server /usr/local/bin/

# Configuration du port par défaut
ENV PORT=3030

# Exposer le port
EXPOSE ${PORT}

# Définir le point d'entrée
ENTRYPOINT ["/usr/local/bin/pandoc-server"]
CMD ["--port", "3030"]
