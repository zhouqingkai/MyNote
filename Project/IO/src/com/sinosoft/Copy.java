package com.sinosoft;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;

import org.junit.Test;
/**
 * 
 */
public class Copy {
	/**
	 * 进行文件复制
	 */
	@Test
	public void copy() {
		BufferedInputStream bis = null;
		BufferedOutputStream bos = null;
		try {
			File file1 = new File("D:\\TestXMLfile\\1.csv");
			String file1Name=file1.getName();
			System.out.println(file1Name);
			
			File file2 = new File("D:\\TestXMLfile\\hello.csv");
			boolean exists = file2.exists();
			if(exists) {
				file2.delete();
			}else {
				file2.createNewFile();
			}
			FileInputStream fis = new FileInputStream(file1);
			FileOutputStream fos = new FileOutputStream(file2);

			bis = new BufferedInputStream(fis);
			bos = new BufferedOutputStream(fos);

			byte[] b = new byte[1024];
			int len;
			while ((len = bis.read(b)) != -1) {
				bos.write(b, 0, len);
				bos.flush();
			}
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				bos.close();
				bis.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}

	}
	@Test
	public void testCopyByBufferInputOutStream() throws IOException {
		File a = new File("hello.txt");
		File b = new File("hello2.txt");
		BufferedInputStream bis=null;
		BufferedOutputStream bos=null;
		try {
			FileInputStream fis=new FileInputStream(a);
			FileOutputStream fos=new FileOutputStream(b);
			bis=new BufferedInputStream(fis);
			bos=new BufferedOutputStream(fos);
			byte[] by=new byte[1024];
			//��������read()����ʱ�ķ���ֵ
			int len;
			while ((len=bis.read(by))!=-1) {
				bos.write(by, 0, len);
				bos.flush();
			}
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				bos.close();
				bis.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
		
	}
	
	

	@Test
	public void testBufferedReader() {
		BufferedReader br = null;
		try {
			File file1 = new File("hello.txt");
			FileReader fr = new FileReader(file1);
			br = new BufferedReader(fr);
//			char[] c = new char[1024];
//			int len;
//			while ((len = br.read(c)) != -1) {
//				String str = new String(c, 0, len);
//				System.out.println(str);
//			}
			String str;
			while ((str=br.readLine())!=null) {
				System.out.println(str);
			}
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				br.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

	}

}
