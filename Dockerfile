FROM postgres:latest AS builder
RUN mkdir /build
WORKDIR /build
RUN apt-get update && apt-get install -y build-essential postgresql-server-dev-all git libssl-dev zlib1g-dev libreadline-dev liblz4-dev libzstd-dev
RUN git clone https://github.com/segasai/q3c.git
WORKDIR /build/q3c
RUN make
RUN /usr/lib/llvm-16/bin/llvm-lto -thinlto -thinlto-action=thinlink -o q3c.index.bc dump.bc q3c.bc q3c_poly.bc q3cube.bc

FROM postgres:latest
LABEL org.opencontainers.image.source https://github.com/mauch/postgres-q3c
RUN mkdir -p /usr/share/doc/postgresql-doc-17/extension /usr/lib/postgresql/17/lib/bitcode/q3c
COPY --from=builder /build/q3c/q3c.so /usr/lib/postgresql/17/lib/q3c.so
COPY --from=builder /build/q3c/q3c.control /usr/share/postgresql/17/extension/
COPY --from=builder /build/q3c/scripts/*.sql /usr/share/postgresql/17/extension/
COPY --from=builder /build/q3c/README.md /usr/share/doc/postgresql-doc-17/extension/
COPY --from=builder /build/q3c/dump.bc /build/q3c/q3c.bc /build/q3c/q3c_poly.bc /build/q3c/q3cube.bc /usr/lib/postgresql/17/lib/bitcode/q3c/
COPY --from=builder /build/q3c/q3c.index.bc /usr/lib/postgresql/17/lib/bitcode/
COPY create_q3c_extension.sql /docker-entrypoint-initdb.d/
