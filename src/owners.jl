
"""
Retrieves data for a specific owner based on their ID.

Args:
    `owners_id::Int`: The ID of the owner for whom to retrieve data.  This is a required argument.
    `as_data_frame::Bool = true`:  If `true`, the retrieved data is converted into a Julia DataFrame. 
                                    If `false`, the data is returned as a raw data structure (e.g., a dictionary or JSON object).
                                    Defaults to `true`.
    `rate_limit::Bool = false`:  If `true`, the `openaq_fetch` function will be configured to respect rate limits. 
                                  This is useful when making frequent requests to the API. Defaults to `false`.
    `api_key::Union{String, Missing}=missing`:  An optional API key to authenticate with the API.  If `missing`, no API key is provided.

Returns:
    A DataFrame 

"""
function get_owner(owners_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "owners/$owners_id"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) : data

end

"""
Lists owners from OpenAQ.

## Arguments
- `order_by::Union{String, Missing}=missing`: The field to order the results by.  Defaults to `missing`.
- `sort_order::Union{String, Missing}=missing`: The sort order (`asc` or `desc`). Defaults to `missing`.
- `limit::Union{Int, Missing}=100`: The maximum number of results to return. Defaults to 100.
- `page::Union{Int, Missing}=1`: The page number to retrieve. Defaults to 1.
- `as_data_frame::Bool=true`: If `true`, returns the data as a data frame. Defaults to `true`.
- `rate_limit::Bool=false`: Whether to apply rate limiting. Defaults to `false`.
- `api_key::Union{String, Missing}=missing`: The OpenAQ API key. Defaults to `missing`.

## Returns
- A `DataFrame` or a raw data structure (depending on `as_data_frame`) containing the owner data from OpenAQ.
"""
function list_owners(;
    order_by::Union{String, Missing}=missing,
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


    data = openaq_fetch("owners", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) : data

    return data

end
