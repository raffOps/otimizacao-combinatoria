using GLPK
using JuMP

function parse_file(file)
    instancia = open("instancias/"*file)
    arr  = []
    for line in eachline(instancia)
        push!(arr, line)
    end
    close(instancia)
    
    vertices = []
    premios = []
    flag_vertices = true
    for line in arr[8:length(arr)]
        if startswith(line, "DEMAND_SECTION")
            flag_vertices = false
        elseif startswith(line, "DEPOT_SECTION")
            break
        elseif flag_vertices
            x, y = split(line)[2:3]
            x = parse(Int32, x)
            y = parse(Int32, y)
            push!(vertices, (x,y))
        else
            premio = split(line)[2]
            premio = parse(Int32, premio)
            push!(premios, premio)

        end
    end
    return (vertices, premios)
end


function get_distancias(vertices)
    cardinalidade = length(vertices)
    distancias = zeros(cardinalidade, cardinalidade)
    for i in 1:cardinalidade
        for j in 1:cardinalidade
            distancia = ((vertices[i][1] - vertices[j][1])^2 + (vertices[i][2] - vertices[j][2])^2)^(0.5)
            distancias[i, j] =  round(distancia)
        end
    end
    return distancias
end

function otimiza(arquivo)
    v, P = parse_file(arquivo)
    D = get_distancias(v)
    k = length(P);
    #k=6;
    m = Model(GLPK.Optimizer)
    set_time_limit_sec(m, 1800)
    @variable(m, A[1:k, 1:k], Bin)
    @variable(m, V[1:k], Bin);
    @variable(m, u[1:k]);

    @objective(m, Min, sum(D .* A) - sum(P .* V));

    @constraints(m, begin
        #3
        sum(A[i,1] for i=1:k) == 1

        #4
        sum(A[1,j] for j=1:k) == 1

        #5
        [i=1:k], sum(A[i,j] for j=1:k) == V[i] 

        #6
        [i=1:k], sum(A[i,j] for j=1:k) <= 1

        #7
        [j=1:k], sum(A[i,j] for i=1:k) <= 1

        #8
        [i=1:k], A[i,i] == 0

        #9    
        [i=2:k,j=2:k; i!=j], u[i] - u[j] + k*A[i,j] <= k - 1
        [i=2:k], 2 <= u[i]
        [i=2:k], u[i] <= k
        u[1] == 1
        end
    )
    
    optimize!(m)
    @show objective_value(m)
    return m, A
end

# # teste
# for file in readdir("instancias")
#     println(file)
# end

file = ARGS[1]

m, A = otimiza(file);

open("resultados/" *file * ".log", "w") do file
    println(file, objective_value(m))
    for i in 1:size(A)[1]
        if 1.0 in JuMP.value.(A)[1,:]
            println(file, i," ", argmax(JuMP.value.(A)[i,:]))
        end
    end
end


