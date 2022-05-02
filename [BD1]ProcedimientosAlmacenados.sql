DROP PROCEDURE IF EXISTS AddNacimiento;
DROP PROCEDURE IF EXISTS ShowError;
DROP PROCEDURE IF EXISTS getNacimiento;
DROP PROCEDURE IF EXISTS AddDefuncion;
DROP PROCEDURE IF EXISTS getDefuncion;
DROP PROCEDURE IF EXISTS generarDPI;
DROP PROCEDURE IF EXISTS getDPI;
DROP PROCEDURE IF EXISTS AddMatrimonio;
DROP PROCEDURE IF EXISTS getMatrimonio;

DROP FUNCTION IF EXISTS getFullName;
DROP FUNCTION IF EXISTS getLastName;
DROP FUNCTION IF EXISTS getName;
DROP FUNCTION IF EXISTS onlyLetters;
DROP FUNCTION IF EXISTS getAge;
DROP FUNCTION IF EXISTS generateCUI;


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
CREATE FUNCTION getAge(solicitado INT)
RETURNS INT DETERMINISTIC
	BEGIN
		DECLARE nac DATE;
        SET nac = (SELECT fecha FROM nacimiento WHERE cui = solicitado LIMIT 1);
        RETURN YEAR(now()) - YEAR(nac) - (DATE_FORMAT(now(), '%m%d') < DATE_FORMAT(nac, '%m%d'));
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
        DECLARE n_cui INT;
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
		ELSEIF getAge(padre) < 18 THEN
			CALL ShowError('Padre no puede ser menor de edad');
            LEAVE proc_exit;
		ELSEIF madre IS NULL OR madre NOT IN (SELECT cui FROM persona) THEN
			CALL ShowError('CUI de madre no encontrado');
            LEAVE proc_exit;
		ELSEIF getAge(madre) < 18 THEN
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
        VALUES (STR_TO_DATE(fecha, '%d-%m-%Y'), n_cui, padre, madre, no_mun, no_dep);
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
		ELSEIF getAge(cui) < 18 THEN
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
        p.genero AS 'Género'
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
        DECLARE novio_ant INT;
        DECLARE novia_ant INT;
        DECLARE div_novio DATE;
        DECLARE div_novia DATE;
        SET novio_ant = (SELECT m.no_acta FROM matrimonio m WHERE m.novio = novio ORDER BY fecha DESC LIMIT 1);
        SET novia_ant = (SELECT m.no_acta FROM matrimonio m WHERE m.novia = novia ORDER BY fecha DESC LIMIT 1);
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
		ELSEIF 'M' <> (SELECT genero FROM persona WHERE cui = novio LIMIT 1) THEN
			CALL ShowError('DPI 1 debe pertenecer a un hombre');
            LEAVE proc_exit;
		ELSEIF 'F' <> (SELECT genero FROM persona WHERE cui = novia LIMIT 1) THEN
			CALL ShowError('DPI 2 debe pertenecer a una mujer');
            LEAVE proc_exit;
		ELSEIF novio_ant IS NOT NULL THEN
			SET div_novio = (SELECT fecha FROM divorcio WHERE matrimonio = novio_ant LIMIT 1); 
			IF div_novio IS NULL OR div_novio > ffecha THEN
				CALL ShowError('DPI 1 cuenta con un matrimonio vigente');
                LEAVE proc_exit;
            END IF;
		ELSEIF novia_ant IS NOT NULL THEN
			SET div_novia = (SELECT fecha FROM divorcio WHERE matrimonio = novia_ant LIMIT 1); 
			IF div_novia IS NULL OR div_novia > ffecha THEN
				CALL ShowError('DPI 2 cuenta con un matrimonio vigente');
                LEAVE proc_exit;
            END IF;
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

/*CALL AddNacimiento(10101, 10102, 'Kenneth', 'Haroldo', NULL, '21-09-2000', 0101, 'M');
CALL AddNacimiento(10101, 10102, 'Cynthia', 'María', NULL, '17-02-2006', 0101, 'F');
CALL getNacimiento(20101);
CALL AddDefuncion(40101, '28-06-2048', 'Paro cardíaco');
CALL getDefuncion(30101);
CALL generarDPI(20101, '02-05-2022', 0102);
CALL generarDPI(10101, '02-05-2022', 0102);
CALL generarDPI(10102, '02-05-2022', 0102);
CALL generarDPI(30101, '02-05-2022', 0102);
CALL generarDPI(40101, '02-05-2022', 0102);
CALL getDPI(20101);
CALL AddMatrimonio(10101, 10102, '02-11-1998');
CALL getMatrimonio(1); */
