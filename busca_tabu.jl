using Formatting: printfmt
import Random
#Random.seed!(1234)

function parse_file(file)
    instancia = open(file)
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

function get_solucao_inicial(k)
    solucao_inicial = [1]
    vertices_nao_visitados = collect(2:k)
    return solucao_inicial, vertices_nao_visitados
end

function get_tabela_tabu_inicial(k) 
    return zeros(Int32, (2, k, k))
end

function pop_at(array, index)
    valor = array[index]
    deleteat!(array, index)
    return array, valor
end

function get_um_vizinho_a_direita(solucao, vertices_nao_visitados)
    direcao = 2
    
    # copias de seguranca
    vizinho = copy(solucao)
    copia_vertices_nao_visitados = copy(vertices_nao_visitados)
    
    # escolhe um vertice para colocar no caminho
    indice = rand(1:length(copia_vertices_nao_visitados))
    vertice_adicionado = copia_vertices_nao_visitados[indice]
    
    # deleta o vertice do array de vertices nao visitados
    deleteat!(copia_vertices_nao_visitados, indice)
    
    # escolhe um ponto de insercao do vertice na solucao
    indice_de_inclusao = rand(2:length(solucao)+1)
    
    # insere o vertice na solucao
    insert!(vizinho, indice_de_inclusao, vertice_adicionado)
    
    # calcula o custo associado a esse vizinho
    custo = get_custo(vizinho)
    
    # retorna vizinho, vertices nao visitados, tripla da tabela tabu
    return vizinho, custo, copia_vertices_nao_visitados, (direcao, vertice_adicionado, indice_de_inclusao)
end
    

# solucao deve ser uma lista de tamanho maior que 1
function get_um_vizinho_a_esquerda(solucao, vertices_nao_visitados) # solucao deve ser uma lista de tamanho maior que 1
    direcao = 1
    # copias de seguranca
    vizinho = copy(solucao)
    copia_vertices_nao_visitados = copy(vertices_nao_visitados)
    
    if length(solucao) == 1
        return vizinho, 0, copia_vertices_nao_visitados, (direcao, 1, 1)
        
    else
        # escolhe o indice do vertice no caminho para ser removido
        indice_de_exclusao = rand(2:length(solucao))

        # remove o vertice escolhido
        vizinho, vertice_deletado = pop_at(vizinho, indice_de_exclusao)

        # insere o vertice removido do caminho na array de vertices nao visitados
        push!(copia_vertices_nao_visitados, vertice_deletado);

        # calcula o custo associado a esse vizinho
        custo = get_custo(vizinho)
        
        # retorna vizinho, vertices nao visitados, tripla da tabela tabu
        return vizinho, custo, copia_vertices_nao_visitados, (direcao, vertice_deletado, 1)
    end
end

# function get_vizinhos(solucao, vertices_nao_visitados)
#     vizinhos = []
#     for i in 1:trunc(Int32, sqrt(length(solucao)))
#         vizinho = get_um_vizinho_a_esquerda(solucao, vertices_nao_visitados)
#         if vizinho[1] != [1]
#             push!(vizinhos, vizinho)
#         end
#     end
#     for i in 1:trunc(Int32, length(vertices_nao_visitados) * 0.7)
#         vizinho = get_um_vizinho_a_direita(solucao, vertices_nao_visitados)
#         push!(vizinhos, vizinho)
#     end
#     return vizinhos
#end

function get_custo(caminho) # D e P sao variaveis globais definidas na celula abaixo
    custo = 0
    for i in 1:length(caminho)-1
        saida = caminho[i]
        entrada = caminho[i+1]
        custo += D[saida, entrada] - P[entrada]
    end
    saida = last(caminho)
    entrada = 1
    custo += D[saida, entrada] - P[entrada] 
end

function movimento_eh_tabu(tabela_tabu, movimento, iteracao)
    direcao, vertice, indice = movimento
    return tabela_tabu[direcao, vertice, indice] > iteracao
end

function insere_movimento_na_tabela_tabu(tabela_tabu, movimento, iteracao)
    direcao, vertice, indice = movimento
    tamanho_tabu = trunc(Int32, sqrt(size(tabela_tabu)[2]))
    tabela_tabu[direcao, vertice, indice] = iteracao + tamanho_tabu
    return tabela_tabu
end      

#println(ARGS)
arquivo_saida =  ARGS[1]
arquivo_entrada = ARGS[2]
#println(arquivo_saida)
#println(arquivo_entrada)
v, P = parse_file(arquivo_entrada)
D = get_distancias(v)
k = length(P);
D = D[1:k, 1:k]
P = P[1:k];

solucao, vertices_nao_visitados  = get_solucao_inicial(k);
tabela_tabu = get_tabela_tabu_inicial(k);

menor_custo_global = 9999999
melhor_vizinho_global = nothing
for iteracao in 1:k*500
    menor_custo_local = 9999999
    melhor_vizinho_local = nothing    
    for i in 1:trunc(Int32, sqrt(length(solucao)))
        vizinho = get_um_vizinho_a_esquerda(solucao, vertices_nao_visitados)
        if vizinho[1] != [1]
            if vizinho[2] < menor_custo_local && !(movimento_eh_tabu(tabela_tabu, vizinho[4], iteracao))
                menor_custo_local = vizinho[2]
                melhor_vizinho_local = vizinho
            end
            global menor_custo_global
            if  vizinho[2] < menor_custo_global
                menor_custo_local = vizinho[2]
                melhor_vizinho_local = vizinho
                global menor_custo_global = vizinho[2]
                global melhor_vizinho_global = vizinho
            end
        end
    end   
    
    for i in 1:trunc(Int32, length(vertices_nao_visitados) * 0.7)
        vizinho = get_um_vizinho_a_direita(solucao, vertices_nao_visitados)
        if vizinho[2] < menor_custo_local && !(movimento_eh_tabu(tabela_tabu, vizinho[4], iteracao))
            menor_custo_local = vizinho[2]
            melhor_vizinho_local = vizinho
        end
        global menor_custo_global
        if  vizinho[2] < menor_custo_global
            menor_custo_local = vizinho[2]
            melhor_vizinho_local = vizinho
            global menor_custo_global = vizinho[2]
            global melhor_vizinho_global = vizinho
            #printfmt("$iteracao, $menor_custo_global\n")
        end
    end
    
    global solucao = melhor_vizinho_local[1]
    global vertices_nao_visitados = melhor_vizinho_local[3]
    global tabela_tabu = insere_movimento_na_tabela_tabu(tabela_tabu, melhor_vizinho_local[4], iteracao)
end

#println(arquivo_saida)
open(arquivo_saida, "w") do file
    println(file, melhor_vizinho_global[2])
    for i in 1:length(melhor_vizinho_global[1])
        println(file, melhor_vizinho_global[1][i])
        end
    println(file, 1)
end


