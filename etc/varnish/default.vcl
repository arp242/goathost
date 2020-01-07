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

backend arp242 {
	.host = "127.0.0.1";
	.port = "8082";
}

# Before we check if we have this in cache.
#
# Typically you clean up the request here, removing cookies you don't need,
# rewriting the request, etc.
sub vcl_recv {
	# Redirect code.arp242.net
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
			set req.backend_hint = goatcounter;
		} else {
			set req.backend_hint = arp242;
		}
	} else {
		# Assume GoatCounter; need catch-all for CNAME custom domain.
		set req.backend_hint = goatcounter;

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
}

sub vcl_backend_error {
	# Retry /count requests; the first 500ms should cover most restarts, but
	# also wait a bit longer for DB migrations and the like.
	if (bereq.url ~ "^/count") {
		if (bereq.retries == 0) {
			vtc.sleep(500ms);
		} else {
			vtc.sleep(1s * bereq.retries * 2);
		}
		return(retry);
	}
}

sub vcl_synth {
	if (resp.status == 301) {
		set resp.http.Location = req.http.x-redir;
		return (deliver);
	}
}
