% EPUCK_PLANTILLA  Plantilla de controlador para el proyecto Micromouse.
%
% Copien esta carpeta y renombrenla con el nombre de su equipo:
%     controllers/epuck_plantilla/epuck_plantilla.m
%  -> controllers/equipo_rojo/equipo_rojo.m
% (el nombre de la carpeta y del archivo .m deben ser iguales, sin espacios
%  ni acentos). Pueden agregar mas funciones .m dentro de la misma carpeta.
%
% Aqui se inicializan TODOS los dispositivos del e-puck (GCtronic, version 1)
% y se leen en cada paso. El comportamiento de EJEMPLO es un seguidor de pared
% derecha que avanza celda por celda usando los encoders. Por las reglas del
% laberinto (R8) un seguidor de pared NUNCA llega a la meta: ustedes deben
% reemplazarlo por exploracion, mapeo, flood fill, regreso al inicio y
% corridas rapidas. Las constantes de ejemplo NO estan calibradas.

TIME_STEP = wb_robot_get_basic_time_step();   % 16 ms (fijado en el mundo oficial)
V_MAX     = 6.28;                             % [rad/s] velocidad maxima de rueda
R_RUEDA   = 0.0205;                           % [m] radio de rueda
L_EJE     = 0.052;                            % [m] distancia entre ruedas
CELDA     = 0.18;                             % [m] tamano de celda (IEEE)

% ------------------------------------------------------------------------
% Motores (control de velocidad) y encoders [rad]
% ------------------------------------------------------------------------
motor_izq = wb_robot_get_device('left wheel motor');
motor_der = wb_robot_get_device('right wheel motor');
wb_motor_set_position(motor_izq, inf);
wb_motor_set_position(motor_der, inf);
wb_motor_set_velocity(motor_izq, 0);
wb_motor_set_velocity(motor_der, 0);

enc_izq = wb_robot_get_device('left wheel sensor');
enc_der = wb_robot_get_device('right wheel sensor');
wb_position_sensor_enable(enc_izq, TIME_STEP);
wb_position_sensor_enable(enc_der, TIME_STEP);

% ------------------------------------------------------------------------
% 8 sensores de proximidad infrarrojos (ps0..ps7)
%   ps0, ps7: frente (der/izq)   ps1, ps6: diagonales (der/izq)
%   ps2: derecha   ps5: izquierda   ps3, ps4: atras
% Valor alto = objeto cerca (~4095 en contacto, ~67 a 7 cm o mas).
% En MATLAB los indices van de 1 a 8: ps0 -> s.ps(1), ps7 -> s.ps(8).
% ------------------------------------------------------------------------
ps = zeros(1, 8);
for i = 1:8
    ps(i) = wb_robot_get_device(sprintf('ps%d', i-1));
    wb_distance_sensor_enable(ps(i), TIME_STEP);
end

% 8 sensores de luz ambiental (ls0..ls7), misma posicion que ps
ls = zeros(1, 8);
for i = 1:8
    ls(i) = wb_robot_get_device(sprintf('ls%d', i-1));
    wb_light_sensor_enable(ls(i), TIME_STEP);
end

% 3 sensores de piso (gs0..gs2): valor bajo = piso negro, alto = meta amarilla
gs = zeros(1, 3);
for i = 1:3
    gs(i) = wb_robot_get_device(sprintf('gs%d', i-1));
    wb_distance_sensor_enable(gs(i), TIME_STEP);
end

% Camara frontal (52 x 39 pixeles RGB)
camara = wb_robot_get_device('camera');
wb_camera_enable(camara, TIME_STEP);

% Acelerometro [m/s^2] y giroscopio [rad/s]
acel = wb_robot_get_device('accelerometer');
wb_accelerometer_enable(acel, TIME_STEP);
giro = wb_robot_get_device('gyro');
wb_gyro_enable(giro, TIME_STEP);

% LEDs: led0..led7 en el anillo (led0 al frente, en sentido horario),
%       led8 = cuerpo (verde), led9 = frontal
led = zeros(1, 10);
for i = 1:10
    led(i) = wb_robot_get_device(sprintf('led%d', i-1));
end

% Comunicacion: emisor/receptor (pueden enviar telemetria para depurar)
emisor   = wb_robot_get_device('emitter');
receptor = wb_robot_get_device('receiver');
wb_receiver_enable(receptor, TIME_STEP);

% ------------------------------------------------------------------------
% Parametros del comportamiento de EJEMPLO (calibrenlos ustedes)
% ------------------------------------------------------------------------
UMBRAL_PARED  = 90;                         % lectura IR: hay pared en la celda
UMBRAL_CHOQUE = 300;                        % lectura IR frontal: demasiado cerca
RAD_CELDA     = CELDA / R_RUEDA;            % giro de rueda para avanzar 1 celda [rad]
RAD_90        = (L_EJE/2) * (pi/2) / R_RUEDA;  % giro de rueda para girar 90 grados [rad]
V_AVANCE      = 0.5 * V_MAX;
V_GIRO        = 0.3 * V_MAX;
K_CENTRO      = 0.005;                      % ganancia de centrado lateral

estado   = 'DECIDIR';     % DECIDIR | GIRAR | AVANZAR
encI0 = 0; encD0 = 0;     % encoders al iniciar el movimiento actual
radGiro = 0; sentido = 0; % giro pendiente (rad de rueda) y sentido (+1 izq, -1 der)
tImpresion = 0;

% ------------------------------------------------------------------------
% Ciclo principal
% ------------------------------------------------------------------------
while wb_robot_step(TIME_STEP) ~= -1
    t = wb_robot_get_time();

    % ---- lectura de sensores ----
    s.ps   = arrayfun(@wb_distance_sensor_get_value, ps);
    s.ls   = arrayfun(@wb_light_sensor_get_value, ls);
    s.gs   = arrayfun(@wb_distance_sensor_get_value, gs);
    s.encI = wb_position_sensor_get_value(enc_izq);
    s.encD = wb_position_sensor_get_value(enc_der);
    s.acel = wb_accelerometer_get_values(acel);
    s.giro = wb_gyro_get_values(giro);
    s.img  = wb_camera_get_image(camara);       % 39 x 52 x 3 uint8

    frente = (s.ps(1) + s.ps(8)) / 2;
    paredF = frente  > UMBRAL_PARED;
    paredD = s.ps(3) > UMBRAL_PARED;
    paredI = s.ps(6) > UMBRAL_PARED;

    % ---- comportamiento de EJEMPLO: seguidor de pared derecha ----
    vI = 0; vD = 0;
    switch estado
        case 'DECIDIR'
            if ~paredD
                sentido = -1; radGiro = RAD_90;       % gira a la derecha
            elseif ~paredF
                sentido = 0;  radGiro = 0;            % sigue derecho
            elseif ~paredI
                sentido = +1; radGiro = RAD_90;       % gira a la izquierda
            else
                sentido = +1; radGiro = 2 * RAD_90;   % callejon: media vuelta
            end
            encI0 = s.encI; encD0 = s.encD;
            if radGiro > 0, estado = 'GIRAR'; else, estado = 'AVANZAR'; end

        case 'GIRAR'
            avance = (abs(s.encI - encI0) + abs(s.encD - encD0)) / 2;
            if avance >= radGiro
                encI0 = s.encI; encD0 = s.encD;
                estado = 'AVANZAR';
            else
                vI = -sentido * V_GIRO;
                vD =  sentido * V_GIRO;
            end

        case 'AVANZAR'
            avance = ((s.encI - encI0) + (s.encD - encD0)) / 2;
            if avance >= RAD_CELDA || frente > UMBRAL_CHOQUE
                estado = 'DECIDIR';
            else
                % centrado: si hay pared a ambos lados, se aleja de la mas cercana
                correccion = 0;
                if paredD && paredI
                    correccion = K_CENTRO * (s.ps(6) - s.ps(3));
                end
                vI = V_AVANCE + correccion;
                vD = V_AVANCE - correccion;
            end
    end

    wb_motor_set_velocity(motor_izq, max(-V_MAX, min(V_MAX, vI)));
    wb_motor_set_velocity(motor_der, max(-V_MAX, min(V_MAX, vD)));

    % ---- LEDs: muestran las paredes detectadas ----
    wb_led_set(led(1), double(paredF));      % led0: pared al frente
    wb_led_set(led(3), double(paredD));      % led2: pared a la derecha
    wb_led_set(led(7), double(paredI));      % led6: pared a la izquierda
    wb_led_set(led(9), double(strcmp(estado, 'AVANZAR')));   % cuerpo: avanzando

    % ---- impresion de sensores una vez por segundo ----
    if t - tImpresion >= 1
        tImpresion = t;
        fprintf('t=%5.1f  %-8s ps=[%s]  gs=[%s]  enc=[%.2f %.2f]  giro_z=%.3f\n', ...
                t, estado, sprintf('%5.0f', s.ps), sprintf('%5.0f', s.gs), ...
                s.encI, s.encD, s.giro(3));
    end
end
