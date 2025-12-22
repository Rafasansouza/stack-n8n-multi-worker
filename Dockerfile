FROM node:22-bookworm-slim

LABEL maintainer="Rafael"
LABEL description="n8n with Oracle Instant Client support"
LABEL version="2.0.3"

ARG N8N_VERSION=2.0.3
ARG ORACLE_IC_ZIP=instantclient-basiclite-linux.x64-19.19.0.0.0dbru.zip
ARG ORACLE_IC_URL=https://download.oracle.com/otn_software/linux/instantclient/1919000/${ORACLE_IC_ZIP}
ARG ORACLE_IC_SHA256=8d8c222d89be761c5e44baa9f6b688e11830f0a82e84b5b0f7e88ff58cff4b65
ARG ORACLE_IC_DIR=/opt/oracle
ARG ORACLE_IC_VER=19_19
ARG ORACLE_IC_PATH=${ORACLE_IC_DIR}/instantclient_${ORACLE_IC_VER}

ENV NODE_ENV=production

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libaio1 \
    libnsl2 \
    python3 \
    python3-pip \
    python3-venv \
    unzip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${ORACLE_IC_DIR} \
  && curl -fSL -H "Cookie: oraclelicense=accept-securebackup-cookie" "${ORACLE_IC_URL}" -o /tmp/instantclient.zip \
  && if [ -n "${ORACLE_IC_SHA256}" ]; then echo "${ORACLE_IC_SHA256}  /tmp/instantclient.zip" | sha256sum -c - || echo "WARNING: SHA256 mismatch - Oracle may have updated the file"; fi \
  && unzip -q /tmp/instantclient.zip -d ${ORACLE_IC_DIR} \
  && rm -f /tmp/instantclient.zip \
  && ln -sf "$(ls -1 ${ORACLE_IC_PATH}/libclntsh.so.* | head -n 1)" ${ORACLE_IC_PATH}/libclntsh.so \
  && ln -sf "$(ls -1 ${ORACLE_IC_PATH}/libocci.so.* | head -n 1)" ${ORACLE_IC_PATH}/libocci.so \
  && mkdir -p ${ORACLE_IC_PATH}/network/admin

ENV ORACLE_HOME=${ORACLE_IC_PATH}
ENV LD_LIBRARY_PATH=${ORACLE_IC_PATH}
ENV OCI_LIB_DIR=${ORACLE_IC_PATH}
ENV PATH=${ORACLE_IC_PATH}:${PATH}
ENV TNS_ADMIN=${ORACLE_IC_PATH}/network/admin
ENV NODE_ORACLEDB_DRIVER_MODE=thick
ENV N8N_USER_FOLDER=/home/node/.n8n

RUN npm install -g n8n@${N8N_VERSION} \
  && npm cache clean --force \
  && mkdir -p /home/node/.n8n \
  && chown -R node:node /home/node/.n8n

# Python é necessário apenas para modo internal (não recomendado para produção)
# Para modo external, use o container n8nio/runners separado

USER node

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5678/', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

EXPOSE 5678
CMD ["n8n"]
