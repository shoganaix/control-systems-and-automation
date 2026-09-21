%% FAa-08 - FIGURAS FINALES (G(t) vs G(f))
% Este script NO modifica figuras anteriores !
clear; close all; clc;

%% 0) Cargar datos y recalcular G(t) y G(f)
fileName = 'FAa-08_Waveform.csv';
data = readmatrix(fileName);
t = data(:,1); u = data(:,2); y = data(:,3);
t = t(:); u = u(:); y = y(:);

% Alinear al flanco
u_pre  = median(u(1:round(0.1*numel(u))));
u_post = median(u(round(0.9*numel(u)):end));
u_th = (u_pre + u_post)/2;
i0 = find(u >= u_th, 1, 'first');
t0 = t(i0);
t  = t - t0;

% Ventana
tmin = -5e-3; tmax = 20e-3;
m = (t>=tmin) & (t<=tmax);
tt = t(m); uu = u(m); yy = y(m);
tt = tt(:); uu = uu(:); yy = yy(:);

% Niveles
n = numel(yy); n10 = max(10, round(0.10*n));
y_pre = median(yy(1:n10));
y_inf = median(yy(end-n10+1:end));

idx0p = (tt >= 0) & (tt <= 100e-6);
y_0p = median(yy(idx0p));

u0 = median(uu(1:n10));
u1 = median(uu((tt>=0) & (tt<=100e-6)));
Du = u1 - u0;
Dy = y_inf - y_pre;
K  = Dy / Du;

% Tau
y_tau_level = y_inf - 0.368*(y_inf - y_0p);
tt_post = tt(tt>=0);
yy_post = yy(tt>=0);
i_tau = find(yy_post >= y_tau_level, 1, 'first');
if isempty(i_tau), [~, i_tau] = min(abs(yy_post - y_tau_level)); end
tau = tt_post(i_tau);

% T
y0_rel   = y_0p  - y_pre;
yinf_rel = y_inf - y_pre;
T = tau * (y0_rel / yinf_rel);

% Modelo tiempo: Gt
s = tf('s');
Gt = K * (1 + T*s) / (1 + tau*s);

%% Datos experimentales de frecuencia
f_exp   = [100 200 600 1000 2000 3000];
Uin_mV  = [115.3 397.4 985.5 983.7 985.4 984.3];
Uout_mV = [132.1 440.4 954.1 905.8 757.8 616.5];

Gexp_dB = 20*log10(Uout_mV ./ Uin_mV);
phi_exp = [-2  -4  -11  -16  -20  -18];   % grados

%% Calcular f_phi_min del modelo (para estimar Gf)
f_dense = logspace(1,4,2000);
w_dense = 2*pi*f_dense;
[~, ph_dense] = bode(Gt, w_dense);
ph_dense = squeeze(ph_dense);
[~, idx_min] = min(ph_dense);
f_phi_min = f_dense(idx_min);

%% Modelo frecuencia: Gf (ajuste simple)
Kf = mean(10.^(Gexp_dB(1:2)/20));    % baja frecuencia
fp_f = 900;                          % ajustable
fz_f = (f_phi_min^2)/fp_f;

tau_f = 1/(2*pi*fp_f);
T_f   = 1/(2*pi*fz_f);

Gf = Kf * (1 + T_f*s) / (1 + tau_f*s);

%% 1) FIGURA FINAL 3.1: ESCALÓN (lab vs Gt vs Gf)
u_step = (uu - u0);                  % entrada excitación alrededor de 0
y_Gt = lsim(Gt, u_step, tt) + y_pre;
y_Gf = lsim(Gf, u_step, tt) + y_pre;

figure;
plot(tt, yy, 'LineWidth', 1.5); hold on;
plot(tt, y_Gt, '--', 'LineWidth', 1.5);
plot(tt, y_Gf, ':', 'LineWidth', 1.8);
grid on;
xlabel('Tiempo (s)');
ylabel('Salida (V)');
title('Comparación a Escalón (FAa-08): Laboratorio vs G(t)/G(f)');
legend('Laboratorio (CH2)','Modelo G(t)','Modelo G(f)','Location','best');

%% 2) FIGURA FINAL 3.2 (MÓDULO): Bode módulo (lab vs Gt / Gf)
w = 2*pi*logspace(1,4,400);
f_th = w/(2*pi);

[mag_t, ph_t] = bode(Gt, w); mag_t = squeeze(mag_t); ph_t = squeeze(ph_t);
[mag_f, ph_f] = bode(Gf, w); mag_f = squeeze(mag_f); ph_f = squeeze(ph_f);

Gt_dB = 20*log10(mag_t);
Gf_dB = 20*log10(mag_f);

figure;
semilogx(f_th, Gt_dB, 'LineWidth', 1.5); hold on;
semilogx(f_th, Gf_dB, '--', 'LineWidth', 1.5);
semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
title('Diagrama de Bode - Módulo (FAa-08): Laboratorio vs G(t)/G(f)');
legend('G(t)','G(f)','Experimental','Location','best');

%% 3) FIGURA FINAL 3.2 (FASE): Bode fase (lab vs Gt / Gf)
figure;
semilogx(f_th, ph_t, 'LineWidth', 1.5); hold on;
semilogx(f_th, ph_f, '--', 'LineWidth', 1.5);
semilogx(f_exp, phi_exp, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Fase (°)');
title('Diagrama de Bode - Fase (FAa-08): Laboratorio vs G(t)/G(f)');
legend('G(t)','G(f)','Experimental','Location','best');
