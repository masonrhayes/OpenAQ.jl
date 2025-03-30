
# OpenAQ.jl  <img src="docs/src/assets/logo.png" align="right" alt="openaq hex logo" style="height: 140px;"/>

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

An (unofficial) Julia package for interacting with the OpenAQ API. The funcationality of this package is intended to be closely aligned with the OpenAQ R package, [openaq-r](https://github.com/openaq/openaq-r/).


To add the package, run:

```julia
using Pkg
Pkg.add(url = "https://github.com/masonrhayes/OpenAQ.jl")
```

# Quick start

The following guide is a quick and minimal example to get you started.

1. Register for an account at https://explore.openaq.org/register.
2. Find your API key in the user account page.
3. Save your API key as the OPENAQ_API_KEY environment variable. You can edit this in two ways
    1. **Recommended**: Add `ENV["OPENAQ_API_KEY"] = "your_api_key"` to your `.julia/config/startup.jl` file (which may not yet exist). This will make your API key available on each new Julia session.
    2. Run `ENV["OPENAQ_API_KEY"] = "your_api_key"` in the Julia REPL. This will require running again with each new Julia session.

Now we can query OpenAQ for air quality monitoring locations. For this example we will query locations that measure PM2.5 near (with 10km) Antananarivo, Madagascar (-18.90848, 47.53751):

```julia
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

