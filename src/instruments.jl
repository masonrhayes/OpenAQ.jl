# instruments.jl

"""
Get a single instrument from the instruments resource.

# Arguments
- `instruments_id::Int`: An integer.
- `as_data_frame::Bool=true`: A logical for toggling whether to return results as data frame or list defaults to TRUE.
- `rate_limit::Bool=false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to FALSE.
- `api_key::String`: A valid OpenAQ API key string, defaults to missing.

# Returns
A data frame or a list of the results.
"""
function get_instrument(
    instruments_id::Int;
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{String, Missing}=missing
)
    path = "instruments/$instruments_id"
    data = openaq_fetch(path, Dict(), rate_limit, api_key)
   
    data = as_data_frame ? convert_to_dataframe(data) |> extract_manufacturer_info : data

    return data
end

"""
# get_manufacturer_data(dict::Dict)

Extracts and returns the manufacturer's ID and name from a dictionary.

## Arguments
- `dict::Dict`: A dictionary containing manufacturer data, expected to have keys `"id"` and `"name"`.

## Returns
- `(manufacturer_id = manufacturer_id, manufacturer_name = manufacturer_name)`: A tuple with named fields `manufacturer_id` and `manufacturer_name`.

"""
function get_manufacturer_data(dict::Dict)
    manufacturer_id = dict["id"]
    manufacturer_name = dict["name"]
    return (manufacturer_id = manufacturer_id, manufacturer_name = manufacturer_name)
end

"""
# get_manufacturer_data(dict::Dict)

Extracts and returns the manufacturer's ID and name from a dictionary.

## Arguments
- `dict::Union{Missing, Nothing}`: A dictionary containing missing or empty values.

## Returns
- `(manufacturer_id = "", manufacturer_name = "")`: A tuple with named fields `manufacturer_id` and `manufacturer_name`.
"""

function get_manufacturer_data(dict::Union{Missing, Nothing})
    return missing
end

"""
`extract_manufacturer_info(df::DataFrame) -> DataFrame`

Transforms a DataFrame containing manufacturer information to extract relevant details. The transformation steps include:
1. Extracting additional data for each manufacturer using the `get_manufacturer_data` function.
2. Removing the original `manufacturer` column.
3. Selecting specific columns including `name`, `id`, `is_monitor`, and all columns containing of the manufacturer info.

# Arguments
- `df::DataFrame`: Input DataFrame with manufacturer information.

# Returns
- A new DataFrame containing transformed data.
"""
function extract_manufacturer_info(df::DataFrame)
    @chain df begin
        transform(:manufacturer => ByRow(get_manufacturer_data) => AsTable)
        select(Not([:manufacturer]))
        select(:name, :id, :is_monitor, Cols(contains("manu"))) 
    end
end



"""
Get a list of instruments from the instruments resource.

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
function list_instruments(
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


    data = openaq_fetch("instruments", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) |> extract_manufacturer_info : data

    return data
end


"""
Get a list of manufacturer instruments from the instruments resource.

# Arguments
- `manufacturers_id::Int`: An integer.
- `as_data_frame::Bool=true`: A logical for toggling whether to return results as data frame or list defaults to TRUE.
- `rate_limit::Bool=false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to FALSE.
- `api_key::Union{String, Missing}=missing`: A valid OpenAQ API key string, defaults to missing.

# Returns
A data frame or a list of the results.
"""
function list_manufacturer_instruments(
    manufacturers_id::Int;
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{String, Missing}=missing
)
    path = "manufacturers/$manufacturers_id/instruments"
    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> extract_manufacturer_info : data

    return data
end
