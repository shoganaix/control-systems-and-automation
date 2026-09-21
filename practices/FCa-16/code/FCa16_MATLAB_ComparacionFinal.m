%% FCa-16 - FIGURAS FINALES (G(t) vs G(f))  [2º ORDEN]
% Este script NO modifica figuras anteriores
clear; close all; clc;

%% 0) Archivo
fileWave = 'FCa-16_Waveform.csv';

%% 1) Cargar datos (escalón)
data = readmatrix(fileWave);
t = data(:,1); 
u = data(:,2); 
y = data(:,3);
t = t(:); u = u(:); y = y(:);

%% 2) Alinear al flanco
du = [0; diff(u)];
[~, i0] = max(abs(du));
t0 = t(i0);
t  = t - t0;

%% 3) Ventana
tmin = -2e-3;
tmax =  10e-3;
m = (t>=tmin) & (t<=tmax);
tt = t(m); uu = u(m); yy = y(m);
tt = tt(:); uu = uu(:); yy = yy(:);

%% 4) Niveles robustos y ganancia K
n = numel(yy);
n10 = max(10, round(0.10*n));

u_pre = median(uu(1:n10));
u_inf = median(uu(end-n10+1:end));
Du = u_inf - u_pre;

y_pre = median(yy(1:n10));
y_inf = median(yy(end-n10+1:end));
Dy = y_inf - y_pre;

K = Dy / Du;

%% 5) Parámetros 2º orden desde escalón: Mp, tp, zeta, wd, wn
post = tt >= 0;
ttp  = tt(post);
ypp  = yy(post);

[ymax, i_pk] = max(ypp);
tp = ttp(i_pk);

Mp = (ymax - y_inf) / (y_inf - y_pre);
if Mp <= 0
    warning('Mp <= 0: no parece subamortiguado o el pico no está bien capturado.');
    Mp = max(Mp, eps);
end

zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2);
wd   = pi / tp;
wn   = wd / sqrt(1 - zeta^2);

% Modelo tiempo: Gt(s)
s = tf('s');
Gt = K * (wn^2) / (s^2 + 2*zeta*wn*s + wn^2);

%% 6) DATOS EXPERIMENTALES de FRECUENCIA
f_exp   = [100 200 600 1000 2000 3000 7000 12000 20000];
Uin_mV  = [279.0 530.4 998.4 986.5 984.3 986.2 986.9 988.0 986.8];
Uout_mV = [278.7 532.2 1024  1067  998.1 1017  343.6 95.95 33.01];

Gexp_dB = 20*log10(Uout_mV ./ Uin_mV);
phi_exp = nan(size(f_exp));

%% 7) Modelo frecuencia: Gf(s) ajustando (Kf, zeta_f, wn_f) a los puntos (módulo)
w_exp = 2*pi*f_exp;

% Función de coste: error en dB entre modelo y puntos
costFun = @(p) cost_second_order_db(p, w_exp, Gexp_dB);

% Parametrización positiva: p = [log(Kf), logit(zeta_f), log(wn_f)]
% zeta en (0,1) con transformación logística
logit = @(x) log(x./(1-x));
sigm  = @(x) 1./(1+exp(-x));

p0 = [log(abs(K)+eps), logit(min(max(zeta,1e-3),0.9)), log(wn)];

opts = optimset('Display','off','MaxIter',4000,'MaxFunEvals',4000);
pOpt = fminsearch(costFun, p0, opts);

Kf     = exp(pOpt(1));
zeta_f = sigm(pOpt(2));
wn_f   = exp(pOpt(3));

Gf = Kf * (wn_f^2) / (s^2 + 2*zeta_f*wn_f*s + wn_f^2);

%% 8) FIGURA FINAL 3.1: ESCALÓN (lab vs Gt vs Gf)
u_step = uu - u_pre;                      
y_Gt = lsim(Gt, u_step, tt) + y_pre;
y_Gf = lsim(Gf, u_step, tt) + y_pre;

figure;
plot(tt, yy, 'LineWidth', 1.5); hold on;
plot(tt, y_Gt, '--', 'LineWidth', 1.5);
plot(tt, y_Gf, ':', 'LineWidth', 1.8);
grid on;
ylim padded
xlabel('Tiempo (s)');
ylabel('Salida (V)');
title('Comparación a Escalón (FCa-16): Laboratorio vs G(t)/G(f)');
legend('Laboratorio (CH2)','Modelo G(t)','Modelo G(f)','Location','best');

%% 9) FIGURA FINAL 3.2 (MÓDULO): Bode (lab vs Gt / Gf)
f_grid = logspace(log10(50), log10(2e5), 800);
w_grid = 2*pi*f_grid;

[mag_t, ph_t] = bode(Gt, w_grid); mag_t = squeeze(mag_t); ph_t = squeeze(ph_t);
[mag_f, ph_f] = bode(Gf, w_grid); mag_f = squeeze(mag_f); ph_f = squeeze(ph_f);

Gt_dB = 20*log10(mag_t);
Gf_dB = 20*log10(mag_f);

figure;
semilogx(f_grid, Gt_dB, 'LineWidth', 1.5); hold on;
semilogx(f_grid, Gf_dB, '--', 'LineWidth', 1.5);
semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
title('Diagrama de Bode - Módulo (FCa-16): Laboratorio vs G(t)/G(f)');
legend('G(t)','G(f)','Experimental','Location','best');

%% 10) FIGURA FINAL 3.2 (FASE): Bode fase (Gt vs Gf, y puntos si existen)
figure;
semilogx(f_grid, ph_t, 'LineWidth', 1.5); hold on;
semilogx(f_grid, ph_f, '--', 'LineWidth', 1.5);

if any(isfinite(phi_exp))
    semilogx(f_exp, phi_exp, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
    legend('G(t)','G(f)','Experimental','Location','best');
else
    legend('G(t)','G(f)','Location','best');
end

grid on;
xlabel('Frecuencia (Hz)');
ylabel('Fase (°)');
title('Diagrama de Bode - Fase (FCa-16): G(t) vs G(f)');

%% 11) Márgenes (cuando sea posible) para ambos modelos
fprintf('\n=== MARGENES (Gt) ===\n');
print_margins(Gt);

fprintf('\n=== MARGENES (Gf) ===\n');
print_margins(Gf);

%% ====== Funciones auxiliares ======
function J = cost_second_order_db(p, w, Gexp_dB)
    % p = [log(K), logit(zeta), log(wn)]
    sigm  = @(x) 1./(1+exp(-x));
    K = exp(p(1));
    z = sigm(p(2));
    wn = exp(p(3));

    jw = 1j*w;
    Gjw = K*(wn^2) ./ ( (jw.^2) + 2*z*wn*jw + wn^2 );
    GdB = 20*log10(abs(Gjw));

    err = (GdB - Gexp_dB);
    J = sum(err.^2);

    % Penalización suave si zeta se va a extremos
    J = J + 1e2*(max(0,0.001 - z)^2 + max(0,z - 0.99)^2);
end

function print_margins(G)
    [GM, PM, Wcg, Wcp] = margin(G);
    if isinf(GM)
        fprintf('Margen de ganancia: INFINITO (no hay cruce de -180°)\n');
    else
        fprintf('Margen de ganancia: %.2f dB (f=%.2f Hz)\n', 20*log10(GM), Wcg/(2*pi));
    end

    if isnan(PM)
        fprintf('Margen de fase: No definido (no hay cruce de 0 dB)\n');
    else
        fprintf('Margen de fase: %.2f deg (f=%.2f Hz)\n', PM, Wcp/(2*pi));
    end
end
