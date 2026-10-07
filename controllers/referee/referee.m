% REFEREE  Arbitro automatico del proyecto Micromouse (Supervisor).
%
% Mide el TIEMPO DE SIMULACION (no el del reloj de la computadora), de modo
% que el resultado no depende de la velocidad del equipo donde se corre.
%
%   - Una corrida inicia cuando el centro del e-puck SALE de la celda de inicio.
%   - Una corrida termina cuando el centro del e-puck ENTRA a la meta (2x2).
%   - Para iniciar otra corrida el robot debe regresar (solo) a la celda de inicio.
%   - Si durante una corrida regresa al inicio sin llegar a la meta, la corrida
%     se anula y se puede intentar de nuevo.
%
%   Puntaje de cada corrida:  P = t_corrida + t_salida / FACTOR_PENALIZACION
%   donde t_salida es el instante (desde t = 0) en que inicio esa corrida.
%   El puntaje final del robot es el MENOR P de sus corridas completas.
%   Tambien se registra el numero de celdas distintas visitadas (desempate
%   entre robots que no completan ninguna corrida).
%
%   El concurso del robot termina cuando ocurre lo primero de:
%     - se alcanza TIEMPO_LIMITE,
%     - el robot no cambia de celda en TIEMPO_ATORADO segundos,
%     - el robot se queda en la celda de inicio TIEMPO_ESTACIONADO segundos
%       despues de haber completado al menos una corrida.
%
% Los resultados se agregan a results/resultados.csv y el detalle de cada
% corrida se guarda en results/<equipo>_<laberinto>_<fecha>.txt
%
% NO MODIFICAR (archivo oficial del concurso).

TIEMPO_LIMITE       = 600;   % [s] 10 minutos de simulacion
FACTOR_PENALIZACION = 30;
TIEMPO_ATORADO      = 60;    % [s]
TIEMPO_ESTACIONADO  = 30;    % [s]

TIME_STEP = wb_robot_get_basic_time_step();

% ---- datos del laberinto (customData del arbitro, definido en el mundo oficial) ----
datos = wb_robot_get_custom_data();
N  = str2double(regexp(datos, 'N=(\d+)', 'tokens', 'once'));
C  = str2double(regexp(datos, 'CELDA=([\d.]+)', 'tokens', 'once'));
lab = regexp(datos, 'LABERINTO=(\S+)', 'tokens', 'once');
lab = lab{1};
g  = N/2;

mouse  = wb_supervisor_node_get_from_def('MOUSE');
equipo = wb_supervisor_field_get_sf_string(wb_supervisor_node_get_field(mouse, 'controller'));

estado      = 'EN_INICIO';    % EN_INICIO | CORRIENDO | REGRESANDO
corridas    = zeros(0, 4);    % [t_salida, t_llegada, t_corrida, puntaje]
anuladas    = 0;
tSalida     = 0;
celdaPrev   = [0 0];
tCambio     = 0;              % ultimo instante en que cambio de celda
tLlegoInicio = 0;             % instante en que volvio a la celda de inicio
motivo      = 'tiempo limite';
tEtiqueta   = -inf;
visitadas   = false(N, N);    % celdas distintas visitadas (criterio de desempate)

fprintf('[arbitro] Equipo "%s" en laberinto "%s" (%dx%d)\n', equipo, lab, N, N);

while wb_robot_step(TIME_STEP) ~= -1
    t   = wb_robot_get_time();
    pos = wb_supervisor_node_get_position(mouse);
    celda = floor(pos(1:2) / C);
    enInicio = all(celda == [0 0]);
    enMeta   = any(celda(1) == [g-1 g]) && any(celda(2) == [g-1 g]);
    if all(celda >= 0) && all(celda < N)
        visitadas(celda(1)+1, celda(2)+1) = true;
    end

    if any(celda ~= celdaPrev)
        celdaPrev = celda;
        tCambio = t;
    end

    switch estado
        case 'EN_INICIO'
            if ~enInicio
                estado  = 'CORRIENDO';
                tSalida = t;
                fprintf('[arbitro] t=%7.3f s  sale del inicio (corrida %d)\n', t, size(corridas,1) + 1);
            end
        case 'CORRIENDO'
            if enMeta
                tc = t - tSalida;
                P  = tc + tSalida / FACTOR_PENALIZACION;
                corridas(end+1, :) = [tSalida, t, tc, P]; %#ok<SAGROW>
                estado = 'REGRESANDO';
                fprintf('[arbitro] t=%7.3f s  LLEGA A LA META: corrida %d = %.3f s, puntaje %.3f\n', ...
                        t, size(corridas,1), tc, P);
            elseif enInicio
                anuladas = anuladas + 1;
                estado = 'EN_INICIO';
                tLlegoInicio = t;
                fprintf('[arbitro] t=%7.3f s  regreso al inicio sin llegar: corrida anulada\n', t);
            end
        case 'REGRESANDO'
            if enInicio
                estado = 'EN_INICIO';
                tLlegoInicio = t;
                fprintf('[arbitro] t=%7.3f s  de vuelta en el inicio\n', t);
            end
    end

    % ---- marcador en pantalla ----
    if t - tEtiqueta >= 0.25
        tEtiqueta = t;
        if isempty(corridas)
            txtMejor = '--';
        else
            [~, k] = min(corridas(:,4));
            txtMejor = sprintf('%.3f s (puntaje %.3f)', corridas(k,3), corridas(k,4));
        end
        if strcmp(estado, 'CORRIENDO'), txtActual = sprintf('%.2f s', t - tSalida);
        else,                           txtActual = '--';
        end
        txt = sprintf(['%s  |  %s\nTiempo: %.2f / %d s   Estado: %s\n' ...
                       'Corrida actual: %s   Completas: %d   Anuladas: %d   Celdas: %d\nMejor: %s'], ...
                      equipo, lab, t, TIEMPO_LIMITE, estado, txtActual, ...
                      size(corridas,1), anuladas, nnz(visitadas), txtMejor);
        wb_supervisor_set_label(0, txt, 0.01, 0.01, 0.07, [1 1 1], 0, 'Arial');
    end

    % ---- fin del concurso ----
    if t >= TIEMPO_LIMITE
        motivo = 'tiempo limite'; break
    end
    if t - tCambio >= TIEMPO_ATORADO
        motivo = 'robot atorado'; break
    end
    if strcmp(estado, 'EN_INICIO') && ~isempty(corridas) && t - tLlegoInicio >= TIEMPO_ESTACIONADO
        motivo = 'robot estacionado en el inicio'; break
    end
end

% ---- resultados ----
t = wb_robot_get_time();
if isempty(corridas)
    mejorT = NaN; mejorP = NaN;
else
    [mejorP, k] = min(corridas(:,4));
    mejorT = corridas(k,3);
end
fprintf('[arbitro] FIN (%s) en t=%.3f s. Completas: %d  Mejor tiempo: %.3f s  Puntaje: %.3f  Celdas: %d\n', ...
        motivo, t, size(corridas,1), mejorT, mejorP, nnz(visitadas));

dirRes = fullfile('..', '..', 'results');
if ~exist(dirRes, 'dir'), mkdir(dirRes); end
fecha = datestr(now, 'yyyy-mm-dd_HHMMSS'); %#ok<TNOW1,DATST>

resumen = fullfile(dirRes, 'resultados.csv');
nuevo = ~exist(resumen, 'file');
fid = fopen(resumen, 'a');
if nuevo
    fprintf(fid, 'fecha,equipo,laberinto,completas,anuladas,celdas_visitadas,mejor_tiempo_s,mejor_puntaje,fin,t_fin_s\n');
end
fprintf(fid, '%s,%s,%s,%d,%d,%d,%.3f,%.3f,%s,%.3f\n', fecha, equipo, lab, size(corridas,1), ...
        anuladas, nnz(visitadas), mejorT, mejorP, motivo, t);
fclose(fid);

fid = fopen(fullfile(dirRes, sprintf('%s_%s_%s.txt', equipo, lab, fecha)), 'w');
fprintf(fid, 'Equipo: %s\nLaberinto: %s (%dx%d)\nFin: %s en t = %.3f s\n\n', equipo, lab, N, N, motivo, t);
fprintf(fid, '%8s %10s %10s %10s %10s\n', 'corrida', 't_salida', 't_llegada', 't_corrida', 'puntaje');
for i = 1:size(corridas,1)
    fprintf(fid, '%8d %10.3f %10.3f %10.3f %10.3f\n', i, corridas(i,:));
end
fprintf(fid, '\nMejor tiempo: %.3f s   Puntaje final: %.3f\n', mejorT, mejorP);
fprintf(fid, 'Celdas distintas visitadas: %d de %d\n', nnz(visitadas), N*N);
fclose(fid);

wb_supervisor_set_label(1, sprintf('FIN: %s', motivo), 0.01, 0.20, 0.08, [1 0.85 0], 0, 'Arial');

% Detiene la simulacion (no cierra Webots). Para torneos automaticos sin
% interfaz, definir la variable de entorno MICROMOUSE_SALIR=1 y Webots se cierra.
if strcmp(getenv('MICROMOUSE_SALIR'), '1')
    wb_supervisor_simulation_quit(0);
else
    wb_supervisor_simulation_set_mode(WB_SUPERVISOR_SIMULATION_MODE_PAUSE);
end
wb_robot_step(TIME_STEP);
