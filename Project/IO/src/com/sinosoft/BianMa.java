package com.sinosoft;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;

import org.junit.Test;

public class BianMa {
	/**
	 * 使用bio流将文件输出到hello.txt文件中
	 */
	@Test
	public void test01() {
		BufferedReader br = null;
		BufferedWriter bw = null;
		try {
			File file1 = new File("hello.txt");
			FileInputStream fis = new FileInputStream(file1);
			InputStreamReader isr = new InputStreamReader(fis, "GBK");
			br = new BufferedReader(isr);

			File file2 = new File("hello4.txt");
			FileOutputStream fos = new FileOutputStream(file2);
			OutputStreamWriter osw = new OutputStreamWriter(fos, "GBK");
			bw = new BufferedWriter(osw);

			String str;
			while ((str = br.readLine()) != null) {
				bw.write(str);
				bw.newLine();
				bw.flush();
			}

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				bw.close();
				br.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}

	}
}
