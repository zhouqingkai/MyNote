package ResolveExcelFileToData;


import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.junit.Test;

import jxl.Cell;
import jxl.Sheet;
import jxl.Workbook;

public class ExcelReader{

	@Test
	public void readExcelFile() throws Exception {
		String path = "F:\\Test\\aaaa.xls";
		List<String[]> list = new ArrayList<String[]>(); 
		//创建输入流
		InputStream is = new FileInputStream(path);
		Workbook wb=Workbook.getWorkbook(is);
		//获取第一个sheet
		Sheet sheet = wb.getSheet(0);
		//对每一行进行循环
		for (int i = 0; i < sheet.getRows(); i++) {
			//创建最大列数的数组
			String[] str = new String[sheet.getColumns()];
			Cell cell = null;
			for (int j = 0; j < sheet.getColumns(); j++) {
				//获取这个单元格内容放入数组
				cell=sheet.getCell(j, i);
				str[j]=cell.getContents();
			}
			list.add(str);
		}
		for(int i=0;i<list.size();i++){
		     String[] str = list.get(i);
		     for(int j=0;j<str.length;j++){
		      System.out.print(str[j]+'\t');
		     }
		     System.out.println();
		 }
		is.close();
	}

	
}




















