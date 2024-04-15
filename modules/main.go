package modules

import (
	"context"
	"fmt"
	"server-go/common"

	"errors"

	"golang.org/x/oauth2"
)

func ExchangeCode(code, redirectUri string) (*oauth2.Token, error) {

	conf := &oauth2.Config{
		Endpoint:     oauth2.Endpoint{},
		Scopes:       []string{"identify"},
		RedirectURL:  redirectUri,
		ClientID:     common.Config.ClientId,
		ClientSecret: common.Config.ClientSecret,
	}

	token, err := conf.Exchange(context.Background(), code)

	if err != nil {
		fmt.Println(err)
		return nil, errors.New("an error occurred while exchanging code")
	} else {
		return token, nil
	}
}
