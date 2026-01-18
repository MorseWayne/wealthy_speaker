FROM golang:1.25.6-alpine AS builder

WORKDIR /app

ENV GOPROXY=https://goproxy.cn,direct

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o wealthy-collector cmd/server/main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /app/wealthy-collector .
COPY --from=builder /app/config ./config

EXPOSE 8080

CMD ["./wealthy-collector"]
