


"""
Get the latest measurements by locations_id.

# Arguments
- `locations_id::Int`: An integer.
- `datetime_min::Union{Missing, String}=missing`: A string.
- `limit::Union{Missing, Int}=missing`: An integer.
- `page::Union{Missing, Int}=missing`: An integer.
- `as_data_frame::Bool=true`: Logical for toggling whether to return results as data frame or list, defaults to TRUE.
- `dry_run::Bool=false`: Logical for toggling a dry run of the request, defaults to FALSE.
- `rate_limit::Bool=false`: Logical for toggling automatic rate limiting based on rate limit headers, defaults to FALSE.

# Returns
- A DataFrame or a List of results.
"""
function list_location_latest(locations_id::Int;
                             datetime_min::Union{Missing, DateTime}=missing,
                             limit::Union{Missing, Int}=missing,
                             page::Union{Missing, Int}=missing,
                             as_data_frame::Bool=true,
                             rate_limit::Bool=false, 
                             api_key::Union{String, Missing}=missing)

    datetime_min = validate_datetime(datetime_min)
    
    params_list = Dict(
        :datetime_min =>datetime_min,
        :limit =>limit,
        :page =>page
    )

    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)

    path = "locations/$locations_id/latest"
    data = openaq_fetch(path, params_list, rate_limit, api_key)


    data = as_data_frame ? convert_to_dataframe(data) |> process_latest : data

    return data
end

function extract_datetime_info(dict::Dict)
    try 
        datetime_local = dict["local"] |> parse_datetime
        datetime_utc = dict["utc"] |> parse_datetime

        return (datetime_local = datetime_local, datetime_utc = datetime_utc)
    catch e 
        return (datetime_local = missing, datetime_utc = missing)
    end
end

function extract_datetime_info(x::Union{Missing, Nothing})
    return (datetime_local = missing, datetime_utc = missing)
end

function extract_coordinates_info(dict::Dict)
    try
        latitude = dict["latitude"] 
        longitude = dict["longitude"] 

        return (latitude = latitude, longitude = longitude)
    catch e 
        return (latitude = missing, longitude = missing)
    end
end

function extract_coordinates_info(x::Union{Missing, Nothing})
    return (latitude = missing, longitude = missing)
end


function process_latest(df::DataFrame)
    @chain df begin 
        transform(:datetime => ByRow(extract_datetime_info) => AsTable)
        transform(:coordinates => ByRow(extract_coordinates_info) => AsTable)
        select(Not([:datetime, :coordinates]))
        select(:sensors_id, :locations_id, :value, Cols(contains("datetime"), Cols(contains("tude"))))
    end
end




# df = list_location_latest(250)



function list_parameters_latest(parameters_id::Int;
    datetime_min::Union{Missing, DateTime}=missing,
    limit::Union{Missing, Int}=missing,
    page::Union{Missing, Int}=missing,
    as_data_frame::Bool=true,
    rate_limit::Bool=false, 
    api_key::Union{String, Missing}=missing)

    datetime_min = validate_datetime(datetime_min)

    params_list = Dict(
    :datetime_min =>datetime_min,
    :limit =>limit,
    :page =>page
    )


    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)

    path = "parameters/$parameters_id/latest"
    data = openaq_fetch(path, params_list, rate_limit, api_key)


    data = as_data_frame ? convert_to_dataframe(data) |> process_latest : data

    return data
end
