# First stage: build the Go binary.
FROM public.ecr.aws/docker/library/golang:1.16 as builder

WORKDIR /home/netstars/app

# Copy the source code.
COPY . .

# Download dependencies.
RUN go mod download

# Build the Go program, output to the 'bin' directory.
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -buildvcs=false -o event_exporter

# Second stage: create a small runtime environment.
FROM public.ecr.aws/docker/library/alpine:3.18

WORKDIR /home/netstars/app

# Copy the built binary from the builder stage.
COPY --from=builder /home/netstars/app/rds_exporter rds_exporter

# 在 alpine 镜像中安装 shadow 以支持用户和组管理，ca-certificates 保证 SSL 连接，curl 可用于网络请求 tzdata 包含时区数据
RUN apk --no-cache add shadow ca-certificates curl tzdata

# 创建一个新的用户和用户组 "netstar"
RUN groupadd -r -g 996 netstars; \
    useradd -r -g netstars -u 996 netstars

# 修改工作目录的所有权，使新用户拥有
RUN chown -R netstars:netstars /home/netstars

# Set the user to run your app.
USER netstars

# Expose the application port.
EXPOSE 9042

# Set the entrypoint.
ENTRYPOINT ["./rds_exporter"]
