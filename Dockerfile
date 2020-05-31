# 1. Python & alpine version
FROM python:3.8-alpine3.11 as base

FROM base as dev

WORKDIR /app
RUN pip install 'toml==0.10.1'

# 2. Poetry version
RUN wget -qO - https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | POETRY_VERSION="1.0.5" python

# 3. Dev & runtime dependencies (system and python)
COPY pyproject.toml poetry.lock /app/
RUN true \
 && ALPINE_VERSION=$(head -n 1 /etc/issue | cut -d ' ' -f 5 | tr '.' '-') \
 && DATA=$(python -c 'import toml; prj = toml.load("pyproject.toml"); print(prj["tool"]["poetry"]["name"]); alpine = prj.get("tool", {}).get("sys", {}).get("alpine'"${ALPINE_VERSION}"'", {}); print(" ".join(map("=".join, alpine.get("dependencies", {}).items()))); print(" ".join(map("=".join, alpine.get("dev-dependencies", {}).items())))') \
 && PROJECT_NAME=$(echo "$DATA" | head -n 1) \
 && RUNDEPS=$(echo "$DATA" | head -n 2 | tail -n 1) \
 && DEVDEPS=$(echo "$DATA" | tail -n 1) \
 && mkdir -p /deps \
 && echo "$RUNDEPS" > /deps/rundeps \
 && if [ -n "$DEVDEPS $RUNDEPS" ]; \
    then \
        apk add --no-cache --virtual .dev-dependencies $DEVDEPS $RUNDEPS ; \
    fi \
 && touch ${PROJECT_NAME}.py \
 && /root/.poetry/bin/poetry install \
 && pip install --no-warn-script-location --user . \
 && rm ${PROJECT_NAME}.py \
 && apk del --no-cache .dev-dependencies

# 4. The app source code
COPY . /app/
RUN /root/.poetry/bin/poetry build \
 && /root/.poetry/bin/poetry install \
 && /root/.poetry/bin/poetry run pytest tests \
 && ln -s /root/.local/lib/python$(python --version | cut -d ' ' -f 2 | cut -d '.' -f 1,2)/site-packages /site-packages \
 && pip install --force --no-warn-script-location --user dist/${PROJECT_NAME}*.whl

FROM base
COPY --from=dev /deps/rundeps /deps/
RUN if [ -n "$(cat /deps/rundeps)" ]; then apk add --no-cache $(cat /deps/rundeps); fi \
 && ln -s /root/.local/lib/python$(python --version | cut -d ' ' -f 2 | cut -d '.' -f 1,2)/site-packages /site-packages
COPY --from=dev /site-packages /site-packages/
COPY --from=dev /root/.local/bin /usr/local/bin/
