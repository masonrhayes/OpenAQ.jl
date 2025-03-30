
"""
Retrieves data for a specific provider.

# Arguments
    
    - providers_id (Int): The ID of the provider to retrieve data for.
    - as_data_frame (Bool, optional): If true, the data is converted to a DataFrame. Defaults to `true`.
    - rate_limit (Bool, optional): If true, rate limiting is applied to the API request. Defaults to `false`.
    - api_key (Union{String, Missing}, optional): The API key to use for authentication. Defaults to `missing`.

Returns:
    A DataFrame
"""
function get_provider(providers_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "providers/$providers_id"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> process_providers : data

end

"""
Lists available providers from OpenAQ.

## Arguments
- `order_by::Union{String, Missing}=missing`:  The field to order the providers by.  Valid values depend on the OpenAQ API, but common ones include 'name', 'created_at', etc. Defaults to `missing`.
- `sort_order::Union{String, Missing}=missing`: The sort order.  Valid values depend on the Open AQ API. Defaults to `missing`.
- `limit::Union{Int, Missing}=100`: The maximum number of providers to return per page. Defaults to 100.
- `page::Union{Int, Missing}=1`: The page number to retrieve. Defaults to 1.
- `as_data_frame::Bool=true`: If `true`, returns the data as a data frame. Defaults to `true`.
- `rate_limit::Bool=false`:  If `true`, applies rate limiting to the API request. Defaults to `false`.
- `api_key::Union{String, Missing}=missing`: The API key to use for authentication. Defaults to `missing`.

## Returns
- A DataFrame

"""
function list_providers(;
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


    data = openaq_fetch("providers", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) |> process_providers : data

    return data

end

# handler functions to get bbox data if available; otherwise return dict with missing values.
function get_bbox_data(dict::Dict)
    dict
end

function get_bbox_data(dict::Union{Nothing, Missing})
    Dict("coordinates" => missing, "type" => missing)
end

function process_providers(df::DataFrame)
    @chain df begin 
        transform(:bbox => ByRow(get_bbox_data) => AsTable)
        transform(:parameters => ByRow(get_parameter_data) => AsTable)
        select(Not([:bbox, :parameters]))
        select(:id, :)
    end 
end

