% ESTUDO_PARAMETROS  Varre um parametro por vez (10 execucoes cada) para
% discutir o efeito dos parametros do AG no relatorio.
clear; clc; close all;

base = struct('pop',60, 'geracoes',100, 'pc',0.8, 'pm',0.15, ...
              'elitismo',2, 'lambda',0.10, 'graficos',false);
n_exec = 10;

estudos = { ...
    'pop',      [10 30 60 120]; ...
    'geracoes', [10 30 100 300]; ...
    'pc',       [0.0 0.5 0.8 0.95]; ...
    'pm',       [0.0 0.02 0.15 0.40]; ...
    'elitismo', [0 2 6 12]; ...
    'lambda',   [0 0.05 0.10 0.30]};

linhas = {};
for e = 1:size(estudos,1)
    nome = estudos{e,1};  valores = estudos{e,2};
    for v = valores
        cfg = base;  cfg.(nome) = v;
        f = zeros(n_exec,1); pc_ = f; na = f;
        for k = 1:n_exec
            cfg.semente = k;
            r = ga_antenas(cfg);
            f(k) = r.fitness; pc_(k) = r.percentual; na(k) = r.n_antenas;
        end
        fprintf('%-9s = %-6g | fitness %.4f +- %.4f | cobertura %.2f%% | antenas %.2f\n', ...
            nome, v, mean(f), std(f), mean(pc_), mean(na));
        linhas(end+1,:) = {nome, v, mean(f), std(f), mean(pc_), mean(na)}; %#ok<SAGROW>
    end
end
T = cell2table(linhas, 'VariableNames', ...
    {'Parametro','Valor','Fitness_medio','Fitness_desvio','Cobertura_media_pct','Antenas_media'});
writetable(T, 'estudo_parametros.csv');
disp(T);
