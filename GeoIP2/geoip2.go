package main

import (
	"fmt"
	"net"
	"os"
	"regexp"
	"strings"

	"github.com/harasou/alfred"
	"github.com/oschwald/geoip2-golang"
)

var reg_ip = regexp.MustCompile(
	"(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")

const mmdb = "mmdb/GeoLite2-City.mmdb"

func main() {

	if len(os.Args) == 1 {
		return
	}

	wf := alfred.Workflow()
	defer wf.Print()

	db, err := geoip2.Open(mmdb)
	if err != nil {
		wf.AddItem(&alfred.Item{
			Title: "データベースのオープンに失敗しました",
		})
		return
	}
	defer db.Close()

	iplist := reg_ip.FindAllString(os.Args[1], -1)

	if len(iplist) == 0 {
		wf.AddItem(&alfred.Item{
			Title:    "IPアドレスを入力してください",
			Subtitle: "ex. 1.1.1.1 8.8.8.8",
		})
		return
	}

	for _, ip := range iplist {

		r, err := db.City(net.ParseIP(ip))
		if err != nil {
			wf.AddItem(&alfred.Item{
				Title: "データベースの検索に失敗しました",
			})
			continue
		}
		if r.Country.IsoCode == "" {
			wf.AddItem(&alfred.Item{
				Uid:      ip,
				Title:    "該当するデータが見つかりませんでした",
				Arg:      ip,
				Subtitle: ip,
				Icon:     "",
			})
		} else {
			wf.AddItem(&alfred.Item{
				Uid:      ip,
				Title:    fmt.Sprintf("%v (%v:%v)", r.Country.IsoCode, r.Country.Names["en"], r.Country.Names["ja"]),
				Arg:      ip,
				Subtitle: ip,
				Icon:     fmt.Sprintf("icons/%v.png", strings.ToLower(r.Country.IsoCode)),
			})
		}
	}
}
