

"""
get a single location from the locations resource.

# Arguments
- `location_id::Int`: An integer.
- `as_data_frame::Bool=true`: Logical for toggling whether to return results as data frame or list, defaults to true.
- `dry_run::Bool=false`: Logical for toggling a dry run of the request, defaults to false.
- `rate_limit::Bool=false`: Logical for toggling automatic rate limiting based on rate limit headers, defaults to false.
- `api_key::String=nothing`: A valid OpenAQ API key string, defaults to nothing.

# Returns
- `DataFrame` or `Dict`.
"""
function get_location(
    licenses_id::Int;
    as_data_frame::Bool=true,
    rate_limit::Bool=false,
    api_key::Union{Missing,String}=missing)
  path = "locations/$licenses_id"
  data = openaq_fetch(path, Dict(), rate_limit, api_key)
  
  
  data = as_data_frame ? convert_to_dataframe(data) |> process_locations : data
end


"""
    extract_instrument_info(dicts::Union{Vector{Dict}, Vector{Any}}) -> NamedTuple

Extracts instrument IDs and names from a vector of dictionaries, returning them as a named tuple.
If any dictionary does not contain the expected keys ("id" and "name"), it returns `missing` for both.

# Arguments
- `dicts::Union{Vector{Dict}, Vector{Any}}`: A vector of dictionaries or any other type of elements.

# Returns
- A named tuple with two fields: `instrument_ids` and `instrument_names`.
  Each field contains a string joining the extracted IDs and names, respectively.
  If an error occurs during extraction, both fields are set to `missing`.

"""
function extract_instrument_info(dicts::Union{Vector{Dict}, Vector{Any}})
    try
        instrument_ids = map(dict -> dict["id"], dicts)
        instrument_names = map(dict -> dict["name"], dicts)
        return (instrument_ids = join(instrument_ids, ", "), instrument_names = join(instrument_names, ", "))
    catch e 
        return (instrument_ids = missing, instrument_names = missing)
    end
end

"""
    extract_owner_info(dict::Dict)

Extracts the owner's ID and name from a dictionary.

# Arguments
- `dict::Dict`: A dictionary containing owner information.

# Returns
- A named tuple with fields `owner_id` and `owner_name`. 
  If either key is missing in the dictionary, returns `missing` for that field.
"""
function extract_owner_info(dict::Dict)
    try 
        owner_id = dict["id"]
        owner_name = dict["name"]
        return (owner_id = owner_id, owner_name = owner_name)
    catch e 
        return (owner_id = missing, owner_name = missing)
    end
end


"""
    extract_owner_info(dict::Dict)

Extracts the owner's ID and name from a dictionary.

# Arguments
- `dict::Dict`: A dictionary containing owner information.

# Returns
- A named tuple with fields `owner_id` and `owner_name`. 
  If either key is missing in the dictionary, returns `missing` for that field.
"""
function extract_provider_info(dicts::Union{Vector{Dict}, Vector{Any}, Vector{Dict{String, Any}}})
    try
        provider_ids = map(dict -> dict["id"], dicts)
        provider_names = map(dict -> dict["name"], dicts)
        return (provider_id = parse(Int, join(provider_ids, ", ")), provider_name = join(provider_names, ", "))
    catch e 
        return (provider_id = missing, provider_name = missing)
    end
end

"""
extract_provider_info(dict::Dict) -> NamedTuple

Extracts the provider's ID and name from a given dictionary. If the keys "id" or "name" are not present in the dictionary, returns `missing` for each value.

# Arguments
- `dict::Dict`: A dictionary containing provider information.

# Returns
- A named tuple with two fields:
  - `provider_id`: The ID of the provider.
  - `provider_name`: The name of the provider.
"""
function extract_provider_info(dict::Dict)
    try
        provider_id = dict["id"]
        provider_name = dict["name"]
        return (provider_id = provider_id, provider_name = provider_name)
    catch e 
        return (provider_id = missing, provider_name = missing)
    end
end

"""
Extracts and returns country information from a given dictionary.

This function attempts to retrieve the 'id', 'name', and 'code' keys
from the input dictionary. If any of these keys are missing, it catches
the error and returns `missing` for each corresponding field.

# Arguments:
- `dict::Dict`: The dictionary containing country information.

# Returns:
- A tuple with fields `country_id`, `country_name`, and `country_iso`.
  Each field contains the respective value if found, otherwise `missing`.
"""
function extract_country_info(dict::Dict)
    try
        country_id = dict["id"]
        country_name = dict["name"]
        country_iso = dict["code"]
        return (country_id = country_id, country_name = country_name, country_iso = country_iso)
    catch e 
        return (country_id = missing, country_name = missing, country_iso = missing)
    end
end


"""
    process_locations(df::DataFrame) -> DataFrame

Process a DataFrame containing location data by extracting and transforming relevant information into new tables or selecting specific columns. This function cleans and prepares the location data for further analysis.

# Arguments
- `df::DataFrame`: A DataFrame with raw location data, including instrument, country, coordinates, datetime, owner, and provider information.

# Returns
- `DataFrame`: A processed DataFrame with transformed and selected columns:
  - `id`
  - `name`
  - Columns starting with "is"
  """
function process_locations(df::DataFrame)
    @chain df begin 
        transform(:instruments => ByRow(extract_instrument_info) => AsTable)
        transform(:country => ByRow(extract_country_info) => AsTable)
        transform(:coordinates => ByRow(extract_coordinates_info) => AsTable)
        transform(Cols(contains("datetime")) .=> ByRow(x -> extract_datetime_info(x).datetime_utc), renamecols = false)
        transform(:owner => ByRow(extract_owner_info) => AsTable)
        transform(:provider => ByRow(extract_provider_info) => AsTable)
        transform(:bounds => ByRow(x -> convert(Vector{Float64}, x)), renamecols=false)
        transform(:sensors => ByRow(x -> convert(Vector{Dict}, x)), renamecols = false)
        select(Not([:instruments, :coordinates, :provider, :country, :owner]))
        # The following columns are not returned in openaq-r; keeping bounds and sensors though 
        select(Not(Cols(contains(r"locality|distance|instrument|license"))))
        select(:id, :name, Cols(startswith("is"), :))
    end
end


"""
Lists locations based on various criteria.

This function interacts with the OpenAQ API to retrieve a list of locations
matching specified parameters. It allows filtering by bounding box,
coordinates, radius, providers, parameters, owner contacts, manufacturers,
licenses, monitor type, mobile sensors, instruments, countries, and sorting.

# Arguments
- `bbox::Union{Missing, AbstractVector, String}`:  Bounding box coordinates.
- `coordinates::Union{Missing, AbstractVector}`: Coordinates for filtering.
- `radius::Union{Missing, Int}`: Radius around coordinates.
- `providers_id::Union{Missing, AbstractVector, Int}`: IDs of providers to filter by.
- `parameters_id::Union{Missing, AbstractVector, Int}`: IDs of parameters to filter by.
- `owner_contacts_id::Union{Missing, AbstractVector, Int}`: IDs of owner contacts to filter by.
- `manufacturers_id::Union{Missing, AbstractVector, Int}`: IDs of manufacturers to filter by.
- `licenses_id::Union{Missing, AbstractVector, Int}`: IDs of licenses to filter by.
- `monitor::Union{Missing, String}`: Monitor type to filter by.
- `mobile::Union{Missing, Bool}`: Whether to filter for mobile sensors.
- `instruments_id::Union{Missing, AbstractVector, Int}`: IDs of instruments to filter by.
- `iso::Union{Missing, String}`: ISO code to filter by.
- `countries_id::Union{Missing, AbstractVector, Int}`: IDs of countries to filter by.
- `order_by::Union{Missing, String}`: Field to order the results by.
- `sort_order::Union{Missing, String}`: Order direction ('asc' or 'desc').
- `limit::Int = 100`: Maximum number of results to return.
- `page::Int = 1`: Page number for pagination.
- `as_data_frame::Bool = true`:  Logical for toggling whether to return results as data frame or list.
- `rate_limit::Bool = false`: Logical for toggling automatic rate limiting based on rate limit headers.
- `api_key::Union{Missing, String} = nothing`: A valid OpenAQ API key string.

# Returns
- `DataFrame` 
"""
function list_locations(;
    bbox::Union{Missing, AbstractVector, String} = missing,
    coordinates::Union{Missing, NamedTuple} = missing,
    radius::Union{Missing, Int} = missing,
    providers_id::Union{Missing, AbstractVector, Int} = missing,
    parameters_id::Union{Missing, AbstractVector, Int} = missing,
    owner_contacts_id::Union{Missing, AbstractVector, Int} = missing,
    manufacturers_id::Union{Missing, AbstractVector, Int} = missing,
    licenses_id::Union{Missing, AbstractVector, Int} = missing,
    monitor::Union{Missing, String} = missing,
    mobile::Union{Missing, Bool} = missing,
    instruments_id::Union{Missing, AbstractVector, Int} = missing,
    iso::Union{Missing, String} = missing,
    countries_id::Union{Missing, AbstractVector, Int} = missing,
    order_by::Union{Missing, String} = missing,
    sort_order::Union{Missing, String} = missing,
    limit::Int = 100,
    page::Int = 1,
    as_data_frame::Bool = true,
    rate_limit::Bool = false,
    api_key::Union{Missing, String} = missing)

    coordinates = !ismissing(coordinates) ? join(coordinates, ",") : coordinates
    
     
    params_list = Dict(
        "bbox" => bbox,
        "coordinates" => coordinates,
        "radius" => radius,
        "providers_id" => providers_id,
        "parameters_id" => parameters_id,
        "owner_contacts_id" => owner_contacts_id,
        "manufacturers_id" => manufacturers_id,
        "licenses_id" => licenses_id,
        "monitor" => monitor,
        "mobile" => mobile,
        "instruments_id" => instruments_id,
        "iso" => iso,
        "countries_id" => countries_id,
        "order_by" => order_by,
        "sort_order" => sort_order,
        "limit" => limit,
        "page" => page)

    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)

    
    path = "locations"
    
    data = openaq_fetch(path, params_list, rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> process_locations : data

    return data

end

