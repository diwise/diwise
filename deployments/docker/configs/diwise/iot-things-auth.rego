package example.authz

# See https://www.openpolicyagent.org/docs/latest/policy-reference/ to learn more about rego

default allow := false

allow = response {
	is_valid_token

	input.method == "GET"
	pathstart := array.slice(input.path, 0, 2)
	pathstart == ["api", "v0"]

	response := {"tenants": token.payload.tenants}
}

allow = response {
	is_valid_token

	input.method == "POST"
	pathstart := array.slice(input.path, 0, 3)
	pathstart == ["api", "v0", "things"]

	response := {"tenants": token.payload.tenants}
}

allow = response {
	is_valid_token

	input.method == "PATCH"
	pathstart := array.slice(input.path, 0, 3)
	pathstart == ["api", "v0", "things"]

	response := {"tenants": token.payload.tenants}
}

allow = response {
	is_valid_token

	input.method == "PUT"
	pathstart := array.slice(input.path, 0, 3)
	pathstart == ["api", "v0", "things"]

	response := {"tenants": token.payload.tenants}
}

issuers := {"https://iam.diwise.local:8444/realms/diwise-local"}

# Connect to the specified issuer to query for openid metadata
metadata_discovery(issuer) := http.send({
	"url": concat("", [issuers[issuer], "/.well-known/openid-configuration"]),
	"method": "GET",
	"force_cache": true,
	"force_cache_duration_seconds": 86400,
	"tls_insecure_skip_verify": true
}).body

# Cache response for 24 hours

# Use the jwks_uri from the metadata returned above, to request a JWKS, to be
# able to verify the supplied token
jwks_request(url) := http.send({
	"url": url,
	"method": "GET",
	"force_cache": true,
	"force_cache_duration_seconds": 3600, # Cache response for an hour
	"tls_insecure_skip_verify": true
})

is_valid_token {

	openid_config := metadata_discovery(token.payload.iss)
	jwks := jwks_request(openid_config.jwks_uri).raw_body

	verified := io.jwt.verify_rs256(input.token, jwks)
	verified == true
}

token := {"payload": payload} {
	[_, payload, _] := io.jwt.decode(input.token)
}
