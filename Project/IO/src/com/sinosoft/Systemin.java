package com.sinosoft;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.junit.Test;

public class Systemin {
	/**
	 * 标准的输入输出流 system.out systemm.in
	 */

	@Test
	public void test02() {
		BufferedReader br = null;
		try {
			InputStream is = System.in;
			InputStreamReader isr = new InputStreamReader(is);
			br = new BufferedReader(isr);
			String str;
			while (true) {
				System.out.println("请输入字符串：");
				str = br.readLine();
				if (str.equalsIgnoreCase("e") || str.equalsIgnoreCase("exit")) {
					break;
				}
				String str1 = str.toUpperCase();
				System.out.println(str1);
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				br.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
}
