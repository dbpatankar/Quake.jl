# Struct and Parsers for various signal format files such as PEERNGA, COSMOS etc

struct TimeSeries
    t
    y
    meta::Dict
end

"""
    read_peernga_file(filename::String, skiprows=4)

Reads a PeerNGA format file and returns a TimeSeries struct.

# Parameters
`filename` (String): Name of the PeerNGA format file

# kwargs
`skiprows` (Integer): Initial number of rows to skip

# Returns
TimeSeries struct
"""
function read_peernga_file(filename::String, skiprows=4)
    start = skiprows + 1
    headRows = skiprows
    lines = readlines(filename)

    # parse line 2
    try
        event, date, station, comp = [strip(i) for i in split(lines[2], ",")]
    catch
        println("Unable to parse event, date, station and component on line 2")
        event, date, station, comp = [" " for i = 1:4]
    end


    # parse lines for yunit
    yunitVec = [match(r"(.*TIME SERIES IN UNITS OF.*)", lines[i]) for i = 1:headRows]
    yunitline = yunitVec[yunitVec .!= nothing]
    yunit = length(yunitline) == 0 ? " " : yunitline[1]

    # parse lines for npts and dt
    ptslineVec = [match(r"\s*[NPTSnpts ]*=?\s*(\d*).*[DTdt ]+=?\s*([\.0-9]+)\s*SEC", lines[i]) for i=1:headRows]
    ptsline = ptslineVec[ptslineVec .!= nothing]
    npts, dt = length(ptsline) == 0 ? ["-9", "-1"] : ptsline[1]
    npts = parse(Int64, npts)
    dt = parse(Float64, dt)

    # Get the data
    try
        y = [parse(Float64, j) for i = start:length(lines) for j in split(lines[i])]
    catch e
        println("Unable to read data from file.")
        throw(e)
    end
    t = dt:dt:npts*dt

    meta = Dict(
        "dt" => dt,
        "npts" => npts,
        "yunit" => yunit,
        "duration" => t[end],
        "event" => event,
        "date" => date,
        "station" => station,
        "component" => comp,
    )
    return TimeSeries(t, y, meta)
end


"""
    read_cosmosvdc_file(filename, skiprows=6)

# Parameters
`filename` (String): cosmosDB vdc file name.

# Kwargs
`skiprows` (Integer): Number of rows to skip at the beginning.

# Returns
three TimeSeries structs for acceleration, velocity and displacement, respectively.
"""
function read_cosmosvdc_file(filename::String, skiprows=6)
    start = skiprows + 1
    lines = readlines(filename)

    # parse line 1 for event details
    event, md, y = split(strip(lines[1]), ",")
    date = strip(md * y)

    # parse line 2 for station details
    station, lat, lon, comp = match(r"\s*(\S*)\s*Lat.*Lon([\-0-9 ]+[NnSs])\s*([ \-0-9]+[EeWw])\s*Comp:\s*(.*)", lines[2])

    # parse line 3
    filter = lines[3]

    # parse line 4 for initial conditions
    initV = match(r"\s*Initial\s*Velocity\s*=\s*([\-\.0-9E]*)\s*(\S*)", lines[4])
    initV = initV[1] * " " * initV[2]
    initD = match(r".*Initial\s*Displacement\s*=\s*([\-\.0-9E]*)\s*(\S*)", lines[4])
    initD = initD[1] * " " * initD[2]

    # parse npts, dt
    npts, aunit, dt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[skiprows])
    npts = parse(Int64, npts)
    dt = parse(Float64, dt)
    t = dt:dt:npts*dt

    # read acceleration data
    ptsPerLine = length(split(lines[start]))
    nLines = trunc(Int, npts/(ptsPerLine+0.001)) + 1
    aEnd = skiprows + nLines
    a = [parse(Float64, j) for i = start:aEnd for j in split(lines[i])]

    # read velocity data
    vStart = aEnd + 3
    vnpts, vunit, vdt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[vStart-1])
    vnLines = trunc(Int, vnpts/(ptsPerLine+0.001)) + 1
    vEnd = vStart + vnLines - 1
    v = [parse(Float64, j) for i = vStart:vEnd for j in split(lines[i])]

    # read displacement data
    dStart = vEnd + 3
    dnpts, dunit, ddt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[dStart-1])
    dnLines = trunc(Int, dnpts/(ptsPerLine+0.001)) + 1
    dEnd = dStart + dnLines - 1
    d = [parse(Float64, j) for i = dStart:dEnd for j in split(lines[i])]

    # prepare data to return
    aMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => aunit, "npts" => npts, "dt" => dt,
    )
    vMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => vunit, "npts" => vnpts, "dt" => vdt,
    )
    dMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => dunit, "npts" => dnpts, "dt" => ddt,
    )
    return TimeSeries(t, a, aMeta), TimeSeries(t, v, vMeta), TimeSeries(t, d, dMeta)
end
