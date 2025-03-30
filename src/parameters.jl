
"""
Retrieves a parameter from the openaq API.

Args:
    parameters_id (Int): The ID of the parameter to retrieve.
    as_data_frame (Bool, optional): Whether to return the data as a DataFrame. Defaults to `true`.
    rate_limit (Bool, optional): Whether to apply a rate limit. Defaults to `false`.
    api_key (Union{String, Missing}, optional): The API key to use. Defaults to `missing`.

Returns:
    A DataFrame or the raw data, depending on the `as_data_frame` argument.
"""
function get_parameter(parameters_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "parameters/$parameters_id"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) : data

end


"""
Lists parameters from the OpenAQ API.

This function retrieves a list of parameters from the OpenAQ API, allowing for filtering and pagination.

## Arguments
- `order_by` (optional): The parameter to order the results by. Defaults to `missing`.
- `sort_order` (optional): The sort order for the results. Defaults to `missing`.
- `limit` (optional): The maximum number of results to return. Defaults to 100.
- `page` (optional): The page number to retrieve. Defaults to 1.
- `as_data_frame` (optional): If `true`, returns the data as a data frame. Defaults to `true`.
- `rate_limit` (optional): If `true`, applies a rate limit to the API requests. Defaults to `false`.
- `api_key` (optional): The API key to use for authentication. Defaults to `missing`.

## Returns
- A DataFrame or the raw data, depending on the `as_data_frame` argument.

"""
function list_parameters(;
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


    data = openaq_fetch("parameters", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) : data

    return data

end


