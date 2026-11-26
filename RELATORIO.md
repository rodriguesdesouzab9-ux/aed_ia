# Relatório AED – Algoritmo Genético para Posicionamento de Antenas

&#32;

&#32;· Integrantes: Beatriz Vitória Rodrigues de Souza e Elizabeth Manuela Silva Lima

&#32;· Disciplina: Inteligência Artificial

&#32;· Professor: Victor Lima Queiroz

Um Algoritmo Genético em MATLAB posiciona até 5 antenas de raio 10 km numa região de 200 km². Nas 10 execuções feitas, o AG convergiu sempre para 1 antena no centro da região, com cobertura de cerca de 100 % e fitness 0,9800.

## 1. Problema e objetivo

O AG deve encontrar a configuração de antenas que maximize a área coberta da região e, ao mesmo tempo, minimize o número de antenas usadas. As restrições:

- A região é um quadrado de 200 km² no primeiro quadrante, com eixos em km.
- Cada antena tem sinal circular de diâmetro 20 km (raio de 10 km).
- São permitidas no máximo 5 antenas, todas dentro da região.
- A cobertura conta só a área dentro da região e desconta as sobreposições entre antenas.

O lado da região é L = √200 ≈ 14,142 km, e a distância do centro a cada vértice é L/√2 = 10 km. Uma única antena no centro (7,071; 7,071) cobre, portanto, 100 % da região, e o ótimo esperado é 1 antena. O AG precisa redescobrir isso sozinho.&#32;

## 2. Modelagem

**Região.** Quadrado \[0, L\] × \[0, L\] com L = √200 ≈ 14,142 km, no primeiro quadrante.

**Indivíduo.** Um vetor de 15 genes, `[x1..x5 | y1..y5 | a1..a5]`:

- `x` e `y` são reais em \[0, L\] e dão a posição de cada antena.
- `a` é binário e indica se a antena está ativa (1) ou não usada (0). Assim o próprio AG decide quantas antenas usar, e o número de antenas entra na otimização.
- Antenas inativas não cobrem nada e não contam no fitness. Se um indivíduo fica sem nenhuma antena ativa, uma é ativada ao acaso (reparo).

**Exemplo real.** Melhor indivíduo da execução com a semente 1 (`ga_antenas` com parâmetros padrão):

```text
x = [11.9479  11.3622   7.0814   1.8571   7.8812]
y = [ 6.9564   0.5221   7.0141   7.7566   7.1408]
a = [ 0        0        1        0        0     ]
```

Só a antena 3 está ativa (a3 = 1), em (7,0814; 7,0141) km, perto do centro. Os genes das outras quatro ficam no cromossomo, mas não entram na cobertura nem no fitness. Essa solução tem 1 antena, área de 199,9968 km² e fitness 0,9800.

**Antenas dentro da região.** Após o cruzamento e a mutação, as coordenadas são limitadas a \[0, L\] (saturadas nas bordas). Nenhum indivíduo é avaliado com antena fora da região.

**Área coberta.** Calculada por integração numérica numa grade de pontos:

1. A região é dividida em células quadradas iguais, e o centro de cada célula é um ponto de teste.
2. Um ponto está coberto se a distância até o centro de pelo menos uma antena ativa for no máximo 10 km.
3. Área coberta = (pontos cobertos / total de pontos) × 200 km².

Como a grade só existe dentro do quadrado, a parte dos círculos que sai da região é descartada. Como cada ponto conta uma vez, mesmo coberto por várias antenas, as sobreposições são descontadas. Durante a evolução usa-se uma grade de 150 × 150 pontos (22.500 pontos). O resultado final é recalculado numa grade de 1000 × 1000, e nos testes a área da solução ótima ficou entre 199,9946 e 199,9998 km², ou seja, com erro abaixo de 0,01 km².

## 3. Função de fitness

O fitness combina cobertura e número de antenas, ambos normalizados entre 0 e 1:

```latex
f = w_{cob}\,\frac{A_{cob}}{A_{reg}} \;-\; \lambda\,\frac{n_{ativas}}{n_{max}}
```

Com `w_cob = 1`, `λ = 0,10` e `n_max = 5`, cada antena ativa custa λ/n\_max = 0,02, isto é, 2 % da região (4 km² dos 200 km²). Justificativa das escolhas:

- **Cobertura domina.** O enunciado pede, antes de tudo, maximizar a área coberta. Com λ pequeno, nenhuma antena deixa de ser usada se for necessária para cobrir a região.
- **Antena redundante não é utilizada****.** Uma antena extra só compensa se acrescentar mais de 2 % de área que ainda não estava coberta. Antenas sobrepostas ou fora de uso reduzem o fitness, o que empurra o AG a eliminar redundância.
- **Normalização.** Os dois termos estão em \[0, 1\], então λ tem leitura direta: é a fração da região que uma antena precisa cobrir para valer o custo.
- **Valor de λ.** Com λ = 0 não há custo por antena e o AG não tem motivo para reduzir o número delas (ver seção 7). Com λ alto (0,30), cada antena custaria 6 % da região e o fitness cai muito sem ganhar cobertura. O valor 0,10 fica entre os dois extremos.

O fitness máximo possível na região de 200 km² é 1 − 0,02 = 0,98, alcançado por 1 antena com 100 % de cobertura.

## 4. Implementação em MATLAB

O código está em três arquivos:

| Arquivo | Função |
| --- | --- |
| `ga_antenas.m` | O algoritmo genético (uma execução), com os gráficos |
| `executar_experimentos.m` | 10 execuções com sementes diferentes, estatísticas, melhor solução e `resultados_execucoes.csv` |
| `estudo_parametros.m` | Varia um parâmetro por vez (10 execuções cada) e gera `estudo_parametros.csv` |

**Ciclo do AG.** Em cada geração a população é avaliada e ordenada pelo fitness, e a próxima população é formada por:

1. **Elitismo:** os melhores indivíduos (2 por padrão) passam intactos.
2. **Seleção por torneio:** para cada pai, sorteiam-se k = 3 indivíduos e vence o de maior fitness. Mantém pressão seletiva moderada e não exige ordenar nem escalar o fitness.
3. **Cruzamento** (probabilidade `pc`): BLX-α com α = 0,3 nas coordenadas, em que o filho é sorteado num intervalo um pouco maior que o dos pais e pode, portanto, explorar posições entre e além deles. Nos genes de ativação usa-se cruzamento uniforme, que troca cada gene entre os pais com probabilidade 0,5.
4. **Mutação:** ruído gaussiano nas coordenadas (probabilidade `pm` por gene, desvio de 10 % do lado L) e inversão de bit nos genes de ativação (probabilidade `pm_flag`).
5. **Reparo:** garante ao menos 1 antena ativa e mantém as coordenadas em \[0, L\].

**Parâmetros configuráveis.** Todos são campos de uma `struct` passada a `ga_antenas`, por exemplo `ga_antenas(struct('pop',100,'geracoes',200,'pc',0.9))`:

| Parâmetro | Padrão | Significado |
| --- | --- | --- |
| `pop` | 60 | Tamanho da população |
| `geracoes` | 100 | Número de gerações |
| `pc` | 0,80 | Taxa de cruzamento |
| `pm` | 0,15 | Taxa de mutação por coordenada |
| `pm_flag` | 0,10 | Taxa de mutação por gene de ativação |
| `sigma` | 0,10 | Desvio da mutação gaussiana (fração de L) |
| `elitismo` | 2 | Indivíduos preservados por geração |
| `k_torneio` | 3 | Tamanho do torneio |
| `alpha` | 0,30 | Parâmetro do BLX-α |
| `w_cob`, `lambda` | 1,0 e 0,10 | Pesos do fitness |
| `area_regiao`, `raio`, `n_max` | 200, 10, 5 | Região (km²), raio (km) e máximo de antenas |
| `res_grade` | 150 | Resolução da grade durante o AG |
| `semente` | 1 | Semente do gerador aleatório (reprodutibilidade) |

**Gráficos.** O programa mostra a região com as antenas e suas áreas de cobertura, a evolução do fitness (melhor e médio) por geração e a área coberta e o número de antenas do melhor indivíduo por geração. Com `animar = true`, a melhor solução é redesenhada a cada geração.

## 5. Resultados das 10 execuções

O AG foi executado 10 vezes com os parâmetros padrão (população 60, 100 gerações, `pc` 0,80, `pm` 0,15, elitismo 2, λ 0,10) e sementes 1 a 10. Todas as execuções terminaram com 1 antena e cobertura próxima de 100 %.

| Execução | Antenas | Área coberta (km²) | Cobertura (%) | Fitness |
| --- | --- | --- | --- | --- |
| 1 | 1 | 199,9968 | 99,9984 | 0,9800 |
| 2 | 1 | 200,0000 | 100,0000 | 0,9800 |
| 3 | 1 | 199,9980 | 99,9990 | 0,9800 |
| 4 | 1 | 199,9974 | 99,9987 | 0,9800 |
| 5 | 1 | 199,9998 | 99,9999 | 0,9800 |
| 6 | 1 | 199,9928 | 99,9964 | 0,9800 |
| 7 | 1 | 199,9968 | 99,9984 | 0,9800 |
| 8 | 1 | 199,9992 | 99,9996 | 0,9800 |
| 9 | 1 | 199,9938 | 99,9969 | 0,9800 |
| 10 | 1 | 199,9970 | 99,9985 | 0,9800 |

Estatísticas das 10 execuções (desvio padrão amostral):

| Métrica | Média | Desvio | Mínimo | Máximo |
| --- | --- | --- | --- | --- |
| Fitness | 0,9800 | 0,0000 | 0,9800 | 0,9800 |
| Área (km²) | 199,9972 | 0,0024 | 199,9928 | 200,0000 |
| Cobertura (%) | 99,9986 | 0,0012 | 99,9964 | 100,0000 |
| Antenas | 1 | 0 | 1 | 1 |

Todas as execuções terminaram com 1 antena e fitness 0,9800. A área variou só de 199,9928 a 200,0000 km² (desvio de 0,0024 km², ou 0,001 % da região), diferença que vem da posição exata da antena em torno do centro e da discretização da grade, não da quantidade de antenas. O AG é, portanto, robusto a sementes diferentes neste problema. A execução 1 coincide com a execução única de `ga_antenas` com parâmetros padrão (semente 1), que deu área de 199,9968 km².

A cobertura com quatro casas decimais é a área dividida por 200. A saída do MATLAB mostra 100,00 % em todas as execuções porque arredonda para duas casas.

## 6. Melhor solução encontrada

A melhor solução veio da execução 2. Todas as execuções empataram em 0,9800 na precisão impressa, e o script escolhe a de maior fitness em precisão total, que também é a de maior área:

| Item | Valor |
| --- | --- |
| Execução | 2 (semente 2) |
| Antenas usadas | 1 |
| Posição da antena | x = 7,0616 km, y = 7,0737 km |
| Área coberta | 200,0000 km² (de 200 km²) |
| Percentual de cobertura | 100,00 % |
| Fitness | 0,9800 |

A antena ficou a cerca de 10 m do centro geométrico da região (7,0711; 7,0711), que é o ponto ótimo teórico. O fitness 0,9800 é o máximo possível neste modelo (cobertura total com 1 antena: 1 − 0,02).

O valor “200,0000 km²” vem da grade. A distância da antena ao vértice (14,142; 0) é 10,009 km, então sobra uma faixa de cerca de 0,0001 km² sem cobertura, menor que a área de uma célula da grade final (0,0002 km²). Na precisão reportada, a cobertura é total.

## 7. Efeito dos parâmetros do AG

Para medir o efeito de cada parâmetro, `estudo_parametros.m` varia um parâmetro por vez, mantendo os outros no padrão, e roda 10 execuções (sementes 1 a 10) por valor. A tabela abaixo é a saída do MATLAB para a região do enunciado (200 km²).

| Parâmetro | Valor | Fitness médio | Desvio (×10⁻⁵) | Cobertura média (%) | Antenas (média) |
| --- | --- | --- | --- | --- | --- |
| `pop` | 10 | 0,97998 | 2,35 | 99,998 | 1 |
| `pop` | 30 | 0,97998 | 1,14 | 99,998 | 1 |
| `pop` | 60 | 0,97999 | 1,18 | 99,999 | 1 |
| `pop` | 120 | 0,97998 | 1,12 | 99,998 | 1 |
| `geracoes` | 10 | 0,97979 | 21,94 | 99,979 | 1 |
| `geracoes` | 30 | 0,97999 | 1,18 | 99,999 | 1 |
| `geracoes` | 100 | 0,97999 | 1,18 | 99,999 | 1 |
| `geracoes` | 300 | 0,97999 | 1,18 | 99,999 | 1 |
| `pc` | 0 | 0,97998 | 0,73 | 99,998 | 1 |
| `pc` | 0,5 | 0,97998 | 0,87 | 99,998 | 1 |
| `pc` | 0,8 | 0,97999 | 1,18 | 99,999 | 1 |
| `pc` | 0,95 | 0,97999 | 0,94 | 99,999 | 1 |
| `pm` | 0 | 0,97999 | 0,86 | 99,999 | 1 |
| `pm` | 0,02 | 0,97998 | 1,00 | 99,998 | 1 |
| `pm` | 0,15 | 0,97999 | 1,18 | 99,999 | 1 |
| `pm` | 0,4 | 0,97999 | 0,93 | 99,999 | 1 |
| `elitismo` | 0 | 0,97999 | 1,00 | 99,999 | 1 |
| `elitismo` | 2 | 0,97999 | 1,18 | 99,999 | 1 |
| `elitismo` | 6 | 0,97998 | 0,88 | 99,998 | 1 |
| `elitismo` | 12 | 0,97999 | 0,90 | 99,999 | 1 |
| `lambda` | 0 | 1,00000 | 0,00 | 100,000 | 3,4 |
| `lambda` | 0,05 | 0,98998 | 1,09 | 99,998 | 1 |
| `lambda` | 0,1 | 0,97999 | 1,18 | 99,999 | 1 |
| `lambda` | 0,3 | 0,93999 | 0,91 | 99,999 | 1 |

**Leitura para 200 km²:**

- **Quase nada muda.** Em todas as linhas, o fitness médio fica a menos de 3×10⁻⁵ do máximo possível para aquele λ. A única exceção é `geracoes = 10`: fitness 0,97979, cobertura de 99,979 % e desvio dez vezes maior que o das outras linhas. Diferenças de 10⁻⁵ no fitness correspondem a cerca de 0,002 km², ruído da própria grade, e por isso não são interpretadas.
- **Por que o efeito é pequeno.** Com 1 antena, a cobertura cresce de forma suave à medida que ela se aproxima do centro, então há um único pico a alcançar. Provavelmente por isso o AG chega lá mesmo sem cruzamento (`pc = 0`), sem mutação (`pm = 0`) ou sem elitismo, pois os outros operadores bastam.
- **Gerações.** Com 10 gerações a busca ainda não refinou a posição. Com 30 já se atinge o mesmo patamar de 100 e 300.
- **λ.** É o único parâmetro que muda o objetivo. Os fitness medidos para λ = 0,05 (0,98998) e λ = 0,3 (0,93999) batem com 1 − λ/5 = 0,99 e 0,94, o que confirma a função de fitness implementada. Com λ = 0 as antenas extras não têm custo, e o AG deixa em média 3,4 delas ativas.

**Cenário de 800 km².** Como o cenário de 200 km² é fácil demais para separar os parâmetros, o estudo foi repetido numa região de 800 km² (lado ≈ 28,3 km), em que são necessárias 4 antenas:

| Parâmetro | Valor | Fitness médio | Desvio (×10⁻⁴) | Cobertura média (%) | Antenas (média) |
| --- | --- | --- | --- | --- | --- |
| `pop` | 10 | 0,91809 | 21,92 | 99,809 | 4 |
| `pop` | 30 | 0,91968 | 1,99 | 99,968 | 4 |
| `pop` | 60 | 0,91977 | 1,46 | 99,977 | 4 |
| `pop` | 120 | 0,91986 | 0,74 | 99,986 | 4 |
| `geracoes` | 10 | 0,88847 | 163,34 | 97,447 | 4,3 |
| `geracoes` | 30 | 0,91887 | 3,94 | 99,887 | 4 |
| `geracoes` | 100 | 0,91977 | 1,46 | 99,977 | 4 |
| `geracoes` | 300 | 0,91989 | 0,68 | 99,989 | 4 |
| `pc` | 0 | 0,91964 | 2,40 | 99,964 | 4 |
| `pc` | 0,5 | 0,91977 | 0,90 | 99,977 | 4 |
| `pc` | 0,8 | 0,91977 | 1,46 | 99,977 | 4 |
| `pc` | 0,95 | 0,91984 | 1,04 | 99,984 | 4 |
| `pm` | 0 | 0,91277 | 118,02 | 99,277 | 4 |
| `pm` | 0,02 | 0,91974 | 1,58 | 99,974 | 4 |
| `pm` | 0,15 | 0,91977 | 1,46 | 99,977 | 4 |
| `pm` | 0,4 | 0,91847 | 6,66 | 99,847 | 4 |
| `elitismo` | 0 | 0,91560 | 31,44 | 99,560 | 4 |
| `elitismo` | 2 | 0,91977 | 1,46 | 99,977 | 4 |
| `elitismo` | 6 | 0,91992 | 0,31 | 99,992 | 4 |
| `elitismo` | 12 | 0,91991 | 0,43 | 99,991 | 4 |
| `lambda` | 0 | 0,99999 | 0,12 | 99,999 | 5 |
| `lambda` | 0,05 | 0,95985 | 0,68 | 99,985 | 4 |
| `lambda` | 0,1 | 0,91977 | 1,46 | 99,977 | 4 |
| `lambda` | 0,3 | 0,75977 | 1,38 | 99,977 | 4 |

O fitness com λ diferente não é comparável entre linhas, pois a escala muda; nesse caso o que se compara é o número de antenas.

**Leitura para 800 km²:**

- **População.** Com 10 indivíduos o fitness cai para 0,91809 e o desvio sobe para 21,9×10⁻⁴ (cobertura de 99,809 %). De 30 a 120 o fitness varia pouco (0,91968 a 0,91986), mas o desvio continua caindo (de 2,0 para 0,7×10⁻⁴): população maior deixa o resultado mais estável. O custo cresce linearmente, pois cada avaliação percorre a grade inteira.
- **Gerações.** Com 10 gerações a busca não termina: fitness de 0,88847, cobertura de 97,447 % e o maior desvio entre as linhas de gerações (0,016). A média de 4,3 antenas indica que parte das execuções ainda mantém uma antena redundante. Com 30 já se chega a 0,91887, e de 100 para 300 o ganho é de apenas 0,0001.
- **Cruzamento.** O efeito é pequeno. Sem cruzamento (`pc = 0`) o fitness é 0,91964, contra 0,91977 a 0,91984 com `pc` de 0,5 a 0,95. A diferença é menor que um desvio padrão, então a mutação gaussiana faz grande parte da busca sozinha.
- **Mutação.** É o parâmetro mais sensível. Sem mutação (`pm = 0`) o fitness cai para 0,91277 e o desvio sobe para 0,0118 (cobertura de 99,277 %): o AG só recombina posições que já existem, e o desvio alto indica que algumas execuções ficam presas em soluções piores. Com `pm` de 0,02 a 0,15 funciona bem, e com 0,4 cai para 0,91847, provável efeito de a mutação alta destruir boas soluções.
- **Elitismo.** Sem elitismo o fitness é 0,91560 com desvio de 0,0031 (cobertura de 99,56 %), pois o melhor indivíduo pode ser perdido por cruzamento ou mutação. Com 2 já estabiliza (0,91977), e 6 e 12 são um pouco melhores e mais estáveis (0,91992 e 0,91991, desvio de 0,3 e 0,4×10⁻⁴ contra 1,5×10⁻⁴). Até 12 indivíduos (20 % da população) não prejudicaram.
- **λ (peso do número de antenas).** É o parâmetro que muda o objetivo. Com λ = 0 o AG usa as 5 antenas, pois mais cobertura nunca custa nada (fitness 0,99999). Com 0,05, 0,1 e 0,3 usa 4. Os fitness medidos batem com cobertura − λ·4/5 (0,95985, 0,91977 e 0,75977). Com λ = 0,3 o custo das antenas já domina o fitness, mas o AG continua com 4 antenas, o que indica que a quarta cobre mais de 6 % da região.

## 8. Conclusões e limitações

- **O AG achou o ótimo.** Nas 10 execuções ele convergiu para 1 antena junto ao centro, com fitness 0,9800 (o máximo do modelo) e área entre 199,9928 e 200,0000 km². Isso coincide com a solução geométrica: o centro está a 10 km de cada vértice.
- **Resultado robusto.** O fitness não variou entre sementes. Só mudaram a posição exata da antena e a área (desvio de 0,0024 km², ou 0,001 % da região). A melhor execução (a 2) ficou a cerca de 10 m do centro.
- **No cenário  proposto****, os parâmetros pouco importam.** Variar população, cruzamento, mutação ou elitismo não alterou o resultado de forma mensurável. A única configuração pior foi a de 10 gerações, que não bastou para refinar a posição.
- **Em 800 km² os parâmetros importam.** O AG usou 4 antenas e cobriu 99,977 % com os parâmetros padrão. Os piores resultados vieram de 10 gerações (fitness 0,88847), mutação nula (0,91277), ausência de elitismo (0,91560) e população de 10 (0,91809). Cruzamento teve efeito pequeno.
- **λ é a decisão de modelagem de maior efeito.** Ele define quantas antenas o AG aceita usar, e os fitness medidos nos dois cenários batem com cobertura − λ·n/5, o que valida a função de fitness.

Limitações:

- A área é calculada numa grade, então tem erro de discretização. Na grade final de 1000 × 1000 ele é menor que 0,01 km², e a grade não avalia exatamente os vértices da região.
- Com 200 km² o ótimo é trivial, então este cenário testa pouco a capacidade do AG; o caso de 800 km² cobre essa lacuna.
- Um AG é uma heurística e não garante o ótimo global. Aqui a conclusão de que se achou o ótimo vem da comparação com a solução geométrica conhecida, o que não existe para o caso de 800 km².
- A análise de parâmetros varia um fator por vez e não capta interações entre eles.
- A área de 200,0000 km² da melhor solução é um arredondamento da grade: restam cerca de 0,0001 km² descobertos perto de um vértice, abaixo da resolução da grade final (0,0002 km² por célula).
