# https://varnish-cache.org/docs/6.1/reference/vcl.html
# https://info.varnish-software.com/blog/one-vcl-per-domain
# https://docs.fastly.com/guides/vcl-tutorials/vcl-regular-expression-cheat-sheet
#
# https://docs.varnish-software.com/policy-engine/filter/ratelimit/

vcl 4.0;

import std;

backend goatletter {
	.host = "127.0.0.1";
	.port = "8080";
}

backend goatcounter {
	.host = "127.0.0.1";
	.port = "8081";
}

# Happens before we check if we have this in cache already.
#
# Typically you clean up the request here, removing cookies you don't need,
# rewriting the request, etc.
sub vcl_recv {
	# Redirect code.arp242.net
	if (req.http.host == "code.arp242.net") {
		set req.http.x-redir = "https://github.com/arp242" + req.url;
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
	} else {
		# Assume GoatCounter; need catch-all for CNAME custom domain.
		set req.backend_hint = goatcounter;
	}
}

# Happens after we have read the response headers from the backend.
#
# Here you clean the response headers, removing silly Set-Cookie headers
# and other mistakes your backend does.
sub vcl_backend_response {
	# Compress everything.
	set beresp.do_gzip = true;

	# set beresp.do_esi = true;
}

# Happens when we have all the pieces we need, and are about to send the
# response to the client.
#
# You can do accounting or modifying the final object here.
sub vcl_deliver {
}

sub vcl_synth {
	if (resp.status == 301) {
		set resp.http.Location = req.http.x-redir;
		return (deliver);
	}
}
