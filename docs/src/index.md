```@meta
CurrentModule = OpenAQ
```

# OpenAQ

A Julia package for interacting with the OpenAQ API. Functionality is intended to be closely aligned with the OpenAQ R package, [openaq-r](https://github.com/openaq/openaq-r/).

Documentation for [OpenAQ.jl](https://github.com/masonrhayes/OpenAQ.jl)

To add the package, run:

```julia-repl 
pkg> add https://github.com/masonrhayes/OpenAQ.jl
```

# Example usage 

```julia-repl

using OpenAQ 

locations = list_locations(;
    parameters_id = 2, 
    coordinates = c(latitude = -18.90848, longitude = 47.53751),
    radius = 10000
)
```

This returns a DataFrame that looks something like:

| id       | name         | is_monitor | is_mobile | timezone         | datetime_first      | sensors                           | datetime_last       | bounds                            | country_id | country_name | country_iso | latitude | longitude | owner_id | owner_name                               | provider_id | provider_name |
| :------- | :------------- | :--------- | :-------- | :--------------- | :------------------ | :-------------------------------- | :------------------ | :------------------------------- | :--------- | :---------- | :-------- | :------- | :-------- | :------- | :-------------------------------------- | :---------- | :------------- |
| 41726    | Antananarivo  | true       | false     | Indian/Antananarivo | 2020-12-22T07:00:00 | Dict[Dict{String, Any}("name"=>"… | 2025-03-04T12:00:00 | [47.5375, -18.9085, 47.5375, -18…        | 182         | Madagascar   | MG          | -18.9085   | 47.5375        | 4          | Unknown Governmental Organization | 119        | AirNow         |

