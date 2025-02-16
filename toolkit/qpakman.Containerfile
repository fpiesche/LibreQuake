FROM alpine:3.21.3 AS build

# Install build tools and dependencies
RUN apk add --no-cache \
    clang cmake ninja \
    curl jq tar gzip

WORKDIR /qpakman
# Download and build
RUN curl -sL https://api.github.com/repos/bunder/qpakman/releases/latest \
    | jq -r ".tarball_url" \
    | xargs curl -L \
    | tar -xz --strip-components=1 \
    && \
    cmake . -G Ninja && ninja

FROM alpine:3.21.3 AS image
RUN apk add --no-cache libpng zlib libstdc++ libgcc
COPY --from=build /qpakman/qpakman /usr/local/bin/qpakman
