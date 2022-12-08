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
    headRows = 5
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
    TimeSeries(t, y, meta)
end
