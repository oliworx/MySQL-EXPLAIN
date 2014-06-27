DROP DATABASE IF EXISTS primetest;
CREATE DATABASE primetest;
USE primetest;

CREATE TABLE big (
	p INT NOT NULL
);
CREATE TABLE small (
	q INT NOT NULL
);
-- # primes 1 10000000 > /tmp/primes
-- # sudo chown mysql:mysql
LOAD DATA INFILE "/tmp/primes" into table big;
TRUNCATE `primetest`.`small`;
insert into small values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
  (11),(12),(13),(14),(15),(16),(17),(18),(19),(20);

-- alle kleinen natürlichen Zahlen
select q from small;

-- alle kleinen Primzahlen
explain select q   from small,  big where small.q=big.p; -- 1,69 sec 1,7 sec 1,59 sec, 1,89 sec
explain select q from small,   big where big.p=small.q; -- 2,04 sec 2,13 sec 2,18 Sek
-- explain 
select p,q from small,  big where big.p=small.q; -- 1,62 sec 1,766 sec 1,54 sec

-- Ein paar Primzahlen aus der Mitte
-- explain
select p,'' from big where p between 5000000 and 5000100; -- 0,528 sec

-- Index anlegen mit UNIQUE
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
