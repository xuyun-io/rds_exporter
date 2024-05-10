FROM public.ecr.aws/docker/library/golang:1.16 as builder

COPY . /usr/src/rds_exporter

RUN cd /usr/src/rds_exporter && go mod download && go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o rds_exporter

FROM public.ecr.aws/docker/library/alpine:3.18

COPY --from=builder /usr/src/rds_exporter/rds_exporter  /bin/
# COPY config.yml           /etc/rds_exporter/config.yml

RUN apk update && \
    apk add ca-certificates && \
    update-ca-certificates

EXPOSE      9042
ENTRYPOINT  [ "/bin/rds_exporter", "--config.file=/etc/rds_exporter/config.yml" ]
