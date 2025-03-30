
"""
Get a single manufacturer from the manufacturers resource.

# Arguments:
- `manufacturers_id::Int`: An integer.
- `as_data_frame::Bool = true`: A logical for toggling whether to return results as data frame or list, defaults to true.
- `dry_run::Bool = false`: A logical for toggling a dry run of the request, defaults to false.
- `rate_limit::Bool = false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to false.
- `api_key::Union{String, Nothing} = nothing`: A valid OpenAQ API key string, defaults to nothing.

# Returns:
- A data frame or a list of the results.
"""
function get_manufacturer(
    manufacturers_id::Int;
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{String, Missing}=missing
)
    path = "manufacturers/$manufacturers_id"
    data = openaq_fetch(path, Dict(), rate_limit, api_key)
    
    data = as_data_frame ? convert_to_dataframe(data) |> process_manufacturers : data

    return data
end



"""
    process_manufacturers(df::DataFrame) -> DataFrame

Process a DataFrame containing location data by extracting and transforming relevant information into new tables or selecting specific columns. This function cleans and prepares the location data for further analysis.

# Arguments
- `df::DataFrame`: A DataFrame with manufacturer's name, id, and a Dictionary of instruments.

# Returns
- `DataFrame`: A processed DataFrame with transformed and selected columns:
  - `id`
  - `name`
  - `instrument_id`
  - `instrument_name`
  """
function process_manufacturers(df::DataFrame)
    @chain df begin 
        transform(:instruments => ByRow(extract_instrument_info) => AsTable)
        select(Not([:instruments]))
    end
end



"""
Get a list of manufactuers from the manufacturers resource.

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
function list_manufacturers(;
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


    data = openaq_fetch("manufacturers", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) |> process_manufacturers : data

    return data
end

