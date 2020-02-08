vcl 4.0;

import std;
import vtc;

backend goatletter {
	.host = "127.0.0.1";
	.port = "8080";
}

backend goatcounter {
	.host = "127.0.0.1";
	.port = "8081";
}

backend goatcounter_staging {
	.host = "127.0.0.1";
	.port = "8083";
}

backend arp242 {
	.host = "127.0.0.1";
	.port = "8082";
}

backend httpbuf {
	.host = "127.0.0.1";
	.port = "8100";
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
	if (req.http.host == "code.arp242.net") {
		set req.http.x-redir = "https://github.com/arp242" + req.url;
		return(synth(301));
	}
	if (req.http.host == "eupl12.zgo.at") {
		set req.http.x-redir = "https://joinup.ec.europa.eu/collection/eupl/eupl-text-11-12";
		return(synth(301));
	}

	# Redirect everything else to HTTPS.
	if (std.port(local.ip) == 80) {
		set req.http.x-redir = "https://" + req.http.host + req.url;
		return(synth(301));
	}

	# Select backend.
	if (req.http.host ~ "goatletter.com$") {
		set req.backend_hint = goatletter;
	} else if (req.http.host ~ "arp242.net$") {
		if (req.http.host == "stats.arp242.net") {  # Domain conflict
			if (req.http.Cookie ~ "gc=staging") {
				set req.backend_hint = goatcounter_staging;
			} else {
				set req.backend_hint = goatcounter;
			}
		} else {
			set req.backend_hint = arp242;
		}
	} else {
		# Assume GoatCounter; need catch-all for CNAME custom domain.
		if (req.http.Cookie ~ "gc=staging") {
			set req.backend_hint = goatcounter_staging;
		} else {
			set req.backend_hint = goatcounter;
		}

		# Remove cookies; we set cookie for all of *.goatcounter.com now so also
		# this one.
		if (req.http.host == "static.goatcounter.com") {
			unset req.http.Cookie;
		}
	}
}

# After we have read the response headers from the backend.
#
# Here you clean the response headers, removing silly Set-Cookie headers and
# other mistakes your backend does.
sub vcl_backend_response {
	set beresp.do_gzip = true;  # Compress everything.

	# Make sure we never cache this. Shouldn't really be needed, but with some
	# curl commands I get a cached response otherwise 🤔 Just be safe about it.
	if (bereq.url ~ "^/count") {
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
	# } elseif (bereq.url !~ "^/status") {
	# 	set beresp.http.Content-Type = "text/html; charset=utf-8";
	# 	set beresp.body = "<h1>Scheduled database maintainance</h1><p>Please try again in 10 minutes or so.</p>";
	# 	return(deliver);
	}
}

sub vcl_synth {
	if (resp.status == 301) {
		set resp.http.Location = req.http.x-redir;
		return (deliver);
	}
}
