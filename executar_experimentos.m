% EXECUTAR_EXPERIMENTOS  Executa o AG varias vezes (sementes diferentes),
% faz a analise estatistica e apresenta a melhor solucao encontrada.
clear; clc; close all;

n_exec = 10;                          % minimo exigido: 10 execucoes
cfg = struct('pop',60, 'geracoes',100, 'pc',0.8, 'pm',0.15, ...
             'elitismo',2, 'graficos',false);

fit = zeros(n_exec,1); area = fit; perc = fit; nant = fit;
res = cell(n_exec,1);
figure('Name','Convergencia das execucoes'); hold on;
for k = 1:n_exec
    cfg.semente = k;
    res{k} = ga_antenas(cfg);
    fit(k)  = res{k}.fitness;
    area(k) = res{k}.area;
    perc(k) = res{k}.percentual;
    nant(k) = res{k}.n_antenas;
    plot(res{k}.hist.melhor, 'LineWidth', 1);
    fprintf('Execucao %2d | antenas=%d | area=%8.4f km2 | cobertura=%6.2f%% | fitness=%.4f\n', ...
        k, nant(k), area(k), perc(k), fit(k));
end
hold off; grid on; xlabel('Geracao'); ylabel('Melhor fitness');
title(sprintf('Convergencia das %d execucoes', n_exec));

% ---- estatisticas ----
T = table((1:n_exec)', nant, area, perc, fit, ...
    'VariableNames', {'Execucao','Antenas','Area_km2','Cobertura_pct','Fitness'});
writetable(T, 'resultados_execucoes.csv');
fprintf('\n%-14s %10s %10s %10s %10s\n', '', 'media', 'desvio', 'minimo', 'maximo');
nomes = {'Fitness','Area (km2)','Cobertura (%)','Antenas'};
dados = [fit area perc nant];
for j = 1:4
    d = dados(:,j);
    fprintf('%-14s %10.4f %10.4f %10.4f %10.4f\n', nomes{j}, mean(d), std(d), min(d), max(d));
end

% ---- melhor solucao ----
[~, ib] = max(fit);
b = res{ib};
fprintf('\n===== MELHOR SOLUCAO (execucao %d) =====\n', ib);
fprintf('Antenas usadas : %d\n', b.n_antenas);
for i = 1:size(b.posicoes,1)
    fprintf('  Antena %d: (x = %.4f km, y = %.4f km)\n', i, b.posicoes(i,1), b.posicoes(i,2));
end
fprintf('Area coberta   : %.4f km2 de %.0f km2\n', b.area, b.params.area_regiao);
fprintf('Cobertura      : %.2f %%\n', b.percentual);
fprintf('Fitness        : %.4f\n', b.fitness);

% ---- graficos da melhor execucao (reexecuta com a mesma semente) ----
cfg.semente = ib; cfg.graficos = true;
ga_antenas(cfg);
