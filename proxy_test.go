package main

import (
	"./internal/proxy"
	"bytes"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"regexp"
	"testing"
	"time"
)

func TestProxyRequest(t *testing.T) {
	ts := testServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}

		if r.Header.Get("Custom-Header") != "test" {
			t.Fatal("Missing custom header")
		}

		var body bytes.Buffer
		io.Copy(&body, r.Body)
		if body.String() != "REQUEST" {
			t.Fatal("Expected REQUEST in request body")
		}

		w.Header().Set("Custom-Response-Header", "test")
		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", bytes.NewBufferString("REQUEST"))
	if err != nil {
		t.Fatal(err)
	}
	httpRequest.Header.Set("Custom-Header", "test")

	u := newUpstream(ts.URL, "")
	w := httptest.NewRecorder()
	u.Proxy.ServeHTTP(w, httpRequest)
	assertResponseCode(t, w, 202)
	assertResponseBody(t, w, "RESPONSE")

	if w.Header().Get("Custom-Response-Header") != "test" {
		t.Fatal("Expected custom response header")
	}
}

func TestProxyError(t *testing.T) {
	httpRequest, err := http.NewRequest("POST", "/url/path", bytes.NewBufferString("REQUEST"))
	if err != nil {
		t.Fatal(err)
	}
	httpRequest.Header.Set("Custom-Header", "test")

	u := newUpstream("http://localhost:655575/", "")
	w := httptest.NewRecorder()
	u.Proxy.ServeHTTP(w, httpRequest)
	assertResponseCode(t, w, 502)
	assertResponseBody(t, w, "dial tcp: invalid port 655575")
}

func TestProxyReadTimeout(t *testing.T) {
	ts := testServerWithHandler(nil, func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(time.Minute)
	})

	httpRequest, err := http.NewRequest("POST", "http://localhost/url/path", nil)
	if err != nil {
		t.Fatal(err)
	}

	transport := proxy.NewRoundTripper(
		&http.Transport{
			Proxy: http.ProxyFromEnvironment,
			Dial: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).Dial,
			TLSHandshakeTimeout:   10 * time.Second,
			ResponseHeaderTimeout: time.Millisecond,
		},
	)

	u := newUpstream(ts.URL, "")
	url, err := url.Parse(ts.URL)
	if err != nil {
		t.Fatal(err)
	}
	u.Proxy = proxy.NewProxy(url, transport, "123")

	w := httptest.NewRecorder()
	u.Proxy.ServeHTTP(w, httpRequest)
	assertResponseCode(t, w, 502)
	assertResponseBody(t, w, "net/http: timeout awaiting response headers")
}

func TestProxyHandlerTimeout(t *testing.T) {
	ts := testServerWithHandler(nil,
		http.TimeoutHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			time.Sleep(time.Second)
		}), time.Millisecond, "Request took too long").ServeHTTP,
	)

	httpRequest, err := http.NewRequest("POST", "http://localhost/url/path", nil)
	if err != nil {
		t.Fatal(err)
	}

	u := newUpstream(ts.URL, "")

	w := httptest.NewRecorder()
	u.Proxy.ServeHTTP(w, httpRequest)
	assertResponseCode(t, w, 503)
	assertResponseBody(t, w, "Request took too long")
}
