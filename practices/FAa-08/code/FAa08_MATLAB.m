%% FAa-08 - Practica Bloque I
clear; close all; clc;

%% 0) Archivo
fileName = 'FAa-08_Waveform.csv';

%% 1) Carga de datos
data = readmatrix(fileName);

t = data(:,1);    % Tiempo (s)
u = data(:,2);    % CH1 (entrada)
y = data(:,3);    % CH2 (salida)

% Fuerza columnas para evitar problemas de tamaños
t = t(:); u = u(:); y = y(:);

%% 2) Alinear el tiempo al flanco (la entrada cruza la mitad del escalón)
u_pre  = median(u(1:round(0.1*numel(u))));
u_post = median(u(round(0.9*numel(u)):end));
u_th = (u_pre + u_post)/2;

i0 = find(u >= u_th, 1, 'first');
if isempty(i0)
    error('No se detecta flanco en CH1. Revisa columnas o señal de entrada');
end

t0 = t(i0);
t  = t - t0;  % flanco ~ t=0

%% 3) Recortar ventana amplia para análisis
tmin = -5e-3;
tmax =  20e-3;   % 20 ms
m = (t>=tmin) & (t<=tmax);
tt = t(m); uu = u(m); yy = y(m);
tt = tt(:); uu = uu(:); yy = yy(:);

%% 4) Estimar niveles de salida de forma robusta
% y_pre: mediana del 10% inicial de la ventana
n = numel(yy);
n10 = max(10, round(0.10*n));

y_pre = median(yy(1:n10));

% y_inf: mediana del 10% final de la ventana
y_inf = median(yy(end-n10+1:end));

% y(0+): mediana en una ventana justo después del flanco (0 a 2% de la ventana)
idx0p = (tt >= 0) & (tt <= (tt(1) + 0.002*(tt(end)-tt(1)))); % ventana pequeñita
if nnz(idx0p) < 5
    idx0p = (tt >= 0) & (tt <= 100e-6); % fallback
end
y_0p = median(yy(idx0p));

% Entrada real: u0 antes y u1 después
u0 = median(uu(1:n10));
u1 = median(uu((tt>=0) & (tt<=100e-6)));
Du = u1 - u0;
Dy = y_inf - y_pre;
K  = Dy / Du;

%% 5) Calcular tau buscando el cruce en TODO t>=0
y_tau_level = y_inf - 0.368*(y_inf - y_0p);

tt_post = tt(tt>=0);
yy_post = yy(tt>=0);

i_tau = find(yy_post >= y_tau_level, 1, 'first');
if isempty(i_tau)
    % Si nunca cruza por ruido, usamos una interpolación con el mínimo error
    [~, i_tau] = min(abs(yy_post - y_tau_level));
end
tau = tt_post(i_tau);

%% 6) Calcular T (cero)
y0_rel   = y_0p  - y_pre;
yinf_rel = y_inf - y_pre;
T = tau * (y0_rel / yinf_rel);


%% 7) Definir función de transferencia con tf
s = tf('s');
G = K * (1 + T*s) / (1 + tau*s);

%% Margenes de estabilidad (si es posible)
[GM, PM, Wcg, Wcp] = margin(G);

% GM: Gain Margin (factor)
% PM: Phase Margin (grados)
% Wcg: frecuencia (rad/s) donde la fase cruza -180° (para GM)
% Wcp: frecuencia (rad/s) donde el modulo cruza 0 dB (para PM)

GM_dB = 20*log10(GM);

fprintf('\n=== MARGENES (modelo) ===\n');
if isinf(GM)
    fprintf('Margen de ganancia: INFINITO (no hay cruce de -180°)\n');
else
    fprintf('Margen de ganancia: %.2f dB (w = %.2f rad/s, f=%.2f Hz)\n', GM_dB, Wcg, Wcg/(2*pi));
end

if isnan(PM)
    fprintf('Margen de fase: No definido (no hay cruce de 0 dB)\n');
else
    fprintf('Margen de fase: %.2f deg (w = %.2f rad/s, f=%.2f Hz)\n', PM, Wcp, Wcp/(2*pi));
end

%% 8) Simulación del modelo ante el MISMO escalón
% Creamos una señal escalón con la misma amplitud y offset que tu entrada
u_model = u0 + Du*(tt >= 0);      % escalón ideal
y_model = lsim(G, u_model - u0, tt) + y_pre;  
% Nota: lo que estamos haciendo es restar u0 para excitar desde 0 y luego sumamos y_pre

%% 9) Gráfica tipo "obtención tau"
figure;
plot(tt, uu, 'LineWidth', 1.3); hold on;             % Input real
plot(tt, yy, 'LineWidth', 1.3);                      % Output real
plot(tt, y_model, '--', 'LineWidth', 1.6);           % Model
plot([tt(1) tt(end)], [y_inf y_inf], 'k-', 'LineWidth', 1.0); % Nominal

% guías tau
plot([0 tau], [y_tau_level y_tau_level], 'g--', 'LineWidth', 1.5);
plot([tau tau], [y_pre y_tau_level], 'g--', 'LineWidth', 1.5);
text(tau*1.03, y_tau_level, sprintf('\\tau = %.3g s', tau), ...
    'Color','g','FontSize',11,'VerticalAlignment','bottom');
grid on;
xlabel('Tiempo (s)');
ylabel('Voltage (V)');
title('Obtención \tau - (FAa-08)');
legend('Input (CH1)','Output (CH2)','Modelo (tf+lsim)','Nominal','Location','best');

%% 10) Imprimir parámetros en 'Command Window'
fp = 1/(2*pi*tau);
fz = 1/(2*pi*T);

fprintf('\n=== PARAMETROS IDENTIFICADOS (desde fichero) ===\n');
fprintf('y(0+)   = %.4f V\n', y_0p);
fprintf('y(inf)  = %.4f V\n', y_inf);
fprintf('tau     = %.6g s\n', tau);
fprintf('K       = %.4f\n', K);
fprintf('T       = %.6g s\n', T);
fprintf('fp      = %.2f Hz\n', fp);
fprintf('fz      = %.2f Hz\n', fz);
fprintf('G(s)    = K(1+Ts)/(1+tau s)\n');

%% 11) Bode teórico + puntos experimentales
% Mis datos experimentales
f_exp   = [100 200 600 1000 2000 3000];
Uin_mV  = [115.3 397.4 985.5 983.7 985.4 984.3];
Uout_mV = [132.1 440.4 954.1 905.8 757.8 616.5];

Gexp_dB = 20*log10(Uout_mV ./ Uin_mV);
phi_exp = [-2  -4  -11  -16  -20  -18];   % grados
%dt_exp_us = [55.6  55.6  50.9  44.4  27.8  16.7];  % microsegundos (no lo
%utilizamos por ahora)

% Bode teórico (solo módulo en dB) evaluando tf
w = 2*pi*logspace(1,4,400);  % rad/s
[mag, ph] = bode(G, w);
mag = squeeze(mag);
Gth_dB = 20*log10(mag);
ph  = squeeze(ph);
f_th = w/(2*pi);

% MODULO
figure;
semilogx(w/(2*pi), Gth_dB, 'LineWidth', 1.5); hold on;
semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
title('Diagrama de Bode - Módulo (FAa-08)');
legend('Teórico (tf)', 'Experimental', 'Location', 'best');

% FASE
figure;
semilogx(f_th, ph,'LineWidth',1.5); hold on;
semilogx(f_exp, phi_exp,'o','LineWidth',1.5);
grid on; xlabel('Frecuencia (Hz)'); ylabel('Fase (°)');
legend('Teórico','Experimental','Location','best');
title('Diagrama de Bode - Fase (FAa-08)');


%% 12) Bode + fase, marca 𝑓min
% --- Frecuencias características ---
fp = 1/(2*pi*tau);
fz = 1/(2*pi*T);

% --- Bode teórico en una malla para calcular mínimos y -3 dB ---
f_dense = logspace(1,4,2000);          % Hz
w_dense = 2*pi*f_dense;                % rad/s
[mag_d, ph_d] = bode(G, w_dense);
mag_d = squeeze(mag_d);                % |G(jw)|
ph_d  = squeeze(ph_d);                 % grados

GdB_d = 20*log10(mag_d);

% === Fase mínima del modelo en el rango de interés ===
[phi_min, idx_min] = min(ph_d);
f_phi_min = f_dense(idx_min);

fprintf('\n=== FASE MINIMA (modelo) ===\n');
fprintf('Fase mínima = %.2f deg\n', phi_min);
fprintf('Frecuencia fase mínima = %.1f Hz\n', f_phi_min);

% === Frecuencia cercana a -3 dB (si existe en rango) ===
[~, idx_3] = min(abs(GdB_d + 3));
f_3dB = f_dense(idx_3);
G_3dB = GdB_d(idx_3);

fprintf('\n=== CORTE ~ -3 dB (modelo) ===\n');
fprintf('f_-3dB ≈ %.1f Hz (G=%.2f dB)\n', f_3dB, G_3dB);

%% --- Bode MÓDULO anotado ---
figure;
semilogx(f_th, Gth_dB, 'LineWidth', 1.5); hold on;
semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);

xline(fp,'--k','f_p','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
xline(fz,'--k','f_z','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');

plot(f_3dB, G_3dB, 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
text(f_3dB*1.05, G_3dB, sprintf(' f_{-3dB}≈%.0f Hz', f_3dB));

grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
title('Diagrama de Bode - Módulo (FAa-08) [Anotado]');
legend('Teórico (tf)', 'Experimental', 'Location', 'best');

%% --- Bode FASE anotado ---
figure;
semilogx(f_th, ph, 'LineWidth', 1.5); hold on;
semilogx(f_exp, phi_exp, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);

xline(f_phi_min,'--k','f_{\phi,min}','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
plot(f_phi_min, phi_min, 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
text(f_phi_min*1.05, phi_min, sprintf('  \\phi_{min}=%.1f^\\circ', phi_min));

grid on;
xlabel('Frecuencia (Hz)');
ylabel('Fase (°)');
title('Diagrama de Bode - Fase (FAa-08) [Anotado]');
legend('Teórico', 'Experimental', 'Location', 'best');

text(f_phi_min*1.15, phi_min+1.2, ...
     sprintf('\\phi_{min}=%.1f^\\circ\nf\\approx %.0f Hz', phi_min, f_phi_min), ...
     'FontSize',11, ...
     'Color','k', ...
     'BackgroundColor','w', ...
     'Margin',3);
