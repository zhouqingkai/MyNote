package com.sinosoft;

import java.io.File;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;


public class Test1 {
	public static void main(String[] args) throws Exception {
		// 创建Freemarker配置实例
//		Configuration cfg = new Configuration();
//		cfg.setDirectoryForTemplateLoading(new File("templates"));
//
//		// 创建数据模型
//		Map<String, Object> root = new HashMap<String, Object>();
//		root.put("user", "庆凯");
//		root.put("random", new Random().nextInt(100));
//		
//		List<Address> list = new ArrayList<Address>();
//		list.add(new Address("中国", "哈尔滨"));
//		list.add(new Address("中国", "上海"));
//		list.add(new Address("美国", "纽约"));
//		root.put("list", list);
//		root.put("date1", new Date());
//		
//		// 加载模板文件
//		Template t1 = cfg.getTemplate("a.ftl");
//
//		// 显示生成的数据
//		/**
//		 * 输出到控制台
//		 * 输出到远方：建立一个socket，文件处理，socket.getOutputStream
//		 * 
//		 */
//		Writer out = new OutputStreamWriter(System.out);
//		t1.process(root, out);
//		out.flush();
//		out.close();
	}
}
