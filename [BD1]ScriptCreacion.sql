CREATE DATABASE IF NOT EXISTS PROYECTO_2;
USE PROYECTO_2;

DROP TABLE IF EXISTS DEFUNCION;
DROP TABLE IF EXISTS ANULACION;
DROP TABLE IF EXISTS RENOVACION;
DROP TABLE IF EXISTS LICENCIA;
DROP TABLE IF EXISTS NACIMIENTO;
DROP TABLE IF EXISTS DIVORCIO;
DROP TABLE IF EXISTS MATRIMONIO;
DROP TABLE IF EXISTS DPI;
DROP TABLE IF EXISTS PERSONA;
DROP TABLE IF EXISTS MUNICIPIO;
DROP TABLE IF EXISTS DEPARTAMENTO;

CREATE TABLE IF NOT EXISTS DEPARTAMENTO (
	codigo INT(2) ZEROFILL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS MUNICIPIO (
	codigo INT(2) ZEROFILL,
    nombre VARCHAR(30) NOT NULL,
    departamento INT(2) ZEROFILL,
    FOREIGN KEY (departamento) REFERENCES DEPARTAMENTO(codigo) ON DELETE CASCADE,
    PRIMARY KEY (codigo, departamento)
);

CREATE TABLE IF NOT EXISTS PERSONA (
	cui INT(13) ZEROFILL PRIMARY KEY,
    nombre_1 VARCHAR(20) NOT NULL,
    nombre_2 VARCHAR(20),
    nombre_3 VARCHAR(20),
    apellido_1 VARCHAR(25) NOT NULL,
    apellido_2 VARCHAR(25),
    genero CHAR(1) NOT NULL,
    CONSTRAINT CHECKGENDER CHECK (genero in ('M','F')),
    CONSTRAINT LETRASN1 CHECK (nombre_1 REGEXP '^[a-zA-Záéíóú]*$'),
    CONSTRAINT LETRASN2 CHECK (nombre_2 REGEXP '^[a-zA-Záéíóú]*$'),
    CONSTRAINT LETRASN3 CHECK (nombre_3 REGEXP '^[a-zA-Záéíóú]*$'),
    CONSTRAINT LETRASA1 CHECK (apellido_1 REGEXP '^[a-zA-Záéíóú]*$'),
    CONSTRAINT LETRASA2 CHECK (apellido_2 REGEXP '^[a-zA-Záéíóú]*$')
);

CREATE TABLE IF NOT EXISTS DEFUNCION (
	no_acta INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    motivo VARCHAR(200),
    cui INT(13) ZEROFILL NOT NULL UNIQUE,
    FOREIGN KEY (cui) REFERENCES PERSONA(cui) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS LICENCIA (
	numero INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    vencimiento DATE,
    cui INT(13) ZEROFILL NOT NULL,
    FOREIGN KEY (cui) REFERENCES PERSONA(cui) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ANULACION (
	numero INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    licencia INTEGER NOT NULL,
    FOREIGN KEY (licencia) REFERENCES LICENCIA(numero) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS RENOVACION (
	numero INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    tipo CHAR(1) NOT NULL,
    licencia INTEGER NOT NULL,
    FOREIGN KEY (licencia) REFERENCES LICENCIA(numero) ON DELETE CASCADE,
    CONSTRAINT TYPECHECK CHECK (tipo IN ('A','B','C','M','E'))
);

CREATE TABLE IF NOT EXISTS NACIMIENTO (
	no_acta INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    cui INT(13) ZEROFILL NOT NULL,
    madre INT(13) ZEROFILL,
    padre INT(13) ZEROFILL,
    municipio INT(2) ZEROFILL NOT NULL,
    departamento INT(2) ZEROFILL NOT NULL,
    FOREIGN KEY (cui) REFERENCES PERSONA(cui) ON DELETE CASCADE,
    FOREIGN KEY (padre) REFERENCES PERSONA(cui) ON DELETE CASCADE,
    FOREIGN KEY (madre) REFERENCES PERSONA(cui) ON DELETE CASCADE,
    FOREIGN KEY (municipio) REFERENCES MUNICIPIO(codigo) ON DELETE CASCADE,
    FOREIGN KEY (departamento) REFERENCES MUNICIPIO(departamento) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS DPI (
	fecha DATE NOT NULL,
    municipio INT(2) ZEROFILL NOT NULL,
    departamento INT(2) ZEROFILL NOT NULL,
    cui INT(13) ZEROFILL,
    estado VARCHAR(10) NOT NULL,
    FOREIGN KEY (municipio) REFERENCES MUNICIPIO(codigo) ON DELETE CASCADE,
    FOREIGN KEY (departamento) REFERENCES MUNICIPIO(departamento) ON DELETE CASCADE,
    FOREIGN KEY (cui) REFERENCES PERSONA(cui) ON DELETE CASCADE,
    PRIMARY KEY (cui)
);

CREATE TABLE IF NOT EXISTS MATRIMONIO (
	no_acta INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    novio INT(13) ZEROFILL NOT NULL,
    novia INT(13) ZEROFILL NOT NULL,
    FOREIGN KEY (novio) REFERENCES PERSONA(cui) ON DELETE CASCADE,
    FOREIGN KEY (novia) REFERENCES PERSONA(cui) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS DIVORCIO (
	no_acta INTEGER PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    matrimonio INTEGER NOT NULL,
    FOREIGN KEY (matrimonio) REFERENCES MATRIMONIO(no_acta) ON DELETE CASCADE
);