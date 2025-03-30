module OpenAQ

    using HTTP, JSON, DataFramesMeta, Dates

    include("api.jl")
    include("countries.jl")
    include("instruments.jl")
    include("latest.jl")
    include("licenses.jl")
    include("locations.jl")
    include("manufacturers.jl")
    include("measurements.jl")
    include("owners.jl")
    include("parameters.jl")
    include("providers.jl")
    include("sensors.jl")


    export 
    # API 
    set_api_key,
    get_api_key, 
    set_base_url,
    enable_rate_limit,
    # Countries 
    get_country, 
    list_countries,
    # Instruments
    get_instrument,
    list_instruments,
    list_manufacturer_instruments,
    # Latest 
    list_location_latest, 
    list_parameters_latest,
    # Locations
    get_location,
    list_locations,
    # Licenses 
    get_license,
    list_licenses,
    # Manufacturers
    get_manufacturer, 
    list_manufacturers,
    # Measurements 
    list_sensor_measurements,
    list_location_measurements,
    # Owners
    get_owner, 
    list_owners,
    # Parameters 
    get_parameter,
    list_parameters,
    # Providers
    get_provider, 
    list_providers,
    # Sensors
    get_sensor,
    get_location_sensors

end # module OpenAQ

