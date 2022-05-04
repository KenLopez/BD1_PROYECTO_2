INSERT INTO PERSONA (
	cui,
    nombre_1,
    nombre_2,
    nombre_3,
    apellido_1,
    apellido_2,
    genero
) VALUES (10101,'Rafael','Haroldo',NULL,'López','García','M'),
    (20101,'Gilmery','Adalia',NULL,'López','Carías','F'),
    (30101,'Raúl','Estuardo',NULL,'López','Carías','M'),
    (40101,'Mynor','Adolfo',NULL,'López','García','M'),
    (50101,'Mariela',NULL, NULL,'González','Pérez','F'),
    (10114,'Marbely',NULL,NULL,'Barrios','Pérez','F'),
    (12101,'Daniel','José','Emilio','Castillo','Fuentes','M'),
    (11802,'Carla',NULL,NULL,'Paz','Alvarado','F'),
    (12202,'Héctor','Andrés',NULL,'Roca','Monzón','M'),
    (11901,'Natalia','Sofía',NULL,'Castro','Jolón','F'),
    (11601,'Mario', NULL,NULL,'Rodríguez','González','M'),
    (11413,'Fernanda','Lucía',NULL,'Rivera','Castillo','F'),
    (11215,'Pedro',NULL,NULL,'López','Corado','M'),
    (10801,'Claudia','Flor','Luz','Solórzano','García','F'),
    (10701,'Eduardo','José',NULL,'Gutiérrez','Ralón','M'),
    (10601,'Emily','Rubí',NULL,'Contreras','Figueroa','F'),
    (10511,'Carlos','Andrés',NULL,'Moreno','Mejía','M'),
    (10501,'Cynthia','María',NULL,'Alvarado','Fernández','F'),
    (10301,'Javier','Roberto',NULL,'Girón','Torres','M'),
    (10116,'Margarita','Cecilia',NULL,'Andrade','Choc','F')
;

INSERT INTO NACIMIENTO (
	fecha,
    cui,
    padre,
    madre,
    municipio,
    departamento
) VALUES ('1974-02-16', 10101, NULL, NULL, 1, 1),
	('1973-11-03', 20101, NULL, NULL, 1, 1),
    ('1981-03-25', 30101, NULL, NULL, 1, 1),
	('1994-05-05', 40101, NULL, NULL, 1, 1),
    ('1997-10-01', 50101, NULL, NULL, 1, 1),
    ('1987-09-07', 10114, NULL, NULL, 1, 14),
    ('1982-01-13', 12101, NULL, NULL, 21, 1),
    ('1979-04-14', 11802, NULL, NULL, 18, 2),
    ('1991-05-28', 12202, NULL, NULL, 22, 2),
    ('1994-08-21', 11901, NULL, NULL, 19, 1),
    ('1976-09-01', 11601, NULL, NULL, 16, 1),
    ('1982-12-06', 11413, NULL, NULL, 14, 13),
    ('1994-04-29', 11215, NULL, NULL, 12, 15),
    ('1978-02-18', 10801, NULL, NULL, 8, 1),
    ('1974-03-10', 10701, NULL, NULL, 7, 1),
    ('1973-01-11', 10601, NULL, NULL, 6, 1),
    ('1981-04-20', 10511, NULL, NULL, 5, 11),
    ('1994-07-25', 10501, NULL, NULL, 5, 1),
    ('1988-09-09', 10301, NULL, NULL, 3, 1),
    ('1999-02-14', 10116, NULL, NULL, 1, 16)
;

CALL generarDPI(10101, '02-05-2022', 0101);
CALL generarDPI(20101, '02-05-2022', 0101);
CALL generarDPI(30101, '02-05-2022', 0101);
CALL generarDPI(40101, '02-05-2022', 0101);
CALL generarDPI(50101, '02-05-2022', 0101);
CALL generarDPI(10114, '02-05-2022', 0101);
CALL generarDPI(12101, '02-05-2022', 0101);
CALL generarDPI(11802, '02-05-2022', 0101);
CALL generarDPI(12202, '02-05-2022', 0101);
CALL generarDPI(11901, '02-05-2022', 0101);
CALL generarDPI(11601, '02-05-2022', 0101);
CALL generarDPI(11413, '02-05-2022', 0101);
CALL generarDPI(11215, '02-05-2022', 0101);
CALL generarDPI(10801, '02-05-2022', 0101);
CALL generarDPI(10701, '02-05-2022', 0101);
CALL generarDPI(10601, '02-05-2022', 0101);
CALL generarDPI(10511, '02-05-2022', 0101);
CALL generarDPI(10501, '02-05-2022', 0101);
CALL generarDPI(10301, '02-05-2022', 0101);
CALL generarDPI(10116, '02-05-2022', 0101);

CALL addMatrimonio(10101, 20101, '24-03-2020');
CALL addMatrimonio(40101, 10114, '13-11-2020');
CALL addMatrimonio(12101, 11802, '20-05-2020');
CALL addMatrimonio(12202, 11901, '04-03-2020');
CALL addMatrimonio(11601, 11413, '08-02-2020');
CALL addMatrimonio(11215, 10801, '06-01-2020');
CALL addMatrimonio(10701, 10601, '07-08-2020');
CALL addMatrimonio(10511, 10501, '04-07-2020');
CALL addMatrimonio(10301, 10116, '06-09-2020');
CALL addMatrimonio(30101, 50101, '01-10-2020');

CALL AddDivorcio(6, '29-10-2021');
CALL AddDivorcio(7, '25-09-2021');
CALL AddDivorcio(8, '24-02-2021');
CALL AddDivorcio(9, '17-03-2021');
CALL AddDivorcio(10, '02-01-2021');

CALL AddDefuncion(10501, '21-01-2050', 'Paro cardíaco');
CALL AddDefuncion(10116, '13-05-2034', 'Cáncer de pulmón');
CALL AddDefuncion(11901, '05-11-2055', 'Ahogado');
CALL AddDefuncion(50101, '17-01-2049', 'Disparo al corazón');
CALL AddDefuncion(10116, '13-10-2052', 'Accidente automovilístico');

CALL AddLicencia(10101, '05-01-2016', 'C');
CALL AddLicencia(12101, '08-04-2010', 'M');
CALL AddLicencia(10101, '15-01-2008', 'E');
CALL AddLicencia(10511, '12-08-2012', 'C');
CALL AddLicencia(10511, '01-10-2015', 'E');
CALL AddLicencia(20101, '05-01-2016', 'C');
CALL AddLicencia(20101, '15-01-2004', 'E');
CALL AddLicencia(10801, '12-08-2010', 'C');
CALL AddLicencia(10116, '01-10-2018', 'M');
CALL AddLicencia(11901, '08-04-2011', 'M');

