-- User login (by username) and user management
SELECT id_usuario, nombre_usuario, contraseña_hash
FROM Usuario
WHERE nombre_usuario = 'hacker_mx' AND activo = TRUE;



-- Check email availability
SELECT COUNT(*) AS email_exists
FROM Usuario
WHERE correo = 'test@example.com';


-- Get user profile with stats
SELECT 
    u.id_usuario, u.nombre_usuario, u.correo, u.pais,
    COALESCE(SUM(p.puntos_obtenidos), 0) AS total_puntos,
    COUNT(CASE WHEN p.estado = 'completado' THEN 1 END) AS maquinas_completadas
FROM Usuario u
LEFT JOIN Progreso p ON u.id_usuario = p.id_usuario
WHERE u.id_usuario = 1
GROUP BY u.id_usuario, u.nombre_usuario, u.correo, u.pais;



-- Progress tracking

-- machine completion
UPDATE Progreso
SET estado = 'completado', fecha_completado = NOW(), puntos_obtenidos = 50
WHERE id_usuario = 1 AND id_maquina = 5;

-- users machine history
SELECT m.nombre, p.estado, p.puntos_obtenidos, p.intentos
FROM Progreso p
JOIN Maquina m ON p.id_maquina = m.id_maquina
WHERE p.id_usuario = 1
ORDER BY p.fecha_inicio DESC;




-- Rankings


-- Global leaderboard (top 10)
SELECT posicion_global, nombre_usuario, pais, puntos_totales, maquinas_completadas
FROM v_ranking_usuario_global
ORDER BY posicion_global ASC
LIMIT 10;


-- Country leaderboard (Mexico)
SELECT posicion_pais, nombre_usuario, puntos_totales
FROM v_ranking_usuario_global
WHERE pais = 'México'
ORDER BY posicion_pais ASC;


-- Machine difficulty analysis
SELECT nombre_maquina, dificultad, tasa_completacion_pct, tiempo_promedio_minutos
FROM v_ranking_maquina_dificultad
WHERE tasa_completacion_pct < 30
ORDER BY tasa_completacion_pct ASC;


-- Average time by difficulty
SELECT dificultad, COUNT(*) AS num_maquinas, ROUND(AVG(tiempo_promedio_minutos), 1) AS tiempo_promedio
FROM v_ranking_maquina_dificultad
GROUP BY dificultad
ORDER BY FIELD(dificultad, 'Fácil', 'Media', 'Difícil', 'Insane');


-- ________________________________________________________________________________________

--                        More detailed queries examples in Architecture.md :)
-- ________________________________________________________________________________________
