FROM alpine:3.21.3 AS build

# Install build tools and dependencies
RUN apk add --no-cache \
    clang cmake ninja curl jq tar unzip

WORKDIR /fteqw
# Download and build
RUN curl -L https://github.com/fte-team/fteqw/archive/refs/heads/master.tar.gz \
    | tar -xz --strip-components=1 \
    && cmake \
    -DFTE_TOOL_QCC=true \
    # Core game modules
    -DFTE_ENGINE=false -DFTE_ENGINE_SERVER_ONLY=false -DFTE_MENU_SYS=false -DFTE_PLUG_EZHUD=false \
    # Game format plugins
    -DFTE_CSADDON=false -DFTE_PLUG_COD=false -DFTE_PLUG_HL2=false -DFTE_PLUG_QUAKE3=false \
    # Physics modules
    -DFTE_PLUG_BULLET=false -DFTE_PLUG_CEF=false \
    # Comms modules
    -DFTE_PLUG_XMPP=false -DFTE_PLUG_IRC=false -DFTE_TOOL_HTTPSV=false \
    # Asset modules
    -DFTE_PLUG_FFMPEG=false -DFTE_TOOL_IMAGE=false -DFTE_PLUG_MODELS=false \
    # Other modules
    -DFTE_PLUG_ODE=false -DFTE_PLUG_OPENXR=false -DFTE_PLUG_QI=false -DFTE_TOOL_IQM=false \
    # Other tools
    -DFTE_TOOL_MASTER=false -DFTE_TOOL_QCCGUI=false -DFTE_TOOL_QCVM=false -DFTE_TOOL_QTV=false \
    -G Ninja . \
    && ninja

FROM alpine:3.21.3 AS image
# RUN apk add --no-cache libpng zlib libstdc++ libgcc
COPY --from=build /fteqw/fteqcc /usr/local/bin/fteqcc
