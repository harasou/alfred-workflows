package main

import (
	"encoding/json"
	"os"
	"strings"

	"ghe.tokyo.pb/harasou/munin"
	"github.com/harasou/alfred"
)

type data struct {
	Services munin.Services
}

func main() {

	wf := alfred.Workflow()
	defer wf.Print()

	dec := json.NewDecoder(os.Stdin)
	var j data
	if err := dec.Decode(&j); err != nil {
		wf.AddItem(&alfred.Item{
			Title: "標準入力から Munin の URL が取得できませんでした",
		})
		return
	}

	var key string
	if len(os.Args) > 1 {
		key = os.Args[1]
	}

	for _, e := range j.Services.Filter(key) {
		n := strings.Split(e.Name, "/")
		wf.AddItem(&alfred.Item{
			Title:        n[len(n)-2],
			Subtitle:     e.Url,
			Arg:          e.Url,
			Autocomplete: e.Name,
		})
	}
}
