# Module-level exports

"""
A helper function to set the Open AQ API key.

    # Examples 

    set_api_key("your_OpenAQ_api_key")

"""
function set_api_key(api_key::String)
    ENV["OPENAQ_API_KEY"] = api_key
end

"""

Gets the current API Key value.
"""
function get_api_key()
    key = ENV["OPENAQ_API_KEY"]
end

"""
Sets the base URL environment variable.
"""
function set_base_url(base_url::String)
    ENV["OPENAQJL_BASE_URL"] = base_url
end

"""
Gets the current base URL value, defaults to OpenAQ's default URL if not set.
"""
function get_base_url()
    url = try ENV["OPENAQJL_BASE_URL"] catch e "https://api.openaq.org" end
end

"""
Checks that API Key is set when using the OpenAQ base URL.
"""
function check_api_key(base_url::String, api_key::String)
    if base_url == "https://api.openaq.org" && api_key == ""
        throw(error("A valid API key is required when using the OpenAQ API."))
    end
end

"""
Enables rate limiting header.
"""
function enable_rate_limit()
    ENV["RATE_LIMIT"] = true
end

"""
Disables or toggles rate limiting header.
"""
function get_rate_limit()
    rate_limit = try ENV["RATE_LIMIT"] catch e false end
    (rate_limit == true) ? true : false
end

"""
Creates an HTTP request object for OpenAQ API requests.
"""
function openaq_request(path::String; query_params::Dict = Dict(), api_key::Union{String, Missing} = missing)
    api_key = (ismissing(api_key) | isnothing(api_key)) ? get_api_key() : api_key

    base_url = get_base_url()

    check_api_key(base_url, api_key)

    resource_path = join(["/v3", path], "/")

    req = join([base_url, "v3", path], "/")
    
    # # Example headers setup (replace with actual headers from OpenAQ API documentation)
    headers = Dict(
            "X-API-Key" => api_key,
            "User-Agent" => "OpenAQ.jl",
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "redact" => ["X-API-Key"]
        )

    return req, headers
    
end


# TODO Adjust implementation of HTTP retries and rate limiting logic. 

"""
req_is_transient(reponse::HTTP.Messages.Response) -> Bool

Determine if the HTTP response indicates that the request is transient due to hitting the rate limit.

# Arguments
- `reponse`: An HTTP response object.

# Returns
- `Bool`: `true` if the response status is 429 (Too Many Requests) and the remaining rate limit is "0", indicating a transient error. Otherwise, returns `false`.
"""
function req_is_transient(response::HTTP.Messages.Response) 
    headers = Dict(response.headers)
    remaining_rate_limit = headers["X-Ratelimit-Remaining"]

    status = response.status

    # Is status 429 and remaining rate limit == "0"?
    return status == 429 && isequal(remaining_rate_limit, "0")
end

"""
    req_is_transient(s::Tuple{Int64, Float64}, ex::HTTP.Exceptions.RequestError, req::HTTP.Messages.Request, resp::Union{HTTP.Messages.Response, Nothing}, resp_body::Union{Vector{UInt8}, Nothing}) -> Bool

Determine if a request should be considered transient based on the response.

# Arguments
- `s::Tuple{Int64, Float64}`: A tuple containing the status code and elapsed time.
- `ex::HTTP.Exceptions.RequestError`: An exception object that occurred during the request.
- `req::HTTP.Messages.Request`: The HTTP request message.
- `resp::Union{HTTP.Messages.Response, Nothing}`: The HTTP response message or `nothing` if no response was received.
- `resp_body::Union{Vector{UInt8}, Nothing}`: The body of the HTTP response as a vector of unsigned 8-bit integers or `nothing`.

# Returns
- `Bool`: `true` if the request should be considered transient, otherwise `false`.
"""
function retry_check(s::Tuple{Int64, Float64}, ex::HTTP.Exceptions.RequestError, req::HTTP.Messages.Request, resp::Union{HTTP.Messages.Response, Nothing}, resp_body::Union{Vector{UInt8}, Nothing})
    req_is_transient(resp)
end



"""
Fetch data from the OpenAQ API.

# Arguments
- `path::String`: The endpoint path to fetch data from.
- `query_params::Dict = Dict()`: Optional query parameters as a dictionary. Default is an empty dictionary.
- `rate_limit::Bool = false`: Whether to apply rate limiting. Default is `false`.
- `api_key::Union{String, Missing} = missing`: An optional API key for authentication. Default is `missing`, which may trigger usage of an environment variable or other fallback method.

# Returns
- `response`: The HTTP response object containing the fetched data.

# Notes
- This function uses the `openaq_request` function to create and handle the request.
- If rate limiting is enabled (`rate_limit=true`) or if the system-wide rate limit is exceeded, additional logic needs to be implemented in the conditional block.
- The function handles retries with an exponential backoff strategy.
"""
function openaq_fetch(path::String, query_params::Dict = Dict(), rate_limit::Bool = false, api_key::Union{String, Missing} = missing)
    # Use openaq_request to create the request and handle it
    req, headers = openaq_request(path)
    
    # Implement rate limiting logic (example implementation)
    if (rate_limit || get_rate_limit()) 
        # Do something
    end
  
    response = HTTP.get(req, headers, query = query_params, retry = true, retries = 4, retry_delays = ExponentialBackOff(n = 4))
    return response
end
