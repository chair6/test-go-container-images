package main

import (
    "fmt"
    "github.com/docker/docker/api/types"
)

func main() {
    fmt.Println("Hello, ", types.ImagePullOptions{}, " 🌎!")
}
