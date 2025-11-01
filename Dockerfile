FROM golang:1.24 AS builder

WORKDIR /app

COPY go.* ./

RUN go mod download

COPY main.go ./

RUN mkdir -p build
RUN CGO_ENABLED=0 go build -v -o build ./...

FROM gcr.io/distroless/static:nonroot

COPY --from=busybox:1.37.0-uclibc /bin/wget /usr/local/bin/wget
COPY --from=builder /app/build/APP_DIR /app/APP_DIR

CMD ["/app/APP_NAME"]