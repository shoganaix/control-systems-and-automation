%% FBa-08 - Practica Bloque I
clear; close all; clc;

%% 0) Archivos
fileWave = 'FBa-08_Waveform.csv';      % escalón (t, CH1, CH2)

%% 1) Carga de datos
data = readmatrix(fileWave);

t = data(:,1);    % Tiempo (s)
u = data(:,2);    % CH1 (entrada)
y = data(:,3);    % CH2 (salida)

% Fuerza columnas para evitar problemas de tamaños
t = t(:); u = u(:); y = y(:);

%% 2) Alinear el tiempo al flanco (la entrada cruza la mitad del escalón)
du = [0; diff(u)];
[~, i0] = max(abs(du));

t0 = t(i0);
t  = t - t0; % flanco ~ t=0

%% 3) Recortar ventana amplia para análisis
tmin = -2e-3;
tmax =  60e-3;
m = (t>=tmin) & (t<=tmax);
tt = t(m); uu = u(m); yy = y(m);
tt = tt(:); uu = uu(:); yy = yy(:);

%% 4) Estimar niveles de salida de forma robusta
% y_pre: mediana del 10% inicial de la ventana
n = numel(yy);
n10 = max(10, round(0.10*n));

% u_inf: mediana del 10%
u_pre = median(uu(1:n10));
u_inf = median(uu(end-n10+1:end));
Du    = u_inf - u_pre;

% y_inf: mediana del 10% final de la ventana
y_inf = median(yy(end-n10+1:end));    % y(∞)
y_pre = median(yy(1:n10));            % y(0-)
Dy    = y_inf - y_pre;

% Ganancia estática:
K = Dy / Du;

% Señal de salida relativa (para tiempos característicos)
yrel = yy - y_pre;
yrel_inf = y_inf - y_pre;

%% 5) Características temporales: Mp, tp, wd, zeta, wn
% Máximo (pico) post-escalón
post = tt >= 0;
ttp  = tt(post);
ypp  = yy(post);

[ymax, i_pk] = max(ypp);
tp = ttp(i_pk);                 % tiempo de pico (s)

% Sobreoscilación Mp (en fracción)
% Mp = (ymax - y_inf) / (y_inf - y_pre)
Mp = (ymax - y_inf) / (y_inf - y_pre);

% Protección: si no hay sobreoscilación real, Mp<=0
if Mp <= 0
    warning('Mp <= 0: no parece subamortiguado o el pico no está bien capturado.');
    Mp = max(Mp, eps);
end

% zeta a partir de Mp
zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2);

% --- zeta alternativa (decremento logarítmico) si hay >=2 picos ---
% picos de ypp (post-escalón)
[pks, locs] = findpeaks(ypp, ttp, 'MinPeakProminence', 0.05*abs(Dy));

if numel(pks) >= 2
    A1 = pks(1) - y_inf;
    A2 = pks(2) - y_inf;
    if A1 > 0 && A2 > 0
        delta = log(A1/A2);
        zeta2 = delta / sqrt(4*pi^2 + delta^2);
        fprintf('\n[zeta por decremento log] zeta2 = %.6f (usando 2 picos)\n', zeta2);
        % si quieres, reemplaza:
        % zeta = zeta2;
        % wn = wd / sqrt(1 - zeta^2);
    end
end

% wd aproximado desde tp: tp = pi/wd
wd = pi / tp;

% wn
wn = wd / sqrt(1 - zeta^2);

% Polos
p1 = -zeta*wn + 1j*wd;
p2 = -zeta*wn - 1j*wd;

%% 6) Otros tiempos: td, tr, ts
% td: delay time (50% del valor final)
% tr: rise time (10%→90%)
% ts: settling time (2%) respecto a y_inf

% Nivel 10% y 90% y 50% (relativos)
y10 = 0.10 * yrel_inf;
y50 = 0.50 * yrel_inf;
y90 = 0.90 * yrel_inf;

% Función auxiliar: primer cruce
idx10 = find((tt>=0) & (yrel >= y10), 1, 'first');
idx50 = find((tt>=0) & (yrel >= y50), 1, 'first');
idx90 = find((tt>=0) & (yrel >= y90), 1, 'first');

if isempty(idx10) || isempty(idx90)
    warning('No se pudo calcular tr (10-90%%) por falta de cruces en la ventana.');
    tr = NaN;
else
    tr = tt(idx90) - tt(idx10);
end

if isempty(idx50)
    warning('No se pudo calcular td (50%%) por falta de cruce.');
    td = NaN;
else
    td = tt(idx50);
end

% ts 2% y 5% (primer instante a partir del cual se mantiene en banda)
band2 = 0.02 * abs(Dy);
band5 = 0.05 * abs(Dy);
e = abs(yy - y_inf);

ts2 = NaN; ts5 = NaN;
idx0 = find(tt>=0);

for k = idx0(:).'
    if isnan(ts5) && all(e(k:end) <= band5)
        ts5 = tt(k);
    end
    if all(e(k:end) <= band2)
        ts2 = tt(k);
        break; % el 2% es más exigente, si aparece ya paramos
    end
end

if isnan(ts2)
    warning('ts(2%%) no se alcanza en la ventana: amplía tmax.');
end

%% 7) Chi, fr y Mr (resonancia)
%   chi = Q = 1/(2*zeta)
chi = 1/(2*zeta);

% Frecuencia de resonancia (si zeta < 1/sqrt(2))
% wr = wn*sqrt(1 - 2*zeta^2)
% fr = wr/(2*pi)
if zeta < 1/sqrt(2)
    wr = wn*sqrt(1 - 2*zeta^2);
    fr = wr/(2*pi);
    Mr = 1/(2*zeta*sqrt(1 - zeta^2));   % pico de resonancia (módulo)
else
    wr = NaN; fr = NaN; Mr = NaN;
end

%% 8) Definir función de transferencia y simular escalón real
s = tf('s');
G = K * (wn^2) / (s^2 + 2*zeta*wn*s + wn^2);

% Entrada modelo (escalón con misma amplitud)
u_model = u_pre + Du*(tt >= 0);
% Excitación desde 0 y luego offset
y_model = lsim(G, u_model - u_pre, tt) + y_pre;

%% Margenes de estabilidad (si es posible)
[GM, PM, Wcg, Wcp] = margin(G);

% GM: Gain Margin (factor)
% PM: Phase Margin (grados)
% Wcg: frecuencia (rad/s) donde la fase cruza -180° (para GM)
% Wcp: frecuencia (rad/s) donde el modulo cruza 0 dB (para PM)

GM_dB = 20*log10(GM);

fprintf('\n=== MÁRGENES (modelo) ===\n');
if isinf(GM)
    fprintf('Margen de ganancia: INFINITO\n');
else
    fprintf('Margen de ganancia: %.2f dB (f = %.2f Hz)\n', GM_dB, Wcg/(2*pi));
end

if isnan(PM)
    fprintf('Margen de fase: No definido\n');
else
    fprintf('Margen de fase: %.2f deg (f = %.2f Hz)\n', PM, Wcp/(2*pi));
end

%% 9) Figura: entrada/salida y modelo
figure;
plot(tt, uu, 'LineWidth', 1.3); hold on;
plot(tt, yy, 'LineWidth', 1.3);
plot(tt, y_model, '--', 'LineWidth', 1.6);
ylim padded
yline(y_inf, 'k-', 'LineWidth', 1.0);

% marcas
plot(tp, ymax, 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
text(tp*1.02, ymax, sprintf(' t_p=%.3g s', tp), 'FontSize', 11);

grid on;
xlabel('Tiempo (s)');
ylabel('Voltage (V)');
title('FBa-08 - Respuesta temporal (2º orden) + modelo');
legend('Input (CH1)','Output (CH2)','Modelo (tf+lsim)','y(\infty)','Pico','Location','best');

%% 10) Imprimir parámetros en 'Command Window'
fprintf('\n=== FBa-08 (2º orden) PARAMETROS ===\n');
fprintf('K        = %.4f\n', K);
fprintf('Mp       = %.4f  (%.1f %%)\n', Mp, 100*Mp);
fprintf('ζ        = %.6f\n', zeta);

fprintf('wd       = %.6g rad/s   (%.2f Hz)\n', wd, wd/(2*pi));
fprintf('wn       = %.6g rad/s   (%.2f Hz)\n', wn, wn/(2*pi));
fprintf('Q        = %.4f\n', chi);

fprintf('td (50%%) = %.6g s\n', td);
fprintf('tr (10-90%%) = %.6g s\n', tr);
fprintf('tp       = %.6g s\n', tp);

fprintf('ts (5%%)  = %.6g s\n', ts5);
fprintf('ts (2%%)  = %.6g s\n', ts2);

fprintf('Polos: p1 = %.3g %+.3gj  rad/s\n', real(p1), imag(p1));
fprintf('       p2 = %.3g %+.3gj  rad/s\n', real(p2), imag(p2));

fprintf('fr       = %.6g Hz\n', fr);
fprintf('Mr       = %.6g (módulo)\n', Mr);

%% 11) Bode teórico + puntos experimentales (desde CAPTURAS)
% Datos experimentales (CH1=Uin, CH2=Uout) en mV
f_exp   = [100 200 600 1000 2000 3000 7000 12000 20000];                  % Hz
Uin_mV  = [279.0 530.4 998.4 986.5 984.3 986.2 986.9 988.0 986.8];       % CH1 Ampl (mV)
Uout_mV = [278.7 532.2 1024.0 1067.0 998.1 1017.0 343.6 95.95 33.01];    % CH2 Ampl (mV)

Gexp_dB = 20*log10(Uout_mV ./ Uin_mV);

% Fase experimental (dt estimado)s
dt_us = [18.2 0 0 0 0 3.0 40 30 20];   % <-- rellena si lo mides (en microsegundos)
phi_exp = -360 .* f_exp .* (dt_us*1e-6);  % grados

% --- Bode teórico centrado en la resonancia del sistema ---
fn = wn/(2*pi);
fmin = max(fn/50, 10);         % (10Hz min)
fmax = fn*50;
f_th = logspace(log10(fmin), log10(fmax), 1200);
w_th = 2*pi*f_th;

[mag, ph] = bode(G, w_th);
mag = squeeze(mag);
ph  = squeeze(ph);          % grados
Gth_dB = 20*log10(mag);

% --- MÓDULO ---
figure;
semilogx(f_th, Gth_dB, 'LineWidth', 1.5); hold on;
semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
ylim padded
title('Diagrama de Bode - Módulo (FBa-08)');
legend('Teórico (2º orden)', 'Experimental (capturas)', 'Location', 'best');

% --- FASE ---
figure;
semilogx(f_th, ph, 'LineWidth', 1.5); hold on;
ylim padded

if all(isfinite(phi_exp))
    semilogx(f_exp, phi_exp, 'o', 'LineWidth', 1.5);
    legend('Teórico', 'Experimental', 'Location', 'best');
else
    legend('Teórico', 'Location', 'best');
end

grid on;
xlabel('Frecuencia (Hz)');
ylabel('Fase (°)');
title('Diagrama de Bode - Fase (FBa-08)');

%% 12) Bode anotado para 2º orden (FBa-08) [Bode + fase, marca Mr 𝑓r]
% Frecuencias características
fn = wn/(2*pi);

if zeta < 1/sqrt(2)
    fr = (wn*sqrt(1-2*zeta^2))/(2*pi);
    Mr = 1/(2*zeta*sqrt(1-zeta^2));   % módulo (lineal)
    Mr_dB = 20*log10(Mr);
else
    fr = NaN;
    Mr_dB = NaN;
end

% Barrido denso
f_dense = logspace(log10(max(fn/100,10)), log10(fn*100), 5000);
w_dense = 2*pi*f_dense;
[mag_d, ph_d] = bode(G, w_dense);
mag_d = squeeze(mag_d);
ph_d  = squeeze(ph_d);
GdB_d = 20*log10(mag_d);

% Nivel DC (bajas frecuencias) ~ 20log10(K)
G0_dB = 20*log10(abs(K));

% Frecuencia -3 dB respecto a DC (si existe)
[~, idx_3] = min(abs(GdB_d - (G0_dB - 3)));
f_3dB = f_dense(idx_3);
G_3dB = GdB_d(idx_3);

fprintf('\n=== ANOTACIONES (2º orden) ===\n');
fprintf('fn = %.1f Hz\n', fn);
if isfinite(fr)
    fprintf('fr = %.1f Hz\n', fr);
    fprintf('Mr = %.2f dB\n', Mr_dB);
else
    fprintf('No hay fr/Mr (zeta >= 1/sqrt(2))\n');
end
fprintf('f_-3dB ≈ %.1f Hz (G=%.2f dB)\n', f_3dB, G_3dB);

%% --- Bode MÓDULO anotado ---
figure;
semilogx(f_dense, GdB_d, 'LineWidth', 1.5); hold on;
if exist('f_exp','var') && exist('Gexp_dB','var')
    semilogx(f_exp, Gexp_dB, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
end

xline(fn,'--k','f_n','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');

if isfinite(fr)
    xline(fr,'--k','f_r','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
    % Marca Mr en fr
    [~, idx_fr] = min(abs(f_dense-fr));
    plot(fr, GdB_d(idx_fr), 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
    text(fr*1.03, GdB_d(idx_fr), sprintf(' M_r=%.1f dB', Mr_dB),'BackgroundColor','w','EdgeColor','k','Margin',3);
end

plot(f_3dB, G_3dB, 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
text(f_3dB*1.05, G_3dB, sprintf(' f_{-3dB}≈%.0f Hz', f_3dB),'BackgroundColor','w','EdgeColor','k','Margin',3);

grid on;
xlabel('Frecuencia (Hz)');
ylabel('Ganancia (dB)');
title('Diagrama de Bode - Módulo (FBa-08) [Anotado]');
if exist('f_exp','var') && exist('Gexp_dB','var')
    legend('Modelo (tf)', 'Experimental', 'Location', 'best');
else
    legend('Modelo (tf)', 'Location', 'best');
end

%% --- Bode FASE anotado ---
figure;
semilogx(f_dense, ph_d, 'LineWidth', 1.5); hold on;

% Frecuencia aproximada donde fase = -90° (referencia)
[~, idx90] = min(abs(ph_d + 90));
f_90 = f_dense(idx90);
phi_90 = ph_d(idx90);

xline(f_90,'--k','f_{\phi=-90°}','LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
plot(f_90, phi_90, 'ks', 'MarkerSize', 7, 'LineWidth', 1.5);
text(f_90*1.05, phi_90, sprintf(' f_{\\phi=-90^\\circ}≈%.0f Hz', f_90),'BackgroundColor','w','EdgeColor','k','Margin',3);
grid on;
xlabel('Frecuencia (Hz)');
ylabel('Fase (°)');
title('Diagrama de Bode - Fase (FBa-08) [Anotado]');
legend('Modelo (tf)', 'Location', 'best');
