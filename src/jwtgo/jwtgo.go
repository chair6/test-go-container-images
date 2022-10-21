package main

import (
    "fmt"
    "github.com/dgrijalva/jwt-go"
)

func main() {
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "Hello": "🌎!",
    })
    fmt.Println(token.Claims)
}

