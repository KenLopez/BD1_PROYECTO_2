USE PROYECTO_2;

CREATE TABLE IF NOT EXISTS TEMP_DEP (
	CODIGO_DEPARTAMENTO VARCHAR(10),
    NOMBRE_DEPARTAMENTO VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS TEMP_MUN (
	CODIGO_MUNICIPIO VARCHAR(10),
    NOMBRE_MUNICIPIO VARCHAR(50),
    CODIGO_DEPARTAMENTO VARCHAR(10)
);

LOAD DATA INFILE 'departamentos.csv'
INTO TABLE TEMP_DEP
COLUMNS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE 'municipios.csv'
INTO TABLE TEMP_MUN
COLUMNS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT INTO DEPARTAMENTO (
	codigo,
    nombre
) SELECT DISTINCT 
	CODIGO_DEPARTAMENTO, 
    NOMBRE_DEPARTAMENTO
FROM TEMP_DEP;

INSERT INTO MUNICIPIO (
	codigo,
    nombre,
    departamento
) SELECT DISTINCT
	MOD(CODIGO_MUNICIPIO, 100),
    NOMBRE_MUNICIPIO,
    CODIGO_DEPARTAMENTO
FROM TEMP_MUN;

DROP TABLE IF EXISTS TEMP_DEP;
DROP TABLE IF EXISTS TEMP_MUN;