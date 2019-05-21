Server infrastructure for zgoat services. It's all really KISS and simple.

## HTTP request overview

- Varnish runs on `*:80` and `localhost:8001`
  - Requests to port 80 are redirected to 443
- Hitch runs on `*:443`, redirects to Varnish on 8001
- Varnish does its cache thing and redirects to backend services:
  - GoatLetter: 8080
  - GoatCounter: 8081

Certificates are generated with acme.sh; see `etc/hitch/create-cert`.

## Other services

- `smtpd` (OpenSMTPD) to deliver emails.

## Scripts

- `deploy` Go apps. It assumes the current directory is of the Go program. It
  doesn't restart anything, or run DB migrations.
- `provision` new servers. Alpine Linux is assumed.
- `run-*` the services. Right now I just run this in `tmux`.
