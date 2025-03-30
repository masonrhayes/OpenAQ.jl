
include("../src/OpenAQ.jl")
using .OpenAQ
using DataFramesMeta, HTTP, Dates
using Test



@testset "Manufacturers" begin 
    @test list_manufacturers() isa DataFrame
    # g(location_id) should return a DataFrame
    @test list_manufacturer_instruments(10) isa DataFrame
    # get_location(location_id; as_data_frame = false) should return an HTTP.Messages.Response:
    @test get_manufacturer(10; as_data_frame = false) isa HTTP.Messages.Response

    # get_instrument() without any instrument_id should throw a MethodError
    @test_throws MethodError get_manufacturer() 
end

sleep(5)

@testset "Instruments" begin 
    @test list_instruments() isa DataFrame
    # g(location_id) should return a DataFrame
    @test get_instrument(10) isa DataFrame
    # get_location(location_id; as_data_frame = false) should return an HTTP.Messages.Response:
    @test get_instrument(10; as_data_frame = false) isa HTTP.Messages.Response

    # get_instrument() without any instrument_id should throw a MethodError
    @test_throws MethodError get_instrument() 

end

sleep(5)

@testset "Countries" begin 
    # get_country(country_id) should return a DataFrame
    @test get_country(79) isa DataFrame
    # get_country(country_id; as_data_frame = false) should return an HTTP.Messages.Response:
    @test get_country(79; as_data_frame = false) isa HTTP.Messages.Response

    @test list_countries() isa DataFrame
    @test list_countries(; parameters_id = 2) isa DataFrame
    @test list_countries(; parameters_id = [2,5]) isa DataFrame

    # get_country() without any country_id should throw a MethodError
    @test_throws MethodError get_country() 

end

sleep(5)




@testset "Latest" begin 
    @test list_location_latest(142) isa DataFrame

    @test list_parameters_latest(5) isa DataFrame 

    @test list_location_latest(142; as_data_frame = false) isa HTTP.Messages.Response

    @test list_parameters_latest(5; as_data_frame = false) isa HTTP.Messages.Response 


    @test list_parameters_latest(5; datetime_min = now() - Year(1)) isa DataFrame

    @test list_location_latest(142; datetime_min = now() - Year(5)) isa DataFrame

    @test_throws ArgumentError list_parameters_latest(5; datetime_min = now() + Month(1))

    @test_throws ArgumentError list_location_latest(142; datetime_min = now() + Month(1)) 
end

sleep(10)

@testset "Locations" begin 
    # get_location(location_id) should return a DataFrame
    @test get_location(142) isa DataFrame
    # get_location(location_id; as_data_frame = false) should return an HTTP.Messages.Response:
    @test get_location(142; as_data_frame = false) isa HTTP.Messages.Response

    # get_location() without any location_id should throw a MethodError
    @test_throws MethodError get_location() 

    @test list_locations(;countries_id = 79) isa DataFrame

end

sleep(5)

@testset "Measurements" begin 
    # list_xx_measurements requires providing an ID
    @test_throws MethodError list_sensor_measurements() 
    @test_throws MethodError list_location_measurements()

    @test list_location_measurements(155) isa DataFrame

    @test list_location_measurements(155, as_data_frame = false) isa Vector{Any}

    @test list_sensor_measurements(4961; rollup = "days") isa DataFrame

    # Test with adding DateTime arguments
    @test list_sensor_measurements(4961; rollup = "days", datetime_from = now() - Year(1), datetime_to = now()) isa DataFrame
end

@testset "Parameters" begin 
    # list_xx_measurements requires providing an ID
    @test_throws MethodError get_parameter() 

    @test get_parameter(5) isa DataFrame

    @test list_parameters() isa DataFrame
end

sleep(5)

@testset "Providers" begin 
    @test_throws MethodError get_provider() 

    @test get_provider(151) isa DataFrame

    @test get_provider(151; as_data_frame = false) isa HTTP.Messages.Response


    @test list_providers() isa DataFrame
end

sleep(5)

@testset "Owners" begin 
    @test_throws MethodError get_owner() 

    @test get_owner(14) isa DataFrame

    @test get_owner(14; as_data_frame = false) isa HTTP.Messages.Response


    @test list_owners() isa DataFrame
end

sleep(5)

@testset "Sensors" begin 
    @test_throws MethodError get_sensor() 

    @test get_sensor(218) isa DataFrame
    @test get_sensor(5) isa DataFrame

    @test get_sensor(218; as_data_frame = false) isa HTTP.Messages.Response

    @test get_location_sensors(142) isa DataFrame
    @test get_location_sensors(142; as_data_frame = false) isa HTTP.Messages.Response
end