# Algoritmo Genético para Posicionamento de Antenas (MATLAB)

Atividade Externa da Disciplina (AED) – Atividades de Extensão.

Otimiza o posicionamento de até 5 antenas (raio de 10 km) em uma região quadrada de 200 km²,
maximizando a área coberta e minimizando o número de antenas.

## Como executar

| Arquivo | Função |
|---|---|
| `ga_antenas.m` | O algoritmo genético (uma execução, com gráficos). |
| `executar_experimentos.m` | 10 execuções, estatísticas, melhor solução e gráficos. Gera `resultados_execucoes.csv`. |
| `estudo_parametros.m` | Varre população, gerações, cruzamento, mutação, elitismo e λ. Gera `estudo_parametros.csv`. |

```matlab
r = ga_antenas();                                   % parâmetros padrão
r = ga_antenas(struct('pop',100,'geracoes',200,'pc',0.9,'pm',0.1));
r = ga_antenas(struct('animar',true));              % mostra a evolução (bom para o vídeo)
executar_experimentos                               % análise com 10 execuções
```

Parâmetros configuráveis (campos da struct): `pop`, `geracoes`, `pc`, `pm`, `pm_flag`, `sigma`,
`elitismo`, `k_torneio`, `alpha`, `w_cob`, `lambda`, `n_max`, `raio`, `area_regiao`,
`res_grade`, `semente`, `graficos`, `animar`.

## Modelagem

- **Região:** quadrado de lado L = √200 ≈ 14,142 km, em [0, L] × [0, L].
- **Indivíduo:** vetor `[x1..x5 | y1..y5 | a1..a5]`. `x, y` são reais em [0, L] (a antena nunca sai da região: há *clamp* após cruzamento e mutação). `a` ∈ {0,1} indica se a antena está ativa. Assim o AG decide também *quantas* antenas usar. Indivíduos sem antena ativa são reparados.
- **Área coberta:** união dos discos ativos restrita à região, calculada por integração numérica em grade (centros de células de mesma área). Sobreposições são contadas uma única vez e a parte do disco fora do quadrado é descartada. Durante o AG usa-se grade 150×150; o resultado final é reavaliado em grade 1000×1000.
- **Fitness:**

  `f = w_cob · (A_coberta / A_região) − λ · (n_ativas / n_max)`

  Com `w_cob = 1` e `λ = 0,10`, cada antena custa 0,02 de fração de cobertura (2 % da região). Uma antena extra só compensa se cobrir mais de 2 % da região que ainda estava descoberta. A cobertura domina (λ pequeno), mas o AG é induzido a eliminar antenas redundantes. Os dois termos estão normalizados em [0,1], o que facilita interpretar λ.
- **Seleção:** torneio (k = 3). **Cruzamento:** BLX-α (α = 0,3) nas coordenadas e uniforme nos genes de ativação, aplicado com probabilidade `pc`. **Mutação:** gaussiana nas coordenadas (σ = 10 % de L) com probabilidade `pm` por gene e *bit-flip* nos genes de ativação. **Elitismo:** os `elitismo` melhores passam intactos para a próxima geração.

## Observação importante para o relatório

O centro do quadrado está a exatamente L/√2 = √200/√2 = 10 km de cada vértice, ou seja, **uma única antena no centro (7,071; 7,071) cobre 100 % da região** (os vértices ficam no limite do raio). O ótimo esperado é, portanto, 1 antena com ~100 % de cobertura, e o AG deve chegar até esse resultado. Vale discutir isso no relatório e mostrar que o algoritmo o redescobre sozinho.

Para um cenário em que o compromisso cobertura × número de antenas apareça de fato, rode, por exemplo:

```matlab
ga_antenas(struct('area_regiao',800))    % lado ~28,3 km: exige várias antenas
```

## Roteiro sugerido do relatório

1. Descrição do problema e modelagem (seções acima).
2. Justificativa dos parâmetros do fitness (`w_cob`, `λ`).
3. Resultados das 10 execuções (`resultados_execucoes.csv`): média, desvio, mínimo, máximo.
4. Melhor solução: posições, nº de antenas, área, percentual, fitness (impresso por `executar_experimentos`).
5. Efeito dos parâmetros (`estudo_parametros.csv`): população pequena × grande, poucas × muitas gerações, `pc` e `pm` baixos/altos, elitismo 0 × alto (perda de diversidade), `λ` (0 → usa todas as antenas; alto → sacrifica cobertura).
6. Conclusões e limitações (discretização da grade, cenário com ótimo trivial).

## Entrega

- Código no GitHub (estes arquivos + `.csv` e figuras gerados).
- Vídeo de 3 a 5 min mostrando o AG rodando (`animar = true`), a melhor solução e a análise estatística.
