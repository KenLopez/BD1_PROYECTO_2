DROP PROCEDURE IF EXISTS AddNacimiento;
DROP PROCEDURE IF EXISTS ShowError;
DROP PROCEDURE IF EXISTS getNacimiento;
DROP PROCEDURE IF EXISTS AddDefuncion;
DROP PROCEDURE IF EXISTS getDefuncion;
DROP PROCEDURE IF EXISTS generarDPI;
DROP PROCEDURE IF EXISTS getDPI;
DROP PROCEDURE IF EXISTS AddMatrimonio;
DROP PROCEDURE IF EXISTS getMatrimonio;
DROP PROCEDURE IF EXISTS AddDivorcio;
DROP PROCEDURE IF EXISTS getDivorcio;
DROP PROCEDURE IF EXISTS AddLicencia;
DROP PROCEDURE IF EXISTS getLicencias;
DROP PROCEDURE IF EXISTS anularLicencia;
DROP PROCEDURE IF EXISTS renewLicencia;

DROP FUNCTION IF EXISTS getFullName;
DROP FUNCTION IF EXISTS getLastName;
DROP FUNCTION IF EXISTS getName;
DROP FUNCTION IF EXISTS onlyLetters;
DROP FUNCTION IF EXISTS getAge;
DROP FUNCTION IF EXISTS generateCUI;
DROP FUNCTION IF EXISTS dateDiffYears;

CREATE FUNCTION getFullName(solicitado INT)
RETURNS VARCHAR(120) DETERMINISTIC
RETURN (SELECT CONCAT(nombre_1, " ", nombre_2, " ", IF(nombre_3 IS NOT NULL, CONCAT(nombre_3, " "), ''), apellido_1, " ", apellido_2) FROM PERSONA WHERE cui = solicitado LIMIT 1);

CREATE FUNCTION getLastName(solicitado INT)
RETURNS VARCHAR(120) DETERMINISTIC
RETURN (SELECT CONCAT(apellido_1, " ", apellido_2) FROM PERSONA WHERE cui = solicitado LIMIT 1);

CREATE FUNCTION getName(solicitado INT)
RETURNS VARCHAR(120) DETERMINISTIC
RETURN (SELECT CONCAT(nombre_1, " ", nombre_2, " ", IF(nombre_3 IS NOT NULL, nombre_3, '')) FROM PERSONA WHERE cui = solicitado LIMIT 1);

CREATE FUNCTION onlyLetters(str VARCHAR(100)) 
RETURNS BOOLEAN DETERMINISTIC
RETURN IF(str REGEXP '^[a-zA-Záéíóú]*$', true, false);

CREATE FUNCTION dateDiffYears(inicio DATE, fin DATE)
RETURNS INT DETERMINISTIC
RETURN YEAR(fin) - YEAR(inicio) - (DATE_FORMAT(fin, '%m%d') < DATE_FORMAT(inicio, '%m%d'));

delimiter //
CREATE FUNCTION generateCUI(codigo INT)
RETURNS INT DETERMINISTIC
	BEGIN
		DECLARE max INT;
        SET max = (SELECT max(cui DIV 10000) FROM persona WHERE MOD(cui, 10000) = codigo);
        RETURN (max+1)*10000 + codigo;
    END //
delimiter ;

delimiter //
CREATE FUNCTION getAge(solicitado INT, actual DATE)
RETURNS INT DETERMINISTIC
	BEGIN
		DECLARE nac DATE;
        SET nac = (SELECT fecha FROM nacimiento WHERE cui = solicitado LIMIT 1);
        RETURN dateDiffYears(nac, actual);
    END //
delimiter ;

delimiter //
CREATE PROCEDURE ShowError (IN msg VARCHAR(200))
	BEGIN
		SELECT msg as Error;
	END //
delimiter ;

delimiter //
CREATE PROCEDURE AddNacimiento (
	IN padre INT, 
    IN madre INT, 
    IN nombre1 VARCHAR(20), 
    IN nombre2 VARCHAR(20), 
    IN nombre3 VARCHAR(20),
    IN fecha VARCHAR(15), 
    IN municipio INT, 
    IN genero CHAR(1)
)
	proc_exit:BEGIN
		DECLARE no_mun INT;
        DECLARE no_dep INT;
        DECLARE apellido1 VARCHAR(25);
        DECLARE apellido2 VARCHAR(25);
        DECLARE ffecha DATE;
        DECLARE n_cui INT;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
        SET no_mun = MOD(municipio, 100);
        SET no_dep = municipio DIV 100;
		IF nombre1 IS NULL THEN
			CALL ShowError('Primer nombre es obligatorio');
            LEAVE proc_exit;
		ELSEIF NOT onlyLetters(nombre1) THEN
			CALL ShowError('Primer nombre solo puede contener letras.');
            LEAVE proc_exit;
		ELSEIF nombre2 IS NOT NULL AND NOT onlyLetters(nombre2) THEN
			CALL ShowError('Segundo nombre solo puede contener letras.');
            LEAVE proc_exit;
		ELSEIF nombre3 IS NOT NULL AND NOT onlyLetters(nombre3) THEN
			CALL ShowError('Tercer nombre solo puede contener letras.');
            LEAVE proc_exit;
		ELSEIF padre IS NULL OR padre NOT IN (SELECT cui FROM persona) THEN
			CALL ShowError('CUI de padre no encontrado');
            LEAVE proc_exit;
		ELSEIF getAge(padre, ffecha) < 18 THEN
			CALL ShowError('Padre no puede ser menor de edad');
            LEAVE proc_exit;
		ELSEIF madre IS NULL OR madre NOT IN (SELECT cui FROM persona) THEN
			CALL ShowError('CUI de madre no encontrado');
            LEAVE proc_exit;
		ELSEIF getAge(madre, ffecha) < 18 THEN
			CALL ShowError('Madre no puede ser menor de edad');
            LEAVE proc_exit;
		ELSEIF NOT EXISTS (SELECT codigo FROM municipio WHERE codigo = no_mun AND departamento = no_dep) THEN
			CALL ShowError('Municipio no válido');
            LEAVE proc_exit;
		ELSEIF genero NOT IN ('M', 'F') THEN
			CALL ShowError('Género no válido');
            LEAVE proc_exit;
		END IF;
        SET n_cui = generateCUI(municipio);
        SET apellido1 = (SELECT apellido_1 FROM PERSONA WHERE cui = padre);
        SET apellido2 = (SELECT apellido_1 FROM PERSONA WHERE cui = madre);
        INSERT INTO PERSONA (cui, nombre_1, nombre_2, nombre_3, apellido_1, apellido_2, genero) 
        VALUES (n_cui, nombre1, nombre2, nombre3, apellido1, apellido2, genero);
        INSERT INTO NACIMIENTO (fecha, cui, padre, madre, municipio, departamento)
        VALUES (ffecha, n_cui, padre, madre, no_mun, no_dep);
        SELECT * FROM persona WHERE cui = n_cui;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getNacimiento(
	IN cui INT
) 
	proc_exit:BEGIN 
		IF cui NOT IN (SELECT n.cui FROM nacimiento n) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
		END IF;
        SELECT 
			n.no_acta as 'No. Acta',
            n.cui as CUI,
			getLastName(n.cui) as Apellidos,
            getName(n.cui) as Nombres,
            n.padre as 'DPI Padre',
            getName(padre.cui) as 'Nombres Padre',
            getLastName(padre.cui) as 'Apellidos Padre',
            n.madre as 'DPI Padre',
            getName(madre.cui) as 'Nombres Madre',
            getLastName(madre.cui) as 'Apellidos Madre',
            DATE_FORMAT(n.fecha, '%d-%m-%Y') as 'Fecha Nacimiento',
			d.nombre as Departamento,
            m.nombre as Municipio,
            p.genero as 'Género'
		FROM nacimiento n
        INNER JOIN persona p ON p.cui = n.cui
        LEFT JOIN persona padre ON padre.cui = n.padre
        LEFT JOIN persona madre ON madre.cui = n.madre
        INNER JOIN municipio m ON m.codigo = n.municipio AND m.departamento = n.departamento
        INNER JOIN departamento d ON d.codigo = n.departamento
        WHERE 
			n.cui = cui
		;
	END //
delimiter ;

delimiter //
CREATE PROCEDURE AddDefuncion(
	IN cui INT,
	IN fecha VARCHAR(15),
    IN motivo VARCHAR(100)
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
		IF cui NOT IN (SELECT p.cui FROM persona p) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
		ELSEIF cui IN (SELECT d.cui FROM defuncion d) THEN
			CALL ShowError('CUI ya cuenta con un acta de defuncion');
            LEAVE proc_exit;
		ELSEIF ffecha < (SELECT n.fecha FROM nacimiento n WHERE n.cui = cui LIMIT 1) THEN
			CALL ShowError('Fecha de defunción anterior a fecha de nacimiento');
            LEAVE proc_exit;
		END IF;
        IF cui IN (SELECT cui FROM dpi) AND (SELECT estado FROM dpi WHERE dpi.cui = cui) = 'CASADO' THEN
			IF (SELECT p.genero FROM persona p WHERE p.cui = cui LIMIT 1) = 'M' THEN
				UPDATE dpi SET estado = 'VIUDO' WHERE dpi.cui = (SELECT novia FROM matrimonio m WHERE novio = cui ORDER BY m.fecha DESC LIMIT 1);
			ELSEIF (SELECT p.genero FROM persona p WHERE p.cui = cui LIMIT 1) = 'F' THEN
				UPDATE dpi SET estado = 'VIUDO' WHERE dpi.cui = (SELECT novio FROM matrimonio m WHERE novia = cui ORDER BY m.fecha DESC LIMIT 1);
            END IF;
        END IF;
        INSERT INTO defuncion (fecha, motivo, cui)
        VALUES (ffecha, motivo, cui);
        SELECT * FROM defuncion d WHERE d.cui = cui; 
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getDefuncion(
	IN cui INT
)
	proc_exit:BEGIN
		IF cui NOT IN (SELECT cui from defuncion) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
        END IF;
        SELECT 
			d.no_acta AS 'No. Acta',
            d.cui AS CUI,
            getLastName(d.cui) AS Apellidos,
            getName(d.cui) AS Nombres,
            DATE_FORMAT(n.fecha, '%d-%m-%Y') AS 'Fecha Nacimiento',
            DATE_FORMAT(d.fecha, '%d-%m-%Y') AS 'Fecha Fallecimiento',
            dep.nombre AS 'Departamento Nacimiento',
            m.nombre AS 'Municipio Nacimiento',
            motivo AS Motivo
		FROM defuncion d
        INNER JOIN persona p ON p.cui = d.cui 
        INNER JOIN nacimiento n ON n.cui = d.cui 
        INNER JOIN municipio m ON m.codigo = n.municipio AND m.departamento = n.departamento
        INNER JOIN departamento dep ON dep.codigo = m.departamento
        WHERE d.cui = cui
        ;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE generarDPI (
	IN cui INT,
    IN fecha VARCHAR(15),
    IN municipio INT
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        DECLARE no_mun INT;
        DECLARE no_dep INT;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
        SET no_mun = MOD(municipio, 100);
        SET no_dep = municipio DIV 100;
        IF cui NOT IN (SELECT cui FROM persona) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
		ELSEIF cui IN (SELECT dpi.cui FROM dpi) THEN
			CALL ShowError('DPI ya fue generado previamente');
			LEAVE proc_exit;
		ELSEIF NOT EXISTS (SELECT codigo FROM municipio WHERE codigo = no_mun AND departamento = no_dep) THEN
			CALL ShowError('Municipio no válido');
            LEAVE proc_exit;
		ELSEIF getAge(cui, ffecha) < 18 THEN
			CALL ShowError('Edad no apta para generar DPI');
            LEAVE proc_exit;
        END IF;
        INSERT INTO dpi (fecha, municipio, departamento, cui, estado)
        VALUES (ffecha, no_mun, no_dep, cui, 'SOLTERO');
        SELECT * FROM dpi WHERE dpi.cui = cui;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getDPI (
	IN cui INT
)
	proc_exit:BEGIN
	IF cui NOT IN (SELECT dpi.cui FROM dpi) THEN
		CALL ShowError('CUI no encontrado');
		LEAVE proc_exit;
	END IF;
    SELECT
		dpi.cui AS CUI,
        getLastName(dpi.cui) AS Apellidos,
        getName(dpi.cui) AS Nombres,
        DATE_FORMAT(n.fecha, '%d-%m-%Y') AS 'Fecha Nacimiento',
        dep.nombre AS 'Departamento Nacimiento',
        m.nombre AS 'Municipio Nacimiento',
        depv.nombre AS 'Departamento Vecindad',
        mv.nombre AS 'Municipio Vecindad',
        p.genero AS 'Género',
        dpi.estado AS 'Estado Civil'
    FROM dpi
    INNER JOIN persona p ON p.cui = dpi.cui
    INNER JOIN nacimiento n ON n.cui = dpi.cui
    INNER JOIN municipio m ON m.codigo = n.municipio AND m.departamento = n.departamento
	INNER JOIN departamento dep ON dep.codigo = m.departamento
    INNER JOIN municipio mv ON mv.codigo = dpi.municipio AND mv.departamento = dpi.departamento
	INNER JOIN departamento depv ON depv.codigo = mv.departamento
    WHERE cui = dpi.cui
    ;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE AddMatrimonio(
	IN novio INT,
    IN novia INT,
    IN fecha VARCHAR(15)
) 
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
        IF novio = novia THEN
			CALL ShowError('Se debe proporcionar DPI diferentes');
            LEAVE proc_exit;
        ELSEIF novio NOT IN (SELECT cui FROM dpi) THEN
			CALL ShowError('No se encontró DPI 1');
            LEAVE proc_exit;
		ELSEIF novia NOT IN (SELECT cui FROM dpi) THEN
			CALL ShowError('No se encontró DPI 2');
            LEAVE proc_exit;
		ELSEIF getAge(novio, ffecha) < 18 THEN
			CALL ShowError('DPI 1 debe ser mayor de 18 años al momento de casarse');
            LEAVE proc_exit;
		ELSEIF getAge(novia, ffecha) < 18 THEN
			CALL ShowError('DPI 2 debe ser mayor de 18 años al momento de casarse');
            LEAVE proc_exit;
		ELSEIF 'M' <> (SELECT genero FROM persona WHERE cui = novio LIMIT 1) THEN
			CALL ShowError('DPI 1 debe pertenecer a un hombre');
            LEAVE proc_exit;
		ELSEIF 'F' <> (SELECT genero FROM persona WHERE cui = novia LIMIT 1) THEN
			CALL ShowError('DPI 2 debe pertenecer a una mujer');
            LEAVE proc_exit;
		ELSEIF (SELECT estado FROM dpi WHERE cui = novio LIMIT 1) = 'CASADO' THEN
			CALL ShowError('DPI 1 cuenta con un matrimonio vigente');
            LEAVE proc_exit;
		ELSEIF (SELECT estado FROM dpi WHERE cui = novia LIMIT 1) = 'CASADO' THEN
			CALL ShowError('DPI 2 cuenta con un matrimonio vigente');
            LEAVE proc_exit;
        END IF;
		INSERT INTO matrimonio (fecha, novio, novia)
        VALUES (ffecha, novio, novia);
        UPDATE DPI SET estado = 'CASADO' WHERE cui IN (novio, novia);
        SELECT * FROM matrimonio m WHERE m.novio = novio ORDER BY no_acta DESC LIMIT 1;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getMatrimonio(
	IN acta INT
)
	proc_exit:BEGIN
		IF acta NOT IN (SELECT no_acta FROM matrimonio) THEN
			CALL ShowError('Acta de matrimonio no encontrada');
            LEAVE proc_exit;
        END IF;
        SELECT 
			m.no_acta AS 'No. Matrimonio',
            m.novio AS 'DPI Hombre',
            getFullName(m.novio) AS 'Nombre Hombre',
            m.novia AS 'DPI Mujer',
            getFullName(m.novia) AS 'Nombre Mujer',
            DATE_FORMAT(m.fecha, '%d-%m-%Y') AS Fecha
		FROM matrimonio m
        WHERE no_acta = acta
        ;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE AddDivorcio (
	IN acta INT,
    IN fecha VARCHAR(15)
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
        IF acta NOT IN (SELECT no_acta FROM matrimonio) THEN
			CALL ShowError('Acta de matrimonio no existe');
            LEAVE proc_exit;
		ELSEIF acta IN (SELECT matrimonio FROM divorcio) THEN
			CALL ShowError('Matrimonio no se encuentra vigente');
            LEAVE proc_exit;
		ELSEIF ffecha < (SELECT fecha FROM matrimonio WHERE no_acta = acta LIMIT 1) THEN
			CALL ShowError('Fecha de divorcio no es posterior a fecha de matrimonio');
            LEAVE proc_exit;
        END IF;
        INSERT INTO divorcio (fecha, matrimonio)
        VALUES (ffecha, acta);
        UPDATE dpi SET estado = 'DIVORCIADO' WHERE cui = (SELECT novio FROM matrimonio WHERE no_acta = acta LIMIT 1);
        UPDATE dpi SET estado = 'DIVORCIADO' WHERE cui = (SELECT novia FROM matrimonio WHERE no_acta = acta LIMIT 1);
        SELECT * FROM divorcio WHERE matrimonio = acta;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getDivorcio(
	acta INT
)
	proc_exit:BEGIN
		IF NOT EXISTS (SELECT no_acta FROM divorcio WHERE no_acta = acta) THEN
			CALL ShowError('Acta de divorcio no encontrada');
            LEAVE proc_exit;
        END IF;
        SELECT 
			d.no_acta AS 'No. Divorcio',
            m.novio AS 'DPI Hombre',
            getFullName(m.novio) AS 'Nombre Hombre',
            m.novia AS 'DPI Mujer',
            getFullName(m.novia) AS 'Nombre Mujer',
            DATE_FORMAT(d.fecha, '%d-%m-%Y') AS 'Fecha'
		FROM divorcio d
        INNER JOIN matrimonio m ON d.matrimonio = m.no_acta
        WHERE d.no_acta = acta
        ;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE AddLicencia(
	IN cui INT,
    IN fecha VARCHAR(15),
    IN tipo CHAR(1)
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
		IF tipo NOT IN ('E','C','M') THEN
			CALL ShowError('Tipo no válido para primera licencia');
            LEAVE proc_exit;
		ELSEIF cui NOT IN (SELECT cui FROM persona) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
		ELSEIF getAge(cui, ffecha) < 16 THEN
			CALL ShowError('Edad insuficiente para solicitar licencia');
            LEAVE proc_exit;
		ELSEIF tipo IN ('C','M') AND EXISTS (SELECT numero FROM licencia l WHERE l.tipo <> 'E' AND l.cui = cui) THEN
			CALL ShowError('Ya se emitió una licencia con este CUI');
            LEAVE proc_exit;
		ELSEIF tipo = 'E' AND EXISTS (SELECT numero FROM licencia l WHERE l.tipo = 'E' AND l.cui = cui) THEN
			CALL ShowError('Ya se emitió una licencia tipo E con este CUI');
            LEAVE proc_exit;
        END IF;
        INSERT INTO licencia (fecha, vencimiento, cui, tipo) 
        VALUES (ffecha, DATE_ADD(ffecha, INTERVAL 1 YEAR), cui, tipo);
        SELECT * FROM licencia l WHERE l.cui = cui AND l.tipo = tipo;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE getLicencias(
	IN cui INT
)
	proc_exit:BEGIN
		IF cui NOT IN (SELECT cui FROM PERSONA) THEN
			CALL ShowError('CUI no encontrado');
            LEAVE proc_exit;
        END IF;
        SELECT 
			l.numero AS 'No. Licencia',
            getName(cui) AS Nombres,
            getLastName(cui) AS Apellidos,
            DATE_FORMAT(l.fecha, '%d-%m-%Y') AS 'Fecha Emisión',
            DATE_FORMAT(l.vencimiento, '%d-%m-%Y') AS 'Fecha Vencimiento',
            l.tipo AS Tipo
		FROM licencia l
		INNER JOIN persona p ON p.cui = l.cui
        WHERE l.cui = cui
        ;
    END //
delimiter ;

delimiter //
CREATE PROCEDURE anularLicencia(
	IN licencia INT,
    IN fecha VARCHAR(15),
    IN motivo VARCHAR(200)
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        DECLARE vencimiento DATE;
        DECLARE prev_null DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
        SET vencimiento = DATE_ADD(ffecha, INTERVAL 2 YEAR);
        SET prev_null = (SELECT a.vencimiento FROM anulacion a WHERE a.licencia = licencia ORDER BY a.numero DESC LIMIT 1);
		IF licencia NOT IN (SELECT numero FROM licencia) THEN
			CALL ShowError('Licencia no encontrada');
            LEAVE proc_exit;
		ELSEIF (SELECT fecha FROM licencia l WHERE l.numero = licencia LIMIT 1) < fecha THEN
			CALL ShowError('Fecha de anulación debe ser posterior a la fecha de emisión');
            LEAVE proc_exit;
		ELSEIF prev_null IS NOT NULL AND prev_null >= ffecha THEN
			SET vencimiento = DATE_ADD(vencimiento, INTERVAL 2 YEAR);
        END IF;
        INSERT INTO anulacion (fecha, licencia, motivo, vencimiento)
        VALUES (ffecha, licencia, motivo, vencimiento);
        SELECT * FROM anulacion a WHERE a.licencia = licencia ORDER BY a.numero DESC LIMIT 1; 
    END //
delimiter ;

delimiter //
CREATE PROCEDURE renewLicencia(
	IN licencia INT,
    IN fecha VARCHAR(15),
    IN tipo CHAR(1)
)
	proc_exit:BEGIN
		DECLARE ffecha DATE;
        DECLARE tipo_ant CHAR(1);
        DECLARE fecha_emision DATE;
        DECLARE prev_vencimiento DATE;
        DECLARE n_vencimiento DATE;
        SET ffecha = STR_TO_DATE(fecha, '%d-%m-%Y');
		IF licencia NOT IN (SELECT numero FROM licencia) THEN
			CALL ShowError('Licencia no encontrada');
            LEAVE proc_exit;
		ELSEIF (SELECT fecha FROM licencia l WHERE l.numero = licencia LIMIT 1) < fecha THEN
			CALL ShowError('Fecha de renovación debe ser posterior a la fecha de emisión');
            LEAVE proc_exit;
		ELSEIF (SELECT a.vencimiento FROM anulacion a WHERE a.licencia = licencia ORDER BY a.numero DESC LIMIT 1) >= ffecha THEN
			CALL ShowError('Licencia se encuentra anulada');
            LEAVE proc_exit;
        END IF;
        SET tipo_ant = (SELECT l.tipo FROM licencia l WHERE l.numero = licencia LIMIT 1);
        SET fecha_emision = (SELECT l.fecha FROM licencia l WHERE l.numero = licencia LIMIT 1);
        IF tipo = 'A' THEN
			IF tipo_ant NOT IN ('A', 'B', 'C') THEN
				CALL ShowError('Licencia no apta para tipo de renovación');
				LEAVE proc_exit;
			ELSEIF tipo_ant IN ('B', 'C') THEN
				IF getAge((SELECT l.cui FROM licencia l WHERE l.numero = licencia LIMIT 1), ffecha) < 25 THEN
					CALL ShowError('Licencia no apta para menores de 25 años');
					LEAVE proc_exit;
                ELSEIF(dateDiffYears(fecha_emision, ffecha)<3) THEN
					CALL ShowError('Se debe haber tenido licencia tipo B o C por más de 3 años');
					LEAVE proc_exit;
                END IF;
            END IF;
		ELSEIF tipo = 'B' THEN
			IF tipo_ant NOT IN ('A', 'B', 'C') THEN
				CALL ShowError('Licencia no apta para tipo de renovación');
				LEAVE proc_exit;
			ELSEIF tipo_ant = 'C' THEN
				IF getAge((SELECT l.cui FROM licencia l WHERE l.numero = licencia LIMIT 1), ffecha) < 23 THEN
					CALL ShowError('Licencia no apta para menores de 23 años');
					LEAVE proc_exit;
                ELSEIF(dateDiffYears(fecha_emision, ffecha)<2) THEN
					CALL ShowError('Se debe haber tenido licencia tipo C por más de 2 años');
					LEAVE proc_exit;
                END IF;
            END IF;
		ELSEIF tipo = 'C' AND tipo_ant NOT IN ('A','B','C') THEN
			CALL ShowError('Licencia no apta para tipo de renovación');
			LEAVE proc_exit;
		ELSEIF tipo IN ('M','E') AND tipo_ant <> tipo THEN
			CALL ShowError('Licencia no apta para tipo de renovación');
			LEAVE proc_exit;
        END IF;
        SET prev_vencimiento = (SELECT l.vencimiento FROM licencia l WHERE l.numero = licencia LIMIT 1);
        SET n_vencimiento = IF(
				ffecha > prev_vencimiento, 
                DATE_ADD(l.vencimiento, INTERVAL 1 YEAR), 
                DATE_ADD(prev_vencimiento, INTERVAL 1 YEAR)
			);
        UPDATE licencia l SET 
			l.vencimiento = n_vencimiento,  
			l.tipo = tipo
		WHERE l.numero = licencia;
        INSERT INTO RENOVACION (fecha, tipo, licencia, vencimiento)
        VALUES (ffecha, tipo, licencia, n_vencimiento);
        SELECT * FROM renovacion r WHERE r.licencia = licencia ORDER BY r.numero DESC LIMIT 1;
    END //
delimiter ;