package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"regexp"
	"strings"

	"github.com/harasou/alfred"
	"github.com/oschwald/geoip2-golang"
)

var reg_ip = regexp.MustCompile(
	"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")

const mmdb = "mmdb/GeoLite2-City.mmdb"

func main() {

	if len(os.Args) == 1 {
		return
	}

	db, err := geoip2.Open(mmdb)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	wf := alfred.Workflow()
	defer wf.Print()

	for _, key := range os.Args[1:] {

		if !reg_ip.MatchString(key) {
			wf.AddItem(&alfred.Item{
				Uid:      key,
				Arg:      key,
				Title:    "IPアドレスを入力してください",
				Subtitle: "ex. 1.1.1.1 8.8.8.8",
				Icon:     "",
			})
			continue
		}

		ip := net.ParseIP(key)

		r, err := db.City(ip)
		if err != nil {
			log.Fatal(err)
		}
		if r.Country.IsoCode == "" {
			wf.AddItem(&alfred.Item{
				Uid:      key,
				Title:    "該当するデータが見つかりませんでした",
				Arg:      key,
				Subtitle: key,
				Icon:     "",
			})
		} else {
			wf.AddItem(&alfred.Item{
				Uid:      key,
				Title:    fmt.Sprintf("%v (%v:%v)", r.Country.IsoCode, r.Country.Names["en"], r.Country.Names["ja"]),
				Arg:      key,
				Subtitle: key,
				Icon:     fmt.Sprintf("icons/%v.png", strings.ToLower(r.Country.IsoCode)),
			})
		}
	}
}
