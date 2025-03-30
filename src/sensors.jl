
function get_sensor(sensors_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "sensors/$sensors_id"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> process_sensors : data

end



function process_sensors(df::DataFrame)
    @chain df begin
        transform(:parameter => ByRow(get_parameter_data) => AsTable)
        select(Not([:parameter]))
    end
end



function get_location_sensors(locations_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "locations/$locations_id/sensors"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) |> process_location_sensors : data

end


# df = get_location_sensors(79) 

function process_location_sensors(df::DataFrame)
    @chain df begin 
        transform(:summary => AsTable)
        transform(:coverage => AsTable)
        transform(:latest => AsTable)
        transform(:coordinates => ByRow(extract_coordinates_info) => AsTable)
        transform(:parameter => ByRow(get_parameter_data) => AsTable)
        transform(Cols(contains("datetime")) .=> ByRow(x -> extract_datetime_info(x).datetime_utc), renamecols = false)
        select(Not([:summary, :coverage, :latest, :value, :coordinates, :parameter]))
        select(Cols(contains("parameter")), Cols(contains("datetime")), :)
        rename(:id => :sensor_id)
        select(:sensor_id, :)
        # Drop columns that are all of type Nothing
        select(_, findall(col -> all(v -> !isnothing(v), col), eachcol(_)))
    end
end

