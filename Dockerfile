# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20230612-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.15.4-erlang-26.0.2-debian-bullseye-20230612-slim
#
ARG ELIXIR_VERSION=1.15.4
ARG OTP_VERSION=26.0.2
ARG DEBIAN_VERSION=bookworm-20230612-slim
ARG NODE_VERSION=20.5.1
ARG NODE_IMAGE_VERSION="${NODE_VERSION}-bookworm-slim"

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="node:${NODE_IMAGE_VERSION}"

FROM ${BUILDER_IMAGE} as builder

SHELL ["/bin/bash", "-c"]

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl wget gpg && install -dm 755 /etc/apt/keyrings \
  && wget -qO - https://rtx.pub/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/rtx-archive-keyring.gpg 1> /dev/null 

ARG RTX_ARCH="amd64"

RUN echo "deb [signed-by=/etc/apt/keyrings/rtx-archive-keyring.gpg arch=${RTX_ARCH}] https://rtx.pub/deb stable main" | tee /etc/apt/sources.list.d/rtx.list \
  && apt update && apt install -y rtx && apt-get clean && rm -f /var/lib/apt/lists/*_*

ARG NODE_VERSION=20.5.1
# install nodejs
RUN rtx install nodejs@${NODE_VERSION} && rtx use -g nodejs@${NODE_VERSION}

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
# RUN ["/bin/bash", "-c", "source ~/.bashrc && mix assets.setup"]
#RUN rtx activate bash >> /root/.bashrc && source /root/.bashrc && mix assets.setup
RUN rtx hook-env -s bash >> ~/.bashrc && source ~/.bashrc \
  && mix assets.setup && mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*


# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/app ./

USER nobody

CMD ["/app/bin/server"]
