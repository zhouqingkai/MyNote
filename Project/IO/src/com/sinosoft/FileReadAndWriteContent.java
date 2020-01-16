package com.sinosoft;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import org.junit.Test;

public class FileReadAndWriteContent {
	/**
	 * ʹ���ֽ���ʵ�����ݵ����
	 */
	@Test
	public void test01() {
		BufferedOutputStream bos = null;
		try {
			FileOutputStream fos = new FileOutputStream(new File("test.txt"));
			bos = new BufferedOutputStream(fos);
			String str = "将字符串数据添加到文件当中";
			bos.write(str.getBytes());
			bos.flush();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				bos.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
	/**
	 * ʹ���ַ���ʵ�����ݵ����
	 */
	@Test
	public void test02() {
		BufferedWriter bw=null; 
		try {
			bw = new BufferedWriter(new FileWriter("test1.txt"));
			String str="ƶ���������ҵ���������";
			bw.write(str);
			bw.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}finally {
			try {
				bw.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
	/**
	 * ʹ���ַ���+������ʵ�֣����ݵĶ���
	 */
	@Test
	public void test03() {
		BufferedReader br=null;
		try {
			 br = new BufferedReader(new FileReader("test1.txt"));
			 String str;
			 try {
				while ((str=br.readLine())!=null) {
					System.out.println(str);
				}
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}finally {
			try {
				br.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
	
	
	/**
	 * ���ó���  ����test.txt����Ϊtest5.txt
	 */
	@Test
	public void test04() {
		BufferedReader br=null;
		BufferedWriter bw=null;
		try {
			br=new BufferedReader(new FileReader(new File("test1.txt")));
			bw=new BufferedWriter(new FileWriter(new File("fuzhiwenjian1.txt")));
			char[]c=new char[20];
			int len;
			while ((len=br.read(c))!=-1) {
				bw.write(c, 0, len);
			}
		} catch (Exception e) {
			// TODO: handle exception
		}finally {
			try {
				bw.close();
				br.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
}







