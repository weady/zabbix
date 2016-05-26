/**************************************************************
  MySQL Auto Partitioning Procedure for Zabbix
**************************************************************/
DELIMITER //
DROP PROCEDURE IF EXISTS `zabbix`.`create_zabbix_partitions` //
CREATE PROCEDURE `zabbix`.`create_zabbix_partitions` ()
BEGIN
	CALL zabbix.create_next_partitions("zabbix","history");
	CALL zabbix.create_next_partitions("zabbix","history_log");
	CALL zabbix.create_next_partitions("zabbix","history_str");
	CALL zabbix.create_next_partitions("zabbix","history_text");
	CALL zabbix.create_next_partitions("zabbix","history_uint");
	CALL zabbix.create_next_partitions_month("zabbix","acknowledges");
	CALL zabbix.create_next_partitions_month("zabbix","alerts");
	CALL zabbix.create_next_partitions_month("zabbix","auditlog");
	CALL zabbix.create_next_partitions_month("zabbix","events");
	CALL zabbix.create_next_partitions_month("zabbix","trends");
	CALL zabbix.create_next_partitions_month("zabbix","trends_uint");
	CALL zabbix.drop_old_partitions("zabbix","history");
	CALL zabbix.drop_old_partitions("zabbix","history_log");
	CALL zabbix.drop_old_partitions("zabbix","history_str");
	CALL zabbix.drop_old_partitions("zabbix","history_text");
	CALL zabbix.drop_old_partitions("zabbix","history_uint");
END //
DROP PROCEDURE IF EXISTS `zabbix`.`create_next_partitions` //
CREATE PROCEDURE `zabbix`.`create_next_partitions` (SCHEMANAME varchar(64), TABLENAME varchar(64))
BEGIN
	DECLARE NEXTCLOCK timestamp;
	DECLARE PARTITIONNAME varchar(16);
	DECLARE CLOCK int;
	SET @totaldays = 7;
	SET @i = 1;
/*
LOOP启到循环的作用
DATE_ADD(date,INTERVAL expr type)
date 是一个 DATETIME 或DATE值，用来指定起始时间
expr 是一个表达式，用来指定从起始日期添加或减去的时间间隔值
DATE_FORMAT(date,format) */
	createloop: LOOP
		SET NEXTCLOCK = DATE_ADD(NOW(),INTERVAL @i DAY);
		SET PARTITIONNAME = DATE_FORMAT( NEXTCLOCK, 'p%Y%m%d' );
		SET CLOCK = UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD( NEXTCLOCK ,INTERVAL 1 DAY),'%Y-%m-%d 00:00:00'));
		CALL zabbix.create_partition( SCHEMANAME, TABLENAME, PARTITIONNAME, CLOCK );
		SET @i=@i+1;
		IF @i > @totaldays THEN
			LEAVE createloop;
		END IF;
	END LOOP;
END //
DROP PROCEDURE IF EXISTS `zabbix`.`create_next_partitions_month` //
CREATE PROCEDURE `zabbix`.`create_next_partitions_month` (SCHEMANAME varchar(64), TABLENAME varchar(64))
BEGIN
	DECLARE NEXTCLOCK timestamp;
	DECLARE PARTITIONNAME varchar(16);
	DECLARE CLOCK int;
	SET @totalmonths = 2;
	SET @i = 1;
/*
LOOP启到循环的作用
DATE_ADD(date,INTERVAL expr type)
date 是一个 DATETIME 或DATE值，用来指定起始时间
expr 是一个表达式，用来指定从起始日期添加或减去的时间间隔值
DATE_FORMAT(date,format) */
	createloop: LOOP
		SET NEXTCLOCK = DATE_ADD(NOW(),INTERVAL @i MONTH);
		SET PARTITIONNAME = DATE_FORMAT( NEXTCLOCK, 'p%Y%m' );
		SET CLOCK = UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD( NEXTCLOCK ,INTERVAL 1 MONTH),'%Y-%m-01 00:00:00'));
		CALL zabbix.create_partition( SCHEMANAME, TABLENAME, PARTITIONNAME, CLOCK );
		SET @i=@i+1;
		IF @i > @totalmonths THEN
			LEAVE createloop;
		END IF;
	END LOOP;
END //
DROP PROCEDURE IF EXISTS `zabbix`.`drop_old_partitions` //
CREATE PROCEDURE `zabbix`.`drop_old_partitions` (SCHEMANAME varchar(64), TABLENAME varchar(64))
BEGIN
	DECLARE OLDCLOCK timestamp;
	DECLARE PARTITIONNAME varchar(16);
	DECLARE CLOCK int;
	SET @mindays = 7;
	SET @maxdays = @mindays+4;
	SET @i = @maxdays;
/*date_sub() 减去相应的天数*/
	droploop: LOOP
		SET OLDCLOCK = DATE_SUB(NOW(),INTERVAL @i DAY);
		SET PARTITIONNAME = DATE_FORMAT( OLDCLOCK, 'p%Y%m%d' );
		CALL zabbix.drop_partition( SCHEMANAME, TABLENAME, PARTITIONNAME );
		SET @i=@i-1;
		IF @i <= @mindays THEN
			LEAVE droploop;
		END IF;
	END LOOP;
END //
DROP PROCEDURE IF EXISTS `zabbix`.`create_partition` //
CREATE PROCEDURE `zabbix`.`create_partition` (SCHEMANAME varchar(64), TABLENAME varchar(64), PARTITIONNAME varchar(64), CLOCK int)
BEGIN
	DECLARE RETROWS int;
	SELECT COUNT(1) INTO RETROWS
		FROM `information_schema`.`partitions`
		WHERE `table_schema` = SCHEMANAME AND `table_name` = TABLENAME AND `partition_name` = PARTITIONNAME;
	
	IF RETROWS = 0 THEN
		SELECT CONCAT( "create_partition(", SCHEMANAME, ",", TABLENAME, ",", PARTITIONNAME, ",", CLOCK, ")" ) AS msg;
     		SET @sql = CONCAT( 'ALTER TABLE `', SCHEMANAME, '`.`', TABLENAME, '`',
				' ADD PARTITION (PARTITION ', PARTITIONNAME, ' VALUES LESS THAN (', CLOCK, '));' );
/* concat 拼接sql语句
set @v_sql=sql;   --注意很重要，将连成成的字符串赋值给一个变量（可以之前没有定义，但要以@开头）
prepare stmt from @v_sql;  --预处理需要执行的动态SQL，其中stmt是一个变量
EXECUTE stmt;      --执行SQL语句
deallocate prepare stmt;     --释放掉预处理段
*/
		PREPARE STMT FROM @sql;
		EXECUTE STMT;
		DEALLOCATE PREPARE STMT;
	END IF;
END //
DROP PROCEDURE IF EXISTS `zabbix`.`drop_partition` //
CREATE PROCEDURE `zabbix`.`drop_partition` (SCHEMANAME varchar(64), TABLENAME varchar(64), PARTITIONNAME varchar(64))
BEGIN
	DECLARE RETROWS int;
	SELECT COUNT(1) INTO RETROWS
		FROM `information_schema`.`partitions`
		WHERE `table_schema` = SCHEMANAME AND `table_name` = TABLENAME AND `partition_name` = PARTITIONNAME;
	
	IF RETROWS = 1 THEN
		SELECT CONCAT( "drop_partition(", SCHEMANAME, ",", TABLENAME, ",", PARTITIONNAME, ")" ) AS msg;
     		SET @sql = CONCAT( 'ALTER TABLE `', SCHEMANAME, '`.`', TABLENAME, '`',
				' DROP PARTITION ', PARTITIONNAME, ';' );
		PREPARE STMT FROM @sql;
		EXECUTE STMT;
		DEALLOCATE PREPARE STMT;
	END IF;
END //
DELIMITER ;
