

function get_owner(owners_id::Int;
    as_data_frame::Bool = true, 
    rate_limit::Bool = false, 
    api_key::Union{String, Missing}=missing
    )

    path = "owners/$owners_id"

    data = openaq_fetch(path, Dict(), rate_limit, api_key)

    data = as_data_frame ? convert_to_dataframe(data) : data

end


function list_owners(;
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


    data = openaq_fetch("owners", params_list, rate_limit, api_key)

    # If as data frame, convert and extract manufacturer info; else just return the data
    data = as_data_frame ? convert_to_dataframe(data) : data

    return data

end
