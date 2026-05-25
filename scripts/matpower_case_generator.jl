using Dates
using Random
using Printf

base_case = joinpath(@__DIR__, "..", "cases", "case14.m")
output_dir = joinpath(@__DIR__, "..", "data", "generated_cases")
interval_seconds = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 300
count = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 0
sigma = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 0.01
meter_bus_id = 6
rng = MersenneTwister(42)

format_number(value) = replace(replace(@sprintf("%.6f", round(Float64(value); digits = 6)), r"0+$" => ""), r"\.$" => "")

function perturb_bus_block(case_text::String)
    parts = split(case_text, "mpc.bus = ["; limit = 2)
    length(parts) == 2 || error("Could not find mpc.bus block")

    tail = split(parts[2], "];"; limit = 2)
    length(tail) == 2 || error("Could not find end of mpc.bus block")

    new_lines = String[]
    for line in split(tail[1], '\n'; keepempty = true)
        row = strip(line)
        if endswith(row, ";")
            cols = split(replace(row, ";" => ""))
            if length(cols) >= 13
                bus_id = parse(Int, cols[1])
                load_scale = clamp(1 + randn(rng) * sigma, 0.92, 1.08)
                if bus_id == meter_bus_id
                    load_scale = clamp(load_scale + randn(rng) * (sigma * 0.5), 0.9, 1.12)
                end
                pd = parse(Float64, cols[3])
                qd = parse(Float64, cols[4])
                if pd != 0.0
                    cols[3] = format_number(pd * load_scale)
                end
                if qd != 0.0
                    cols[4] = format_number(qd * load_scale)
                end
                line = join(cols, '\t') * ";"
            end
        end
        push!(new_lines, line)
    end

    return parts[1] * "mpc.bus = [\n" * join(new_lines, "\n") * "\n];" * tail[2]
end

mkpath(output_dir)
case_text = read(base_case, String)

println("Generating synthetic cases from $(base_case)")
println("Writing to $(output_dir) every $(interval_seconds) seconds")

i = 1
while count == 0 || i <= count
    mutated = perturb_bus_block(case_text)
    stamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    file_name = "case14_synthetic_$(stamp)_$(lpad(string(i), 4, '0')).m"
    file_path = joinpath(output_dir, file_name)

    open(file_path, "w") do io
        write(io, mutated)
    end

    println("Wrote $(file_path)")

    i += 1
    if count == 0 || i <= count
        sleep(interval_seconds)
    end
end