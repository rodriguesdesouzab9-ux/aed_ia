function resultado = ga_antenas(params)
% GA_ANTENAS  Algoritmo Genetico para posicionamento de antenas.
%
%   resultado = ga_antenas()            -> usa parametros padrao
%   resultado = ga_antenas(struct('pop',100,'geracoes',200))
%
% Modelagem
%   Regiao : quadrado de area 'area_regiao' km^2 (lado L = sqrt(area)), no
%            primeiro quadrante: [0,L] x [0,L].
%   Antena : sinal circular de raio 'raio' km (diametro 20 km).
%   Individuo (vetor linha com 3*n_max genes):
%            [x1..xM | y1..yM | a1..aM]
%            x,y reais em [0,L] (antena sempre dentro da regiao);
%            a em {0,1} indica se a antena esta ativa (usada).
%   Cobertura: area da UNIAO dos discos ativos, restrita a regiao
%            (sobreposicoes contadas uma unica vez). Calculada por
%            integracao numerica em grade de pontos (centros de celulas).
%   Fitness : f = w_cob * (A_coberta / A_regiao) - lambda * (n_ativas / n_max)
%
% Operadores: selecao por torneio, cruzamento BLX-alpha (coordenadas) +
% uniforme (genes de ativacao), mutacao gaussiana + bit-flip, elitismo.

if nargin < 1, params = struct(); end
p = parametros_padrao(params);
rng(p.semente);

M = p.n_max;  N = p.pop;  G = p.geracoes;
[X, Y] = grade(p.L, p.res_grade);

pop = inicializar(p);
hist.melhor = zeros(G,1);  hist.media = zeros(G,1);
hist.area   = zeros(G,1);  hist.n_ant = zeros(G,1);
hist.frac   = zeros(G,1);

hfig = [];
for g = 1:G
    [fit, frac, nat] = avaliar_pop(pop, p, X, Y);
    [fit, ord] = sort(fit, 'descend');
    pop = pop(ord,:);  frac = frac(ord);  nat = nat(ord);

    hist.melhor(g) = fit(1);
    hist.media(g)  = mean(fit);
    hist.frac(g)   = frac(1);
    hist.area(g)   = frac(1) * p.area_regiao;
    hist.n_ant(g)  = nat(1);

    if p.graficos && p.animar && (mod(g, p.passo_animacao) == 0 || g == 1)
        if isempty(hfig) || ~isvalid(hfig), hfig = figure('Name','Evolucao'); end
        figure(hfig); clf;
        plotar_solucao(gca, pop(1,:), p, sprintf('Geracao %d/%d | fitness %.4f | cobertura %.2f%% | %d antenas', ...
            g, G, fit(1), 100*frac(1), nat(1)));
        drawnow;
    end
    if g == G, break; end

    % --- proxima geracao ---
    ne = min(p.elitismo, N);
    elite = pop(1:ne,:);
    nf = N - ne;
    ns = nf + mod(nf,2);                       % numero par de pais
    pais = pop(torneio(fit, p.k_torneio, ns), :);
    filhos = cruzar(pais, p);
    filhos = mutar(filhos, p);
    filhos = reparar(filhos, p);
    pop = [elite; filhos(1:nf,:)];
end

% --- resultado final (area recalculada em grade mais fina) ---
melhor = pop(1,:);
[Xf, Yf] = grade(p.L, p.res_final);
[frac_f, nat_f] = cobertura_ind(melhor, p, Xf, Yf);
ativas = melhor(2*M+1:3*M) > 0.5;
resultado.params      = p;
resultado.melhor      = melhor;
resultado.posicoes    = [melhor(1:M)', melhor(M+1:2*M)'];
resultado.posicoes    = resultado.posicoes(ativas,:);
resultado.n_antenas   = nat_f;
resultado.frac        = frac_f;
resultado.area        = frac_f * p.area_regiao;
resultado.percentual  = 100 * frac_f;
resultado.fitness     = p.w_cob*frac_f - p.lambda*nat_f/M;
resultado.hist        = hist;

if p.graficos
    figure('Name','Melhor solucao');
    plotar_solucao(gca, melhor, p, sprintf('Melhor solucao: %d antenas, %.2f km^2 (%.2f%%), fitness %.4f', ...
        nat_f, resultado.area, resultado.percentual, resultado.fitness));
    figure('Name','Evolucao do AG');
    subplot(1,2,1);
    plot(1:G, hist.melhor, 'b-', 1:G, hist.media, 'r--', 'LineWidth', 1.5);
    grid on; xlabel('Geracao'); ylabel('Fitness'); legend('Melhor','Media','Location','southeast');
    title('Evolucao do fitness');
    subplot(1,2,2);
    yyaxis left;  plot(1:G, hist.area, 'g-', 'LineWidth', 1.5); ylabel('Area coberta (km^2)');
    yyaxis right; stairs(1:G, hist.n_ant, 'k-'); ylabel('Antenas usadas'); ylim([0 M+1]);
    grid on; xlabel('Geracao'); title('Area coberta e antenas (melhor individuo)');
end
end

% =====================================================================
%  Funcoes locais
% =====================================================================
function p = parametros_padrao(u)
p.area_regiao = 200;     % km^2
p.raio        = 10;      % km (diametro 20 km)
p.n_max       = 5;       % maximo de antenas
p.pop         = 60;      % tamanho da populacao
p.geracoes    = 100;
p.pc          = 0.80;    % taxa de cruzamento
p.pm          = 0.15;    % taxa de mutacao por coordenada
p.pm_flag     = 0.10;    % taxa de mutacao (flip) por gene de ativacao
p.sigma       = 0.10;    % desvio da mutacao gaussiana (fracao do lado L)
p.elitismo    = 2;       % individuos preservados por geracao
p.k_torneio   = 3;       % tamanho do torneio
p.alpha       = 0.30;    % parametro do BLX-alpha
p.w_cob       = 1.0;     % peso da cobertura no fitness
p.lambda      = 0.10;    % penalidade por usar TODAS as antenas (cada uma custa lambda/n_max)
p.res_grade   = 150;     % grade (res x res) usada durante o AG
p.res_final   = 1000;    % grade usada para reportar a solucao final
p.semente     = 1;       % semente do gerador aleatorio
p.graficos    = true;
p.animar      = false;   % true: mostra a solucao evoluindo (bom para o video)
p.passo_animacao = 1;
f = fieldnames(u);
for i = 1:numel(f), p.(f{i}) = u.(f{i}); end
p.L = sqrt(p.area_regiao);
end

function [X, Y] = grade(L, n)
gx = ((1:n) - 0.5) / n * L;          % centros das celulas
[X, Y] = meshgrid(gx, gx);
end

function pop = inicializar(p)
M = p.n_max;
pop = [p.L*rand(p.pop, 2*M), double(rand(p.pop, M) < 0.5)];
pop = reparar(pop, p);
end

function pop = reparar(pop, p)
% garante pelo menos 1 antena ativa
M = p.n_max;
sem = find(sum(pop(:,2*M+1:3*M) > 0.5, 2) == 0);
for i = sem'
    pop(i, 2*M + randi(M)) = 1;
end
end

function [frac, nat] = cobertura_ind(ind, p, X, Y)
M = p.n_max;
cob = false(size(X));
nat = 0;
for k = 1:M
    if ind(2*M+k) > 0.5
        nat = nat + 1;
        cob = cob | ((X - ind(k)).^2 + (Y - ind(M+k)).^2 <= p.raio^2 + 1e-9);
    end
end
frac = mean(cob(:));     % celulas tem areas iguais -> fracao da area da regiao
end

function [fit, frac, nat] = avaliar_pop(pop, p, X, Y)
n = size(pop,1);
fit = zeros(n,1); frac = zeros(n,1); nat = zeros(n,1);
for i = 1:n
    [frac(i), nat(i)] = cobertura_ind(pop(i,:), p, X, Y);
    fit(i) = p.w_cob*frac(i) - p.lambda*nat(i)/p.n_max;
end
end

function idx = torneio(fit, k, n)
cand = randi(numel(fit), n, k);
[~, j] = max(fit(cand), [], 2);
idx = cand(sub2ind(size(cand), (1:n)', j));
end

function f = cruzar(pais, p)
M = p.n_max; n = size(pais,1); f = pais;
ic = 1:2*M;  ia = 2*M+1:3*M;
for i = 1:2:n-1
    a = pais(i,:); b = pais(i+1,:);
    if rand < p.pc
        lo = min(a(ic), b(ic));  d = abs(a(ic) - b(ic));
        f(i,  ic) = lo - p.alpha*d + rand(1,2*M).*(1+2*p.alpha).*d;
        f(i+1,ic) = lo - p.alpha*d + rand(1,2*M).*(1+2*p.alpha).*d;
        m = rand(1,M) < 0.5;
        f(i,  ia) = a(ia).*m + b(ia).*~m;
        f(i+1,ia) = b(ia).*m + a(ia).*~m;
    end
end
f(:,ic) = min(max(f(:,ic), 0), p.L);
end

function f = mutar(f, p)
M = p.n_max; n = size(f,1);
ic = 1:2*M;  ia = 2*M+1:3*M;
mask = rand(n, 2*M) < p.pm;
f(:,ic) = f(:,ic) + mask .* randn(n, 2*M) * p.sigma * p.L;
f(:,ic) = min(max(f(:,ic), 0), p.L);            % antenas dentro da regiao
flip = rand(n, M) < p.pm_flag;
f(:,ia) = double(xor(f(:,ia) > 0.5, flip));
end

function plotar_solucao(ax, ind, p, titulo)
M = p.n_max;  L = p.L;  R = p.raio;
[X, Y] = grade(L, 300);
cob = false(size(X));
cla(ax); hold(ax, 'on');
for k = 1:M
    if ind(2*M+k) > 0.5
        cob = cob | ((X-ind(k)).^2 + (Y-ind(M+k)).^2 <= R^2 + 1e-9);
    end
end
gx = X(1,:);
imagesc(ax, gx, gx, double(cob));
colormap(ax, [1 1 1; 0.65 0.85 1]);
for k = 1:M
    if ind(2*M+k) > 0.5
        rectangle(ax, 'Position', [ind(k)-R, ind(M+k)-R, 2*R, 2*R], ...
            'Curvature', [1 1], 'EdgeColor', [0.1 0.3 0.8], 'LineWidth', 1.2);
        plot(ax, ind(k), ind(M+k), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
        text(ax, ind(k), ind(M+k), sprintf('  A%d', k), 'Color', 'r');
    end
end
rectangle(ax, 'Position', [0 0 L L], 'EdgeColor', 'k', 'LineWidth', 2);
set(ax, 'YDir', 'normal'); axis(ax, 'equal');
axis(ax, [-R, L+R, -R, L+R]); grid(ax, 'on'); box(ax, 'on');
xlabel(ax, 'x (km)'); ylabel(ax, 'y (km)'); title(ax, titulo);
hold(ax, 'off');
end
