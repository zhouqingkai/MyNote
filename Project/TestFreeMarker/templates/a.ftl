你好，${user},你今天气色不错！
--------------------------------------
测试if语句
<#if user=="庆凯">
	庆馨！
</#if>
--------------------------------------
<#if random gte 90>
	及格
<#elseif random gte 60>
	优秀
<#else>
	不及格
</#if>
--------------------------------------
测试list遍历
<#list list as bianliang>
	<b>${bianliang.country}</b></br>
</#list>
--------------------------------------
测试包含指令
<#include "included.txt">
--------------------------------------
测试宏指令

定义宏：
<#macro m1>  <#-- 定义指令m1 -->
	<b>aaabbbccc</b>
	<b>dddeeefff</b>
</#macro>

调用宏：
<@m1 /><@m1 /><@m1 /><@m1 />

定义带参数的宏
<#macro m2 a b c>
	${a}--${b}--${c}
</#macro>

调用宏：
<@m2 "hai" "nihao" "helo"/>
<@m2 "zhou" "qing" "kai"/>

--------------------------------------
<#-- nested指令 -->
<#macro border h>   <#-- 有参或者无参在border后面添加变量 -->
	<table border=4 cellspacing=0 cellpadding=4>
		<tr>
			<td>
			  ${h}			
			</td>
		</tr>
	</table>
</#macro>

调用宏：
<@border "调用有参的nested指令"/>
--------------------------------------
<#-- nested指令 -->
<#macro bord>   <#-- 有参或者无参在border后面添加变量 -->
	<table border=4 cellspacing=0 cellpadding=4>
		<tr>
			<td>
				<#nested>			
			</td>
		</tr>
	</table>
</#macro>
调用宏：
<@bord>
	border文本中间的内容  使用#nested带入
</@bord>

--------------------------------------
测试namespace命名空间

<#-- 一个重要的规则就是路径不应该包含大写字母，为了分割词语，使用下划线 -->

<#import "b.ftl" as bb/>
<@bb.copyright date="2010-2011"/>
${bb.mail}
<#assign mail="aaaaaaaaaa@163.com" />
${mail}
<#assign mail="aaaatobbbb@163.com" in bb />
${bb.mail}
--------------------------------------
测试数据类型

<#-- Freemarker对于javaBean的处理和EL表达式一直，类型可自动转化！非常方便 -->

<#assign b="sss">
${date1?string("yyyy-MM-dd HH:mm:ss")}
--------------------------------------
测试空值处理
<#--  ${sss} 没有定义这个变量  会报异常 在后面加上！  表示  没有这个变量  给默认值空   -->
<#--  没有定义这个变量，默认字符串是abcd -->
${sss!} 
${sss!"abcd"}
?? 表示判断是否为true  布尔值boolean
<#if user??>Welcome ${user}</#if>
--------------------------------------





