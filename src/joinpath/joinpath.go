package main

import (
	"fmt"
    "net/url"
)

func main() {
    u, _ := url.JoinPath("https://github.com", "../chair6")
    fmt.Println(u)
}

