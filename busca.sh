instancias=" E-n101-k14 A-n80-k10 P-n101-k4 B-n78-k10 P-n76-k5 E-n76-k8 M-n101-k10 F-n72-k4 G-n262-k25 B-n31-k5 A-n32-k5"
for instancia in $instancias; do
  echo $instancia
  for i in {1..5}; do
      docker run -d -v ${PWD}:/otc julia julia busca_tabu.jl "resultados/busca_tabu/${instancia}_${i}.log" "instancias/${instancia}.vrp"
  done
done
