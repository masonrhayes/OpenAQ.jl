
"""
get a single license from the licenses resource.

# Arguments
- `licenses_id::Int`: An integer.
- `as_data_frame::Bool=true`: Logical for toggling whether to return results as data frame or list, defaults to true.
- `dry_run::Bool=false`: Logical for toggling a dry run of the request, defaults to false.
- `rate_limit::Bool=false`: Logical for toggling automatic rate limiting based on rate limit headers, defaults to false.
- `api_key::String=nothing`: A valid OpenAQ API key string, defaults to nothing.

# Returns
- `DataFrame` or `Dict`.
"""
function get_license(
    licenses_id::Int,
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{Missing,String}=missing)
  path = "licenses/$licenses_id"
  data = openaq_fetch(path, Dict(), rate_limit, api_key)
  
  
  data = as_data_frame ? convert_to_dataframe(data) : data
end



"""
Get a list of licenses from the licenses resource.

# Arguments
- `order_by::Union{String, Missing}=missing`: A string.
- `sort_order::Union{String, Missing}=missing`: A string.
- `limit::Union{Int, Missing}=100`: An integer.
- `page::Union{Int, Missing}=1`: An integer.
- `as_data_frame::Bool=true`: A logical for toggling whether to return results as data frame or list defaults to TRUE.
- `rate_limit::Bool=false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to FALSE.
- `api_key::Union{String, Missing}=missing`: A valid OpenAQ API key string, defaults to missing.

# Returns
A data frame or a list of the results.
"""
function list_licenses(
    order_by::Union{String, Missing}=missing;
    sort_order::Union{String, Missing}=missing,
    limit::Union{Int, Missing}=100,
    page::Union{Int, Missing}=1,
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{String, Missing}=missing
)
    params_list = Dict(
        :order_by => order_by,
        :sort_order => sort_order,
        :limit => limit,
        :page => page
    )

    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)


    data = openaq_fetch("licenses", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) : data

    return data
end
