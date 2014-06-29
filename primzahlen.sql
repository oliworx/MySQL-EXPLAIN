-- Primzahlen bis 100 Mio. berechnen (Linux-Konsole)
-- # primes 1 10000000 > /tmp/primes
-- # sudo chown mysql:mysql /tmp/primes
-- # mysql -u root -p

DROP DATABASE IF EXISTS primetest;
CREATE DATABASE primetest;
USE primetest;

CREATE TABLE big (
	p INT NOT NULL
);
CREATE TABLE small (
	q INT NOT NULL
);

LOAD DATA INFILE "/tmp/primes" into table big;
>Query OK, 5761455 rows affected (49,15 sec)
>Records: 5761455  Deleted: 0  Skipped: 0  Warnings: 0

insert into small values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
  (11),(12),(13),(14),(15),(16),(17),(18),(19),(20);

-- Einfache SELECT-Abfragen mit einer Tabelle
-- kleine natürliche Zahlen:
select q from small where q < 10;
+---+
| q |
+---+
| 1 |
| 2 |
| 3 |
| 4 |
| 5 |
| 6 |
| 7 |
| 8 |
| 9 |
+---+
9 rows in set (0,00 sec)

-- QEP anzeigen:
mysql> explain select q from small where q < 10;
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | small | ALL  | NULL          | NULL | NULL    | NULL |   20 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0,00 sec)


--kleine Primzahlen:
mysql> select p from big where p < 10;
+---+
| p |
+---+
| 2 |
| 3 |
| 5 |
| 7 |
+---+
4 rows in set (2,59 sec)


-- QEP anzeigen
mysql> explain select p from big where p < 10;
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | big   | ALL  | NULL          | NULL | NULL    | NULL | 5751080 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0,00 sec)

-- grosse Primzahlen:
mysql> select p from big where p > 99999900;
+----------+
| p        |
+----------+
| 99999931 |
| 99999941 |
| 99999959 |
| 99999971 |
| 99999989 |
+----------+
5 rows in set (2,52 sec)

-- QEP ist der gleiche wie bei kleinen Primzahlen
mysql> explain select p from big where p > 99999900;
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | big   | ALL  | NULL          | NULL | NULL    | NULL | 5751080 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0,00 sec)


-- komplexere SELECT-Abfragen mit mehreren Tabellen
-- Tabelle mit Worten anlegen
mysql> CREATE TABLE words ( 
	id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
	word VARCHAR(60) ) ENGINE=InnoDB; 
Query OK, 0 rows affected (0,81 sec)

-- deutsche Worte in die Tabelle laden
mysql> LOAD DATA LOCAL INFILE '/usr/share/dict/ngerman' INTO TABLE words (word);
Query OK, 339099 rows affected (6,58 sec)
Records: 339099  Deleted: 0  Skipped: 0  Warnings: 0

-- die 5 letzten Wörter auswählen
mysql> select word from words order by word desc limit 5;
+-----------+
| word      |
+-----------+
| zzgl      |
| Zysten    |
| Zyste     |
| Zypressen |
| Zypresse  |
+-----------+
5 rows in set (0,20 sec)

mysql> explain select word from words order by word desc limit 5;
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows   | Extra          |
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------+
|  1 | SIMPLE      | words | ALL  | NULL          | NULL | NULL    | NULL | 341202 | Using filesort |
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------+
1 row in set (0,00 sec)

-- die ersten 5 "Prim-Worte"
mysql> SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+--------+---------------+
| p      | word          |
+--------+---------------+
|     29 | Aachener      |
|     31 | Aachenerinnen |
| 113647 | aale          |
| 113657 | aalglattem    |
|     37 | Aargau        |
+--------+---------------+
5 rows in set (22,67 sec)


mysql> EXPLAIN SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+----+-------------+-------+--------+---------------+---------+---------+-----------------+---------+---------------------------------+
| id | select_type | table | type   | possible_keys | key     | key_len | ref             | rows    | Extra                           |
+----+-------------+-------+--------+---------------+---------+---------+-----------------+---------+---------------------------------+
|  1 | SIMPLE      | big   | ALL    | NULL          | NULL    | NULL    | NULL            | 5672186 | Using temporary; Using filesort |
|  1 | SIMPLE      | words | eq_ref | PRIMARY       | PRIMARY | 4       | primetest.big.p |       1 | Using where                     |
+----+-------------+-------+--------+---------------+---------+---------+-----------------+---------+---------------------------------+
2 rows in set (0,00 sec)

-- Index anlegen:
mysql> ALTER TABLE big ADD UNIQUE INDEX IX_P USING BTREE (p ASC);
Query OK, 0 rows affected (48,53 sec)
Records: 0  Duplicates: 0  Warnings: 0

-- wieder Primworte abfragen:
mysql> SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+--------+---------------+
| p      | word          |
+--------+---------------+
|     29 | Aachener      |
|     31 | Aachenerinnen |
| 113647 | aale          |
| 113657 | aalglattem    |
|     37 | Aargau        |
+--------+---------------+
5 rows in set (0,46 sec)


mysql> EXPLAIN SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+----+-------------+-------+--------+---------------+------+---------+--------------------+--------+--------------------------+
| id | select_type | table | type   | possible_keys | key  | key_len | ref                | rows   | Extra                    |
+----+-------------+-------+--------+---------------+------+---------+--------------------+--------+--------------------------+
|  1 | SIMPLE      | words | ALL    | PRIMARY       | NULL | NULL    | NULL               | 341202 | Using filesort           |
|  1 | SIMPLE      | big   | eq_ref | IX_P          | IX_P | 4       | primetest.words.id |      1 | Using where; Using index |
+----+-------------+-------+--------+---------------+------+---------+--------------------+--------+--------------------------+
2 rows in set (0,00 sec)

-- In Tabelle Words einen weiteren Index anlegen:
mysql> ALTER TABLE words ADD INDEX IX_WORD USING BTREE (word ASC);
Query OK, 0 rows affected (2,06 sec)
Records: 0  Duplicates: 0  Warnings: 0

-- wieder Primworte abfragen:
mysql> SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+--------+---------------+
| p      | word          |
+--------+---------------+
|     29 | Aachener      |
|     31 | Aachenerinnen |
| 113647 | aale          |
| 113657 | aalglattem    |
|     37 | Aargau        |
+--------+---------------+
5 rows in set (0,00 sec)

mysql> EXPLAIN SELECT p,word FROM words, big WHERE p=id ORDER BY word LIMIT 5;
+----+-------------+-------+--------+---------------+---------+---------+--------------------+------+--------------------------+
| id | select_type | table | type   | possible_keys | key     | key_len | ref                | rows | Extra                    |
+----+-------------+-------+--------+---------------+---------+---------+--------------------+------+--------------------------+
|  1 | SIMPLE      | words | index  | PRIMARY       | IX_WORD | 63      | NULL               |    5 | Using index              |
|  1 | SIMPLE      | big   | eq_ref | IX_P          | IX_P    | 4       | primetest.words.id |    1 | Using where; Using index |
+----+-------------+-------+--------+---------------+---------+---------+--------------------+------+--------------------------+
2 rows in set (0,00 sec)



-- alle kleinen Primzahlen
explain select q   from small,  big where small.q=big.p; -- 1,69 sec 1,7 sec 1,59 sec, 1,89 sec
explain select q from small,   big where big.p=small.q; -- 2,04 sec 2,13 sec 2,18 Sek
-- explain 
select p,q from small,  big where big.p=small.q; -- 1,62 sec 1,766 sec 1,54 sec

-- Ein paar Primzahlen aus der Mitte
-- explain
select p,'' from big where p between 5000000 and 5000100; -- 0,528 sec

-- Index anlegen ohne UNIQUE
ALTER TABLE `primetest`.`big` 
ADD INDEX `IX_P1` USING BTREE (`p` ASC);

-- alle kleinen Primzahlen
explain select q    from small,   big where small.q=big.p; -- 0,001 sec
explain select q   from small,   big where big.p=small.q; -- 0,001 sec
-- explain 
select p,  q from small,  big where big.p=small.q; -- 0,001 sec

-- Ein paar Primzahlen aus der Mitte
-- Bemerkung: ,'' wegen http://bugs.mysql.com/bug.php?id=62893
-- explain
select p,''  from big where p between 5000000 and 5000100; -- 0,001 sec

drop INDEX IX_P1 on big;

-- Index anlegen mit UNIQUE
ALTER TABLE `primetest`.`big` 
ADD UNIQUE INDEX `IX_P2` USING BTREE (`p` ASC);

drop INDEX IX_P2 on big;

-- explain 
select small.q from big, small where small.q=big.p; -- 0,001 sec
-- explain
select p from big where p between 5000000 and 5000100; -- 0,001 sec
-- explain
select p from big order by p desc limit 10; -- 0,001 sec


ALTER TABLE `primetest`.`big` 
ADD COLUMN `md` CHAR(32) NULL AFTER `p`;

-- Spalte MD mit MD5 der Primzahlen füllen
update big set md=md5(p) where p > 1; -- 20,58 sec
select p, md from big limit 5;

drop INDEX IX_P2 on big;

-- explain 
select small.q from big, small where small.q=big.p; -- 2,05 sec
-- explain
select p, md from big where p between 5000000 and 5000100; -- 0,48
-- explain
select p, md from big order by p desc limit 10; -- 0,87 sec

-- wieder Index anlegen
ALTER TABLE `primetest`.`big` ADD UNIQUE INDEX `IX_P2` USING BTREE (`p` ASC); -- 10,52 sec
-- explain 
select small.q        from big,   small where small.q=big.p; -- 0,002 sec 0,001 sec, 0,001 sec
select small.q, big.md from big,small where small.q=big.p; -- 0,005 sec 0,001 sec, 0,001 sec

-- explain
select p, md from big where p between 5000200   and  5000300; -- 0,001 sec 0,001 sec 0,001 sec
-- explain
select p, md  from big order by p desc limit  10; -- 0,001 sec 0,002 sec 0,001 sec

select p, md from big order by md desc limit  10; -- 1,18
-- explain
select p, md from big order by md limit  10; -- 1,01

-- Index für Spalte MD anlegen
ALTER TABLE `primetest`.`big` 
ADD INDEX `IX_MD` USING BTREE (`md` ASC); -- 5,62 sec

select p, md from big order by md desc  limit 11; -- 0,002 sec 0,001 sec
-- explain
select p, md from big order by md limit  11; -- 0,001 sec 0,001 sec
