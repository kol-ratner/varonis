FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1 \
    PDM_VERSION=2.19.3

WORKDIR /app

RUN pip install pdm==${PDM_VERSION}

COPY app/pyproject.toml app/pdm.lock ./

# Install dependencies
RUN pdm install --prod

# Copy application code
COPY app/src .

ENTRYPOINT ["pdm", "run", "start"]
