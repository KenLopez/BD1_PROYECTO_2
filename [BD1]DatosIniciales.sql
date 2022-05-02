INSERT INTO PERSONA (
	cui,
    nombre_1,
    nombre_2,
    nombre_3,
    apellido_1,
    apellido_2,
    genero
) VALUES (10101,'Rafael','Haroldo',NULL,'López','García','M'),
    (10102,'Gilmery','Adalia',NULL,'López','Carías','F'),
    (20101,'Katherine','Andrea','Sofía','González','Pérez','F')
;

INSERT INTO NACIMIENTO (
	fecha,
    cui,
    padre,
    madre,
    municipio,
    departamento
) VALUES ('1974-02-16', 10101, NULL, NULL, 1, 1),
	('1973-11-03', 10102, NULL, NULL, 2, 1),
	('2001-08-24', 40101, NULL, NULL, 1, 1)
;