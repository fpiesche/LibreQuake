FROM alpine:3.21.3 AS build

# Install build tools and dependencies
RUN apk add --no-cache \
    clang cmake ninja embree-dev onetbb-dev git curl jq

# Download and build
RUN export ERICW_TOOLS_TAG=$(curl -sL https://api.github.com/repos/ericwa/ericw-tools/releases/latest | jq -r ".tag_name") \
    && git clone --recursive https://github.com/ericwa/ericw-tools \
    && cd ericw-tools && git checkout $ERICW_TOOLS_TAG \
    && cmake . -G Ninja && ninja

FROM alpine:3.21.3 AS image
RUN apk add --no-cache libpng zlib embree onetbb
COPY --from=build \
    /ericw-tools/bspinfo/bspinfo \
    /ericw-tools/bsputil/bsputil \
    /ericw-tools/light/light \
    /ericw-tools/qbsp/qbsp \
    /ericw-tools/vis/vis \
    /usr/local/bin/
