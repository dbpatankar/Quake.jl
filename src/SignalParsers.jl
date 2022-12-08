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
function read_peernga_file(filename, skiprows=4)
    start = skiprows + 1
    headRows = skiprows
    lines = readlines(filename)
    event, date, station, comp = [strip(i) for i in split(lines[2], ",")]
    yunitVec = [match(r"(.*TIME SERIES IN UNITS OF.*)", lines[i]) for i = 1:headRows]
    yunitline = yunitVec[yunitVec .!= nothing][1]
    yunit = yunitline[1]
    ptslineVec = [match(r"\s*[NPTSnpts ]*=?\s*(\d*).*[DTdt ]+=?\s*([\.0-9]+)\s*SEC", lines[i]) for i=1:headRows]
    ptsline = ptslineVec[ptslineVec .!= nothing][1]
    npts, dt = ptsline
    npts = parse(Int64, npts)
    dt = parse(Float64, dt)
    # Get the data
    y = [parse(Float64, j) for i = start:length(lines) for j in split(lines[i])]
    t = dt:dt:npts*dt
    #return TimeSeries(filename, t, y, dt, npts, yunit, t[end], event, date, station, comp, " ")
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
function read_cosmosvdc_file(filename, skiprows=6)
    start = skiprows + 1
    lines = readlines(filename)
    event, md, y = split(strip(lines[1]), ",")
    date = strip(md * y)
    station, lat, lon, comp = match(r"\s*(\S*)\s*Lat.*Lon([\-0-9 ]+[NnSs])\s*([ \-0-9]+[EeWw])\s*Comp:\s*(.*)", lines[2])
    filter = lines[3]
    initV = match(r"\s*Initial\s*Velocity\s*=\s*([\-\.0-9E]*)\s*(\S*)", lines[4])
    initV = initV[1] * " " * initV[2]
    initD = match(r".*Initial\s*Displacement\s*=\s*([\-\.0-9E]*)\s*(\S*)", lines[4])
    initD = initD[1] * " " * initD[2]
    npts, aunit, dt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[skiprows])
    npts = parse(Int64, npts)
    dt = parse(Float64, dt)
    t = dt:dt:npts*dt
    ptsPerLine = length(split(lines[start]))
    nLines = Int(ceil(npts/(ptsPerLine+0.001)))
    aEnd = skiprows + nLines
    a = [parse(Float64, j) for i = start:aEnd for j in split(lines[i])]
    vStart = aEnd + 3
    vEnd = vStart + nLines - 1
    v = [parse(Float64, j) for i = vStart:vEnd for j in split(lines[i])]
    dStart = vEnd + 3
    dEnd = dStart + nLines - 1
    d = [parse(Float64, j) for i = dStart:dEnd for j in split(lines[i])]
    npts, vunit, dt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[vStart-1])
    npts, dunit, dt = match(r"\s*(\d*)\s*(.*)at\s*([\.0-9]*)\s*\S*", lines[dStart-1])
    aMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => aunit,
    )
    vMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => vunit,
    )
    dMeta = Dict(
        "event" => event, "date" => date, "station" => station,
        "lat" => lat, "lon" => lon, "component" => comp,
        "filter" => filter, "initV" => initV, "initD" => initD,
        "yunit" => dunit,
    )
    return TimeSeries(t, a, aMeta), TimeSeries(t, v, vMeta), TimeSeries(t, d, dMeta)
end
