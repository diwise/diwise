package example.authz

default allow := false

allow {
    is_valid_token

    input.method == "GET"
    pathstart := array.slice(input.path, 0, 3)
    pathstart == ["api", "v0", "devices"]
}

issuers := {"http://keycloak:8080/realms/diwise-local"}

metadata_discovery(issuer) := http.send({
    "url": concat("", [issuers[issuer], "/.well-known/openid-configuration"]),
    "method": "GET",
    "force_cache": true,
    "force_cache_duration_seconds": 86400 # Cache response for 24 hours
}).body

jwks_request(url) := http.send({
    "url": url,
    "method": "GET",
    "force_cache": true,
    "force_cache_duration_seconds": 3600 # Cache response for an hour
})

is_valid_token {

    openid_config := metadata_discovery(token.payload.iss)
    jwks := jwks_request(openid_config.jwks_uri).raw_body
	
    verified := io.jwt.verify_rs256(input.token, jwks)
    verified == true
}

token := {"payload": payload} {
    [header, payload, signature] := io.jwt.decode(input.token)
}