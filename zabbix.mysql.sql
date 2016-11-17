1.根据模板名获取模板中所有的监控key_,以及监控频率,保存时长
	主要模板 'Record','Mysql','Concurrency','Cluster concurrency','Discovery'
	select i.hostid,h.name,i.itemid,i.name,i.key_,i.delay,i.trends,i.history 
	from items i 
	left join hosts h on h.hostid=i.hostid 
	where i.hostid in (
		select hostid 
	    from hosts 
	    where name in(
	    	'Record','Mysql','Concurrency','Cluster concurrency','Discovery')
	    	) 
		and key_ not like 'zabbix[%' 
		and key_ not like 'ProfessionalWork[%';

	获取单个模板中的监控项目
	select i.hostid,h.name,i.itemid,i.name,i.key_,i.delay,i.trends,i.history 
	from items i 
	left join hosts h on h.hostid=i.hostid 
	where i.hostid in (
		select hostid 
	    from hosts 
	    where name='Discovery'
	    	) 
		and key_ not like 'zabbix[%' 
		and key_ not like 'ProfessionalWork[%';

	添加监控项目到模板中	
2.获取zabbix的最新告警信息
	select distinct t.lastchange,t.description,h.name,h.hostid,t.priority
    from items i
    left join hosts h on i.hostid = h.hostid
    left join functions f on i.itemid = f.itemid
    left join triggers t on f.triggerid = t.triggerid
    where t.status = 0 and value=1 and i.status=0 
    ORDER BY lastchange desc,description;
3.获取模板中的触发器
	select description,lastchange 
	from triggers 
	where triggerid in (
		select triggerid
		from functions
		where itemid in (
			select i.itemid
			from items i 
			left join hosts h on h.hostid=i.hostid 
			where i.hostid in (
				select hostid 
		    	from hosts 
		    	where name in(
		    		'Record','Mysql','Concurrency','Cluster concurrency','Discovery')
		    		) 
			and key_ not like 'zabbix[%' 
			and key_ not like 'ProfessionalWork[%'
			)
		);

	获取单个模板中的触发器
	select *
	from triggers 
	where triggerid in (
		select triggerid
		from functions
		where itemid in (
			select i.itemid
			from items i 
			left join hosts h on h.hostid=i.hostid 
			where i.hostid in (
				select hostid 
		    	from hosts 
		    	where name='Record'
		    		) 
			and key_ not like 'zabbix[%' 
			and key_ not like 'ProfessionalWork[%'
			)
		);
4.获取所有监控key的最新数据
	select hostid,itemvalue.itemid,name,itemname,DateTime,value,units 
	from  (select ta.itemid, from_unixtime(clock) as DateTime,value 
			from  history_uint as ta  
			join  (
				SELECT itemid, MAX(clock) as maxclock 
				from history_uint 
				group BY itemid) as tb  
			on ta.itemid=tb.itemid and ta.clock=tb.maxclock) as latest 
			join  (
				SELECT TA.hostid,TA.`name`,items.itemid,items.`name` as itemname, items.units 
				from ( 
					SELECT `hosts`.hostid,`hosts`.`name` 
					from `hosts` 
					JOIN  items ON  `hosts`.hostid=items.hostid 
					where `hosts`.`status`=0  
					GROUP BY `hosts`.host) as TA 
				JOIN items on TA.hostid=  items.hostid and `items`.status=0) as itemvalue 
				on latest.itemid=itemvalue.itemid;
