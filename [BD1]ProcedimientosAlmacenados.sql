DROP PROCEDURE IF EXISTS AddNacimiento;
DROP PROCEDURE IF EXISTS ShowError;
DROP PROCEDURE IF EXISTS getNacimiento;
DROP PROCEDURE IF EXISTS AddDefuncion;
DROP PROCEDURE IF EXISTS getDefuncion;

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
	cui INT,
	fecha VARCHAR(15),
    motivo VARCHAR(100)
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
	cui INT
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
        ;
    END //
delimiter ;

CALL AddNacimiento(10101, 10102, 'Kenneth', 'Haroldo', NULL, '21-09-2000', 0101, 'M');
CALL AddNacimiento(10101, 10102, 'Cynthia', 'María', NULL, '17-02-2006', 0101, 'F');
CALL getNacimiento(20101);
CALL addDefuncion(30101, '28-06-2048', 'Paro cardíaco');
CALL getDefuncion(30101);