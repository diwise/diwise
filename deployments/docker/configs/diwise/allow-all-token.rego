package example.authz

# See https://www.openpolicyagent.org/docs/latest/policy-reference/ to learn more about rego

default allow := false

current_scopes := [
	"devices.create",
	"devices.read",
	"devices.update",
	"devices.admin",
	"sensors.create",
	"sensors.read",
	"sensors.update",
	"things.create",
	"things.read",
	"things.update",
	"things.delete"
]

access_response := {
	"tenants": token.payload.tenants,
	"access": {
		tenant: current_scopes |
		some tenant in token.payload.tenants
	}
}

allow := response if {
	is_valid_token
	response := access_response
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

is_valid_token if {

	openid_config := metadata_discovery(token.payload.iss)
	jwks := jwks_request(openid_config.jwks_uri).raw_body

	verified := io.jwt.verify_rs256(input.token, jwks)
	verified == true
}

token := {"payload": payload} if {
	[_, payload, _] := io.jwt.decode(input.token)
}
