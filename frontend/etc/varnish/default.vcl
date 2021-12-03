vcl 4.0;

import std;
import vtc;

backend goatcounter {
	.host = "139.162.3.42"; # gc-sg
	.port = "8081";
}

backend httpbuf {
	.host = "127.0.0.1";
	.port = "8082";
}

# Before we check if we have this in cache.
#
# Typically you clean up the request here, removing cookies you don't need,
# rewriting the request, etc.
sub vcl_recv {
	# Redirect.
	if (req.http.host == "static.goatcounter.com") {
		set req.http.x-redir = "https://gc.zgo.at" + req.url;
		return(synth(301));
	}
	if (req.http.host == "license.goatcounter.com") {
			set req.http.x-redir = "https://github.com/zgoat/goatcounter/blob/master/LICENSE";
			return(synth(301));
	}
	if (req.http.host == "code.arp242.net") {
		set req.http.x-redir = "https://github.com/arp242" + req.url;
		return(synth(301));
	}
	if (req.http.host == "eupl12.zgo.at") {
		set req.http.x-redir = "https://joinup.ec.europa.eu/collection/eupl/eupl-text-11-12";
		return(synth(301));
	}

	# Probably previous owner of the IP address; prevents logging needless 400s.
	if (req.http.host == "army2phl.tk") {
		return(syncth(410));
	}

	# Redirect everything else to HTTPS.
	if (std.port(local.ip) == 80 && req.url !~ "(?i)^/\.well-known/acme-challenge/") {
		set req.http.x-redir = "https://" + req.http.host + req.url;
		return(synth(301));
	}

	# GoatAnalytics only works for /count
	if (req.http.host ~ "goatanalytics.com$" && req.url !~ "^/count") {
		set req.http.x-redir = "https://" + regsub(req.http.host, "goatanalytics", "goatcounter") + req.url;
		return(synth(301));
	}

	# Assume GoatCounter; need catch-all for CNAME custom domain.
	set req.backend_hint = goatcounter;
}

# After we have read the response headers from the backend.
#
# Here you clean the response headers, removing silly Set-Cookie headers and
# other mistakes your backend does.
sub vcl_backend_response {
	# Compress everything.
	if (beresp.http.Content-Type != "application/gzip") {
		set beresp.do_gzip = true;
	}

	# Make sure we never cache this. Shouldn't really be needed, but with some
	# curl commands I get a cached response otherwise 🤔 Just be safe about it.
	if (bereq.url ~ "^/(count|status)") {
		set beresp.ttl = 0s;
		set beresp.uncacheable = true;
	}
}

sub vcl_backend_error {
	if (bereq.url ~ "^/count") {
		if (bereq.retries >= 3) {
			set bereq.backend = httpbuf;
			return(retry);
		}

		vtc.sleep(300ms * (bereq.retries + 1));
		return(retry);

	# set beresp.http.Content-Type = "text/html; charset=utf-8";
	# set beresp.body = "<h1>Scheduled database maintainance</h1><p>Please try again in 10 minutes or so.</p>";
	# return(deliver);
	}
}

sub vcl_synth {
	if (resp.status == 301) {
		set resp.http.Location = req.http.x-redir;
		return (deliver);
	}
}
