

"""
Fetches sensor measurements from the OpenAQ API.

## Arguments
- `sensors_id::Union{Missing, Int}`: The ID of the sensor to retrieve measurements for. Defaults to `missing`.
- `data::Union{String, Missing}`: The name of the data file to fetch. Defaults to `"measurements"`.
- `rollup::Union{Missing, String}`: The time aggregation level (e.g., "minutes", "hours", "days", "months"). Defaults to `missing`.
- `datetime_from::Union{DateTime, Missing}`: The start date and time for the measurements. Defaults to `missing`.
- `datetime_to::Union{DateTime, Missing}`: The end date and time for the measurements. Defaults to `missing`.
- `order_by::Union{Missing, String}`: The field to order the results by (e.g., "timestamp"). Defaults to `missing`.
- `sort_order::Union{Missing, String}`: The order of the results (e.g., "asc", "desc"). Defaults to `missing`.
- `limit::Int`: The maximum number of results to return. Defaults to 100.
- `page::Int`: The page number to retrieve. Defaults to 1.
- `as_data_frame::Bool`: Whether to return the data as a DataFrame. Defaults to `true`.
- `rate_limit::Bool`: Whether to apply rate limiting. Defaults to `false`.
- `api_key::Union{Missing, String}`: The OpenAQ API key. Defaults to `missing`.

## Returns
- `data::DataFrame | Array{...}`: A DataFrame or array containing the sensor measurements.  The data type depends on the `as_data_frame` argument.
"""
function list_sensor_measurements(
    sensors_id::Union{Missing, Int} = missing;
    data::Union{String, Missing} = "measurements",
    rollup::Union{Missing, String} = missing,
    datetime_from::Union{DateTime, Missing} = missing, 
    datetime_to::Union{DateTime, Missing} = missing, 
    order_by::Union{Missing, String} = missing,
    sort_order::Union{Missing, String} = missing,
    limit::Int = 100,
    page::Int = 1,
    as_data_frame::Bool = true,
    rate_limit::Bool = false,
    api_key::Union{Missing, String} = missing)

    @assert (rollup ∈ ["hours", "days", "years"]) | ismissing(rollup)

    datetime_from, datetime_to = validate_datetime.([datetime_from, datetime_to])
    
     
    params_list = Dict(
        "datetime_from" => datetime_from, 
        "datetime_to" => datetime_to,
        "order_by" => order_by,
        "sort_order" => sort_order,
        "limit" => limit,
        "page" => page)

    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)

    
    path = (ismissing(rollup) || isnothing(rollup)) ? "sensors/$sensors_id/$data" : "sensors/$sensors_id/$rollup"
    
    data = openaq_fetch(path, params_list, rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> process_sensor_measurements : data

    return data
end

function validate_datetime(dt::DateTime)
    # Only get to accuracy of the nearest second
    round(dt, Second) |> string
end

function validate_datetime(dt::Missing)
    missing
end


"""
    get_parameter_data(dict::Dict)

Extracts parameter data from a dictionary.

This function takes a dictionary containing parameter information and returns a tuple
containing the `parameter_id`, `parameter_name`, and `parameter_units`.

# Arguments
- `dict::Dict`: A dictionary where keys are strings representing the parameter
  attributes ("id", "name", "units") and values are the corresponding
  parameter values.

# Returns
- `(parameter_id = id, parameter_name = name, parameter_units = units)`: A tuple
  containing the extracted parameter data.
"""
function get_parameter_data(dict::Dict)
    id =  dict["id"]
    name = dict["name"]
    units = dict["units"]
    
    return (parameter_id = id, parameter_name = name, parameter_units = units)
end

"""
Extracts period data from a dictionary.

Args:

    dict (Dict): A dictionary containing period data.
        Expected keys:

            - "interval": The interval for the period.
            - "label": The label for the period.
            - "datetimeTo": The end datetime for the period.
            - "datetimeFrom": The start datetime for the period.

Returns:

    Tuple[Float64, String, DateTime, DateTime]: A tuple containing the period interval, label, start datetime, and end datetime.
"""
function get_period_data(dict::Dict)
    interval =  dict["interval"]
    label = dict["label"]
    datetime_to = dict["datetimeTo"]
    datetime_from = dict["datetimeFrom"]

    return (period_interval = interval, period_label = label, datetime_from = datetime_from, datetime_to = datetime_to)
end


function get_period_data(dict::Union{Nothing, Missing})
    return (period_interval = missing, period_label = missing, datetime_from = missing, datetime_to = missing)
end

# TODO Implement a more sensible way to handle different rollups

# Create handlers to catch summary data only if it is available (i.e., only when 
# rollup is provided.)

function get_summary_data(dict::Dict)
    return dict
end

function get_summary_data(dict::Union{Nothing, Missing})
    return Dict(:summary => missing)
end


"""
    process_sensor_measurements(df::DataFrame)

Processes a DataFrame containing sensor data, extracting and transforming relevant information.

This function takes a DataFrame (`df`) as input and performs the following steps:

1.  Extracts coverage data as an `AsTable`.
2.  Extracts latitude and longitude coordinates from the `coordinates` column using `extract_coordinates_info` as an `AsTable`.
3.  Extracts period data (label, interval, `datetime_from`, `datetime_to`) using `get_period_data` as an `AsTable`.
4.  Extracts parameter data (id, name, units) using `get_parameter_data` as an `AsTable`.
5.  Extracts summary data (quantiles, min, max, avg, sd) from the `summary` column as an `AsTable`.
6.  Extracts datetime information as UTC using `extract_datetime_info` for columns containing "datetime", renaming is disabled.
7.  Selects the desired columns, dropping the `period`, `flag_info`, `coverage`, `parameter`, `summary`, and `coordinates` columns.
8.  Canonicalizes the period interval into a `CompoundPeriod`.
9.  Selects the remaining columns in a preferred order.

Args:
    df::DataFrame: The input DataFrame containing sensor data.

Returns:
    DataFrame: A new DataFrame containing the processed sensor data.

Raises:
    error("Sensor data processing failed."): If any error occurs during the processing steps.
"""
function process_sensor_measurements(df::DataFrame)
    try 
        df = @chain df begin 
            # Don't need 'flag_info'
            transform(:coverage => AsTable) # get coverage
            select(Not(Cols(contains("date")))) # don't get the 'dates' from coverage
            transform(:coordinates => ByRow(extract_coordinates_info) => AsTable) # get lat, lon
            transform(:period => ByRow(get_period_data) => AsTable) # get period label, interval, datetime_from and datetime_to
            transform(:parameter => ByRow(get_parameter_data) => AsTable) # get parameter id, name, units.
            transform(:summary => ByRow(get_summary_data) => AsTable) # get summary data (quantiles, min, max, avg, sd)
            transform(Cols(contains("datetime")) .=> ByRow(x -> extract_datetime_info(x).datetime_utc), renamecols = false) # extract datetime as UTC
            select(Not([:period, :flag_info, :coverage, :parameter, :summary, :coordinates])) # drop parse data
            @rtransform(:period_interval = canonicalize(:datetime_to - :datetime_from)) # set interval as a CompoundPeriod
            select(:value, Cols(contains("parameter")), Cols(contains("period")), Cols(contains("datetime")), :) # select rows in order of preference
        end

        return df
    catch e 
        throw(error("Sensor data processing failed."))
    end

end

# 
function list_location_measurements(
    locations_id::Union{Missing, Int} = missing;
    parameters_ids::Union{Missing, Int, Vector{Int}} = missing,
    data::Union{String, Missing} = "measurements",
    rollup::Union{Missing, String} = missing,
    datetime_from::Union{DateTime, Missing} = missing, 
    datetime_to::Union{DateTime, Missing} = missing, 
    order_by::Union{Missing, String} = missing,
    sort_order::Union{Missing, String} = missing,
    limit::Int = 100,
    page::Int = 1,
    as_data_frame::Bool = true,
    rate_limit::Bool = false,
    api_key::Union{Missing, String} = missing)

    # Assert that rollup should be in hours, days, years, or else missing.
    @assert (rollup ∈ ["hours", "days", "years"]) | ismissing(rollup)

    # Round DateTimes to nearest Second and parse as String
    datetime_from, datetime_to = validate_datetime.([datetime_from, datetime_to]) 
    
    # Get location info
    location = get_location(locations_id; as_data_frame = true) |> extract_location_sensors

    # Get sensor IDs associated with location, and paramater IDs associated with sensors.
    sensors_ids = collect(location.sensor_ids...)
    sensor_parameter_ids = collect(location.sensor_parameter_ids...)


    # If parameters_ids is provided, then adjust sensor ids accordingly.
    if !ismissing(parameters_ids) && !isempty(parameters_ids)
        selected_parameters = filter(x -> x ∈ parameters_ids, sensor_parameter_ids)

        length(selected_parameters) == 0 ? throw(ErrorException("Parameter $parameters_ids not available at this location.")) : nothing

        selected_parameters_indicies = indexin(selected_parameters, sensor_parameter_ids)
        
        sensors_ids = sensors_ids[selected_parameters_indicies]
    end

    # List of query parameters
    params_list = Dict(
        "datetime_from" => datetime_from, 
        "datetime_to" => datetime_to,
        "order_by" => order_by,
        "sort_order" => sort_order,
        "limit" => limit,
        "page" => page)

    # If no query parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)


    results = map(sensors_ids) do sensor_id
        path = (ismissing(rollup) || isnothing(rollup)) ? "sensors/$sensor_id/$data" : "sensors/$sensor_id/$rollup"

        @info "Requesting data on sensors: $sensor_id"

        result = openaq_fetch(path, params_list, rate_limit, api_key)

        result = as_data_frame ? convert_to_dataframe(result) |> process_sensor_measurements : result
    end

    return foldr(vcat, results, init = DataFrame())

end


function get_sensor_ids(dicts::Vector{Dict})
    ids = map(dict -> dict["id"], dicts)
    names = map(dict -> dict["name"], dicts)
    params = map(dict -> dict["parameter"], dicts) .|> get_parameter_data 
    param_ids = [x.parameter_id for x in params]

    return (sensor_ids = ids, sensor_names = names, sensor_parameter_ids = param_ids)
end

function extract_location_sensors(df::DataFrame)
    @chain df begin 
        transform(:sensors => ByRow(get_sensor_ids) => AsTable)
        select(Not([:sensors]))
    end
end

