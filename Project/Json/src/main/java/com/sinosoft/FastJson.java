package com.sinosoft;

import com.alibaba.fastjson.JSON;

public class FastJson {
	public static void main(String[] args) {
		User user1 = new User();
		user1.setUserName("温庆欣");
		user1.setPwd("123");

		//1、单个对象转换成json
		String jsonString = JSON.toJSONString(user1);
		System.out.println(jsonString);
		//打印结果
		//{{"pwd":"123","userName":"温庆欣"}}
	}
}	
