#
# Build:
#

FROM golang:1.15-buster AS build

WORKDIR /app

COPY ./go.mod .
COPY ./go.sum .

RUN go mod download

COPY ./*.go ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o /service

# RUN strip interaction

#
# Dist:
#

FROM gcr.io/distroless/static AS dist

COPY --from=build /service /service

CMD ["/service"]
