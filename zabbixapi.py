#!/usr/bin/python
#coding=utf-8
#
#这个脚本的主要作用是利用zabbix api获取出信息
#
#	by wangdd 2015/12/30
#

import json
import urllib2
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

#zabbix APID的信息和头部信息的定义
url = "http://192.168.35.114/zabbix/api_jsonrpc.php"
header = {"Content-Type": "application/json"}
#定义认证函数，可以使用api
def auth():
	data = json.dumps(
	{
	"jsonrpc": "2.0",
	"method": "user.login",
	"params": {
	"user": "admin",
	"password": "admin"
	},
	"id": 0
	})
	request = urllib2.Request(url,data)
	for key in header:
		request.add_header(key,header[key])
	# auth and get authid
	try:
		result = urllib2.urlopen(request)
	except URLError as e:
		print "Auth Failed, Please Check Your Name And Password:",e.code
	else:
		response = json.loads(result.read())
		result.close()
		return response['result']

#定义request数据获取数据
def get_data(api):
	key = auth()
	data_request = json.dumps(
	{
	"jsonrpc":"2.0",
	"method":api,
	"params":{
	"output":"extend",
	"selectSteps":"extend"
	},
	"auth":key, # the auth id is what auth script returns, remeber it is string
	"id":1
	})
	request = urllib2.Request(url,data_request)
	for key in header:
	    request.add_header(key,header[key])
	result = urllib2.urlopen(request)
	response = json.loads(result.read())
	return response
	result.close()

#利用api 获取出自动发现规则的信息,规则状态0启用,1停用,类型服务获取客户端数据的方式,默认0(zabbix_agent)
def get_discoveryrule():
	data = get_data(api='discoveryrule.get')
	for name in data['result']:
		print "主机ID:",name['hostid'] + "\t" "规则名称:",name['name'] +"\t" "自动探索key:",name['key_'] \
		+"\t" "数据更新间隔(秒):",name['delay'] +"\t" "过期数据保留时间(天):",name['lifetime'] \
		+"\t" "规则是否启用:",name['status'] +"\t" "类型",name['type'] \
		+"\t" "interfaceid:",name['interfaceid'] +"\t" "templateid:",name['templateid']

#利用接口添加自动发现规则
def create_discoveryrule():
	key = auth()
	data_request = json.dumps(
	{
	"jsonrpc": "2.0",
	"method": "discoveryrule.create",
	"params": {
		"name":"test",
        	"key_":"test.discovery"
	},
	"auth": key,
	"id": 1
	})
	request = urllib2.Request(url,data_request)
        for key in header:
            request.add_header(key,header[key])
        result = urllib2.urlopen(request)
        response = json.loads(result.read())
        print response
        result.close()

#获取主机的信息
def get_host_info():
	data = get_data(api='host.get')
	for name in data['result']:
		print "hostid:",name['hostid'] +"\t" "hostname:",name['name']

#获取模板信息
def get_template():
	data = get_data(api='template.get')
	for name in data['result']:
		print "模板名:",name['name'] +"\t" "模板ID:",name['templateid']

#获取item信息
def get_item():
	data = get_data(api='item.get')
	for name in data['result']:
		print "主机ID:",name['hostid'] + "\t" "Item 名字:",name['name'] + "\t" "Key:",name['key_']

#获取itemprototype信息
def get_itemprototype():
	data = get_data(api='itemprototype.get')
	for name in data['result']:
		print "主机ID:",name['hostid'] + "\t" "Item 名字:",name['name'] + "\t" "Key:",name['key_']

#获取trigger信息
def get_trigger():
	data = get_data(api='trigger.get')
	for name in data['result']:
		print "名称:",name['description'] +"\t" "等级:",name['priority'] + "\t" "状态:",name['state']

#获取triggerprototype信息
def get_triggerprototype():
	data = get_data(api='triggerprototype.get')
	for name in data['result']:
		print "名称:",name['description'] +"\t" "等级:",name['priority'] + "\t" "状态:",name['state']

#获取脚本的信息
def get_script():
	data = get_data(api='script.get')
	for name in data['result']:
		print "脚本名称:",name['name'] +"\t" "命令:",name['command']

#获取httptest信息
def get_httptest():
	data = get_data(api='httptest.get')
	for name in data['result']:
		print "HostID:",name['hostid'] +"\t" "名称:",name['name'] + "\t" "URL:",name['steps'][0]['url'] \
		+"\t" "状态码:",name['steps'][0]['status_codes']
#获取hostinterface信息
def get_hostinterface():
	data = get_data(api='hostinterface.get')
	for name in data['result']:
		print "hostid:",name['hostid'] +"\t" "interfaceid:",name['interfaceid'] +"\t" "IP:",name['ip']

#函数调用
#get_discoveryrule()
#get_host_info()
#get_template()
#get_item()
#get_itemprototype()
#get_trigger()
#get_script()
#get_httptest()
#get_triggerprototype()
get_hostinterface()
#create_discoveryrule()
