# I say

This is a highly opinionated example of how to manage dependencies of a python
application and how to package it in a small alpine-based Docker image.

## Features

### Small Docker image

The application can be packaged into a slim (< 80 MB overhead) alpine-based
[Docker](https://www.docker.com/) image by simply running:

```sh
docker build -t isay .
```

in the root folder.

### Python dependency management using poetry

If your app is using poetry as the dependency management system, you are good to
go. Check out the docs at <https://python-poetry.org/docs/>.

### System dependencies

Some python packages (including, maybe, your own) may have system dependencies
like `openssl` or `gcc` either in order to be compiled or in order to run. You
can define these dependencies in the `[tools.sys.alpine3-11.dev-dependencies]`
and `[tools.sys.alpine3-11.dependencies]` sub-sections of your `pyproject.toml`
file. They each include the list of system dependencies along with their exact
versions. The `dev-dependencies` are the ones needed for building wheels for the
dependencies (and for the project) while the `dependencies` are needed to run
the application.

The `alpine3-11` part in the section name has to match the version of alpine
linux that the python image is based on. The first line in the `Dockerfile`
reads:

```docker
FROM python:3.8-alpine3.11 as base
```

The `alpine3.11` part in the `Dockerfile` must match the `alpine3-11` part in
`pyproject.toml` (with the `.` replaced by a `-` due to restrictions on section
names in `toml`).

### Cache-friendly Docker builds

Whether you are running the build on your development machine or on a continuous
integration (CI) build agent, the build process will try to make use of Docker's
caching mechanism by building layers that depend on data likely to change less
frequently ahead of the layers that depend on data that is likely to change more
frequently. Here is the sequence:

1. Python version: `Dockerfile`
2. Dev & runtime dependencies (system and python): `pyproject.toml`,
   `poetry.lock`
3. Application installed in both the dev and runtime virtual environments: app source code
