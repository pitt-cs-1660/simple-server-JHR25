# =========================
# Build Stage
# =========================
FROM python:3.12 AS builder

RUN pip install --no-cache-dir uv

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /app

COPY pyproject.toml .

RUN python -m venv /opt/venv \
    && uv pip compile pyproject.toml -o requirements.txt \
    && /opt/venv/bin/pip install -r requirements.txt

COPY . .
# =========================
# Final Runtime Stage
# =========================
FROM python:3.12-slim AS runtime


COPY --from=builder /opt/venv /opt/venv

# Copy tests directory into final stage
COPY --from=builder /app/tests ./tests

ENV PATH="/opt/venv/bin:$PATH"

ENV PYTHONPATH="/app"

WORKDIR /app

COPY . .

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]