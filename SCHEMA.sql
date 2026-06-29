-- !/bin/bash



-- Modelo E-R Relacional Normalizado a 3NF
--                                                                                          Base de datos creada 

CREATE DATABASE IF NOT EXISTS htb_platform;
USE htb_platform;

--                                                                                       1 Categoría
--  Categorías de máquina                                                             (Linux, Windows, Web, Active Directory, OSINT)
CREATE TABLE Categoria (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_categoria_nombre ON Categoria(nombre);






--                                                                            Sistemas operativos de máquinassss (Linux, Windows, Web, etc)
CREATE TABLE OS (
    id_os INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_os_nombre ON OS(nombre);

                                                                                          --tabla 3 Dificultad
 
-- Niveles de dificultad (Fácil, Media, Difícil, Insane)
CREATE TABLE Dificultad (
    id_dificultad INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    rango_puntos_minimo INT,
    rango_puntos_maximo INT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dificultad_nombre ON Dificultad(nombre);






                                                                                          -- 4  Usuario
--  Usuarios de la plataforma

-- Información personal, credenciales, auditoría
CREATE TABLE Usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    apellido VARCHAR(50) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    pais VARCHAR(100) NOT NULL,
    contraseña_hash VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_conexion DATETIME,
    num_conexiones INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_usuario_nombre_usuario ON Usuario(nombre_usuario);
CREATE INDEX idx_usuario_correo ON Usuario(correo);
CREATE INDEX idx_usuario_pais ON Usuario(pais);
CREATE INDEX idx_usuario_activo ON Usuario(activo);








--                                                                                                  5 Máquina
-- Diposinbilidad de las maquinas
--                                                                                  Categoría (1:N), OS (1:N), Dificultad (1:N)
CREATE TABLE Maquina (
    id_maquina INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    puntos INT NOT NULL,
    id_categoria INT NOT NULL,
    id_os INT NOT NULL,
    id_dificultad INT NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    num_intentos_totales INT DEFAULT 0,
    num_completadas INT DEFAULT 0,
    
    -- FK
    CONSTRAINT fk_maquina_categoria FOREIGN KEY (id_categoria) 
        REFERENCES Categoria(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_maquina_os FOREIGN KEY (id_os) 
        REFERENCES OS(id_os) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_maquina_dificultad FOREIGN KEY (id_dificultad) 
        REFERENCES Dificultad(id_dificultad) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_maquina_categoria ON Maquina(id_categoria);
CREATE INDEX idx_maquina_os ON Maquina(id_os);
CREATE INDEX idx_maquina_dificultad ON Maquina(id_dificultad);
CREATE INDEX idx_maquina_nombre ON Maquina(nombre);
CREATE INDEX idx_maquina_activa ON Maquina(activa);







--                                                                                                        tabkla 6 Progreso
-- TABLA ASOCIATIVA - Vincula Usuario con Máquina (relación N:M)
-- Atrb: Fechas, estado, puntos obtenidos
CREATE TABLE Progreso (
    id_usuario INT NOT NULL,
    id_maquina INT NOT NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_completado DATETIME,
    intentos INT NOT NULL DEFAULT 1,
    estado ENUM('en_progreso', 'completado', 'abandonado') NOT NULL DEFAULT 'en_progreso',
    puntos_obtenidos INT,
    tiempo_total_minutos INT,
    
    -- Clave primaria compuesta
    PRIMARY KEY (id_usuario, id_maquina),
    
    -- FK
    CONSTRAINT fk_progreso_usuario FOREIGN KEY (id_usuario) 
        REFERENCES Usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_progreso_maquina FOREIGN KEY (id_maquina) 
        REFERENCES Maquina(id_maquina) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_progreso_usuario ON Progreso(id_usuario);
CREATE INDEX idx_progreso_maquina ON Progreso(id_maquina);
CREATE INDEX idx_progreso_estado ON Progreso(estado);
CREATE INDEX idx_progreso_fecha_completado ON Progreso(fecha_completado);









--                                                                                                              7 Intentos y vpn, logs
-- Registrp cada intento VPN y resolución para despues agregar los fallos:>>


-- Atributos: Timestamps, estado, errores, logs
CREATE TABLE Intento (
    id_intento INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_maquina INT NOT NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin DATETIME,
    exitoso BOOLEAN NOT NULL DEFAULT FALSE,
    tipo_fallo VARCHAR(255),
    logs LONGTEXT,
    duracion_segundos INT,
    ip_conectado VARCHAR(45),
    
    -- FK
    CONSTRAINT fk_intento_usuario FOREIGN KEY (id_usuario) 
        REFERENCES Usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_intento_maquina FOREIGN KEY (id_maquina) 
        REFERENCES Maquina(id_maquina) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_intento_usuario ON Intento(id_usuario);
CREATE INDEX idx_intento_maquina ON Intento(id_maquina);
CREATE INDEX idx_intento_exitoso ON Intento(exitoso);
CREATE INDEX idx_intento_fecha_inicio ON Intento(fecha_inicio);







--                                                                                                      8 Comentarios 'if...'
-- Comentarios de usuarios sobre máquinas (solo si las completaron)
-- Solo se permite comentar si Progreso.estado = 'completado', else error
CREATE TABLE Comentario (
    id_comentario INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_maquina INT NOT NULL,
    texto TEXT NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    -- FK
    CONSTRAINT fk_comentario_usuario FOREIGN KEY (id_usuario) 
        REFERENCES Usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_comentario_maquina FOREIGN KEY (id_maquina) 
        REFERENCES Maquina(id_maquina) ON DELETE CASCADE ON UPDATE CASCADE,
    -- Constraint si si se compleot o n0o
    -- ..
    -- ..
    -- ..
    -- ..
    CONSTRAINT fk_comentario_progreso FOREIGN KEY (id_usuario, id_maquina)
        REFERENCES Progreso(id_usuario, id_maquina) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_comentario_maquina ON Comentario(id_maquina);
CREATE INDEX idx_comentario_usuario ON Comentario(id_usuario);
CREATE INDEX idx_comentario_fecha ON Comentario(fecha_creacion);




--                                                                                                        VISTAS ANALÍTICAS   y   PROGRESS BARS




-- VISTA 1: Ranking Global de Usuarios


CREATE OR REPLACE VIEW v_ranking_usuario_global AS
SELECT 
    u.id_usuario,
    u.nombre_usuario,
    u.pais,
    u.fecha_registro,
    COALESCE(SUM(p.puntos_obtenidos), 0) AS puntos_totales,
    COUNT(CASE WHEN p.estado = 'completado' THEN 1 END) AS maquinas_completadas,
    COUNT(CASE WHEN p.estado = 'en_progreso' THEN 1 END) AS maquinas_en_progreso,
    COUNT(CASE WHEN p.estado = 'abandonado' THEN 1 END) AS maquinas_abandonadas,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(p.puntos_obtenidos), 0) DESC) AS posicion_global,
    ROW_NUMBER() OVER (PARTITION BY u.pais ORDER BY COALESCE(SUM(p.puntos_obtenidos), 0) DESC) AS posicion_pais
FROM Usuario u
LEFT JOIN Progreso p ON u.id_usuario = p.id_usuario
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.nombre_usuario, u.pais, u.fecha_registro;





-- VISTA 2: Estadísticas de Máquina por Dificultad
CREATE OR REPLACE VIEW v_ranking_maquina_dificultad AS
SELECT
    m.id_maquina,
    m.nombre AS nombre_maquina,
    d.nombre AS dificultad,
    c.nombre AS categoria,
    os.nombre AS sistema_operativo,
    m.puntos,
    COUNT(DISTINCT p.id_usuario) AS intentos_totales,
    COUNT(CASE WHEN p.estado = 'completado' THEN 1 END) AS completadas,
    ROUND(100 * COUNT(CASE WHEN p.estado = 'completado' THEN 1 END) / 
          NULLIF(COUNT(DISTINCT p.id_usuario), 0), 2) AS tasa_completacion_pct,
    AVG(CASE WHEN p.estado = 'completado' THEN p.tiempo_total_minutos END) AS tiempo_promedio_minutos
FROM Maquina m
JOIN Dificultad d ON m.id_dificultad = d.id_dificultad
JOIN Categoria c ON m.id_categoria = c.id_categoria
JOIN OS os ON m.id_os = os.id_os
LEFT JOIN Progreso p ON m.id_maquina = p.id_maquina
WHERE m.activa = TRUE
GROUP BY m.id_maquina, m.nombre, d.id_dificultad, d.nombre, c.nombre, os.nombre, m.puntos;

