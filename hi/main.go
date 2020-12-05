package main

import (
	"context"
	"fmt"
	runner "github.com/jarppe/router-runner"
	"github.com/labstack/echo/v4"
	"log"
	"net/http"
	"os"
)


func main() {
	log.SetPrefix("hi: ")

	foo, ok := os.LookupEnv("FOO")
	if !ok {
		log.Fatal("missing env FOO")
	}

	hostname, err := os.Hostname()
	if err != nil {
		log.Fatal("can't resolve hostname")
	}

	ctx := context.Background()
	ctx = context.WithValue(ctx, "FOO", foo)
	ctx = context.WithValue(ctx, "HOSTNAME", hostname)
	ctx, err = runner.RunWithRoutes(ctx,
		HealthRouter,
		HiApi,
	)
	if err != nil {
		log.Printf("main: got error: %v (%[1]T)", err)
		os.Exit(1)
	}
	log.Printf("Server running, pid=%d", os.Getpid())
	<-ctx.Done()
	log.Printf("Server terminated")
	os.Exit(0)

}

func HealthRouter(ctx context.Context) func(ctx context.Context, e *echo.Echo) error {
	return func(ctx context.Context, e *echo.Echo) error {
		e.GET("/", root)
		e.GET("/readyz", readyz)
		e.GET("/livez", livez)
		return nil
	}
}

func root(c echo.Context) error {
	log.Printf("GET /")
	resp := c.Response()
	resp.WriteHeader(http.StatusOK)
	resp.Write([]byte("root"))
	return nil
}

func readyz(c echo.Context) error {
	log.Printf("GET /readyz")
	resp := c.Response()
	resp.WriteHeader(http.StatusOK)
	resp.Write([]byte("ready"))
	return nil
}

func livez(c echo.Context) error {
	log.Printf("GET /livez")
	resp := c.Response()
	resp.WriteHeader(http.StatusOK)
	resp.Write([]byte("live"))
	return nil
}

func HiApi(ctx context.Context) func(ctx context.Context, e *echo.Echo) error {
	return func(ctx context.Context, e *echo.Echo) error {
		g := e.Group("/hi")

		g.GET("/", func(c echo.Context) error {
			resp := c.Response()
			resp.WriteHeader(http.StatusOK)
			resp.Write([]byte(fmt.Sprintf("Hello, foo=[%s], I live at %q", ctx.Value("FOO"), ctx.Value("HOSTNAME"))))
			return nil
		})

		g.GET("/ping", func(c echo.Context) error {
			log.Printf("GET /hi/ping")
			resp := c.Response()
			resp.WriteHeader(http.StatusOK)
			resp.Write([]byte("pong"))
			return nil
		})

		return nil
	}
}
