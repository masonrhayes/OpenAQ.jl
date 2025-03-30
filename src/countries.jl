"""
Get a single country from countries resource.

# Arguments
- `countries_id::Int`: An integer representing the OpenAQ countries_id.
- `as_data_frame::Bool=true`: A logical for toggling whether to return results as data frame or list, defaults to true.
- `rate_limit::Bool=false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to false.
- `api_key::Union{String,Missing}=missing`: A valid OpenAQ API key string, defaults to missing.

# Returns
A data frame or list of the results.

# Examples
julia> country = get_country(42)
"""
function get_country(countries_id::Int; as_data_frame::Bool=true, rate_limit::Bool=false, api_key::Union{String,Missing}=missing)
    path = "countries/$countries_id"
    data = openaq_fetch(path, Dict(), rate_limit, api_key)
    if as_data_frame
        return convert_to_dataframe(data) |> extract_parameter_info
    else
        return data
    end
end



function get_parameter_data(dicts::Union{Vector{Dict}, Vector{Any}})
    ids = map(dict -> dict["id"], dicts)
    names = map(dict -> dict["name"], dicts)
    units = map(dict -> dict["units"], dicts)
    return (parameter_ids = join(ids, ", "), parameter_names = join(names, ", "), parameter_units = join(units, ", "))
end

function get_parameter_data(dicts::Union{Missing, Nothing})
    return (parameter_ids = "", parameter_names = "", parameter_units = "")
end

# Rename function to turn CamelCase to snake_case
snake_case(x) = lowercase(replace(x, r"([a-z])([A-Z])" => s"\1_\2"))

# Parse date time - only care about first 19 digits - i.e., dateformat"yyyy-mm-dd\T:HH:MM:ss"
parse_datetime(x) = try DateTime(x[1:19]) catch e missing end
parse_datetime(x::Union{Missing, Nothing}) = missing
parse_datetime(x::Dict) = x


function convert_to_dataframe(resp::HTTP.Messages.Response)
    body = String(copy(resp.body))
    json = JSON.parse(body)
    results = json["results"]

    isempty(results) && throw(error("No results found. Try a different query."))

    df = DataFrame(results)
    rename!(snake_case, df)
    transform!(df, Cols(contains("datetime")) .=> ByRow(parse_datetime), renamecols = false)
end

function extract_parameter_info(df::DataFrame)
    # Transform data 
    @chain df begin
        # rename(:name => :country_name, :id => :country_id, :code => :country_code)
        transform(:parameters => ByRow(get_parameter_data) => AsTable)
        select(Not([:parameters]))
        select(:name, :id, :code, :datetime_first, :datetime_last, Cols(contains("param")))
    end
end

# A nice way to get the data as DataFrame rather than column lists...
# new_country_df = @chain country_df begin
#     # groupby(Not([:parameters]))
#     # combine(_) do sdf 
#     #     params_df = foldr(vcat, DataFrame.(sdf.parameters[1]), init = DataFrame())
#     #     rename(params_df, :id => :param_id, :name => :param_name, :units => :param_units)
#     # end
# end

"""
Get a list of countries from the countries resource.

# Arguments
- `providers_id::Union{Int,Vector{Int}}=missing`: An integer or a list of integers.
- `parameters_id::Union{Int,Vector{Int}}=missing`: An integer or a list of integers.
- `order_by::Union{String,Missing}=missing`: A string.
- `sort_order::Union{String,Missing}=missing`: A string.
- `limit::Union{Int,Missing}=100`: An integer.
- `page::Union{Int,Missing}=1`: An integer.
- `as_data_frame::Bool=true`: A logical for toggling whether to return results as data frame or list, defaults to true.
- `rate_limit::Bool=false`: A logical for toggling automatic rate limiting based on rate limit headers, defaults to false.
- `api_key::Union{String,Missing}=missing`: A valid OpenAQ API key string, defaults to missing.

# Returns
A data frame or a list of the results.

# Examples
julia> countries = list_countries()
"""
function list_countries(;providers_id::Union{Int,Vector{Int}, Missing}=missing, parameters_id::Union{Int,Vector{Int}, Missing}=missing,
                        order_by::Union{String,Missing}=missing, sort_order::Union{String,Missing}=missing,
                        limit::Union{Int,Missing}=100, page::Union{Int,Missing}=1,
                        as_data_frame::Bool=true, rate_limit::Bool=false, api_key::Union{String,Missing}=missing)


    params_list = Dict(
        :providers_id=> providers_id,
        :parameters_id => parameters_id,
        :order_by => order_by,
        :sort_order => sort_order,
        :limit => limit,
        :page=>page
    )
    
    # If no parameter provided, do not pass it as a query.
    params_list = filter(x -> (!ismissing(x.second)), params_list)

    path = "countries"
    data = openaq_fetch(path, params_list, rate_limit, api_key)
    if as_data_frame
        return convert_to_dataframe(data) |> extract_parameter_info
    else
        return data
    end
end


list_countries()