package CreateExcelAndZipFile;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import jxl.Workbook;
import jxl.format.Alignment;
import jxl.format.Border;
import jxl.format.BorderLineStyle;
import jxl.format.Colour;
import jxl.format.UnderlineStyle;
import jxl.format.VerticalAlignment;
import jxl.write.Label;
import jxl.write.WritableCellFormat;
import jxl.write.WritableFont;
import jxl.write.WritableSheet;
import jxl.write.WritableWorkbook;
import jxl.write.WriteException;
import jxl.write.biff.RowsExceededException;

public class CreateExcelFile {
	/**
	 * @param args
	 * @throws IOException
	 * @throws WriteException
	 * @throws RowsExceededException
	 */
	public static void main(String[] args) throws RowsExceededException, WriteException, IOException {
		String path = "F:\\Test";
		// 创建文件夹;
		createFile(path);
		// 创建Excel文件;
		createExcelFile(path);
		// 生成.zip文件;
		craeteZipPath(path);
		// 删除目录下所有的文件;
		//File file = new File(path);
		// 删除文件;
		//deleteExcelPath(file);
		// 重新创建文件;
		//file.mkdirs();

	}

	/**
	 * 创建文件夹D:\document\excel; 在D盘中创建document文件夹，并在里面创建excel文件夹
	 * 
	 * @param path
	 * @return
	 */
	public static String createFile(String path) {
		File file = new File(path);
		// 判断文件是否存在;
		if (!file.exists()) {
			// 创建文件;
			boolean bol = file.mkdirs();
			if (bol) {
				System.out.println(path + " 路径创建成功!");
			} else {
				System.out.println(path + " 路径创建失败!");
			}
		} else {
			System.out.println(path + " 文件已经存在!");
		}
		return path;
	}

	/**
	 * 在指定目录下创建Excel文件; 在excel文件夹下方创建三个excel文件，并设置样式，内容
	 * 
	 * @param path
	 * @throws IOException
	 * @throws WriteException
	 * @throws RowsExceededException
	 */
	public static void createExcelFile(String path) throws IOException, RowsExceededException, WriteException {
		for (int i = 0; i < 3; i++) {
			// 创建Excel;
			WritableWorkbook workbook = Workbook.createWorkbook(new File(
					path + "/" + new SimpleDateFormat("yyyyMMddHHmmsss").format(new Date()) + "_" + (i + 1) + ".xls"));
			// 创建第一个sheet文件;
			WritableSheet sheet = workbook.createSheet("导出Excel文件", 0);
			// 设置默认宽度;
			sheet.getSettings().setDefaultColumnWidth(30);

			// 设置字体;
			WritableFont font1 = new WritableFont(WritableFont.ARIAL, 14, WritableFont.BOLD, false,
					UnderlineStyle.NO_UNDERLINE, Colour.RED);

			WritableCellFormat cellFormat1 = new WritableCellFormat(font1);
			// 设置背景颜色;
			cellFormat1.setBackground(Colour.BLUE_GREY);
			// 设置边框;
			cellFormat1.setBorder(Border.ALL, BorderLineStyle.DASH_DOT);
			// 设置自动换行;
			cellFormat1.setWrap(true);
			// 设置文字居中对齐方式;
			cellFormat1.setAlignment(Alignment.CENTRE);
			// 设置垂直居中;
			cellFormat1.setVerticalAlignment(VerticalAlignment.CENTRE);
			// 创建单元格
			Label label1 = new Label(0, 0, "第一行第一个单元格(测试是否自动换行!)", cellFormat1);
			Label label2 = new Label(1, 0, "第一行第二个单元格", cellFormat1);
			Label label3 = new Label(2, 0, "第一行第三个单元格", cellFormat1);
			Label label4 = new Label(3, 0, "第一行第四个单元格", cellFormat1);
			// 添加到行中;
			sheet.addCell(label1);
			sheet.addCell(label2);
			sheet.addCell(label3);
			sheet.addCell(label4);

			// 写入Excel表格中;
			workbook.write();
			// 关闭流;
			workbook.close();
		}
	}

	/**
	 * 生成.zip文件,将excel文件压缩为压缩包;
	 * 
	 * @param path
	 * @throws IOException
	 */
	public static void craeteZipPath(String path) throws IOException {
		ZipOutputStream zipOutputStream = null;
		File file = new File(path + new SimpleDateFormat("yyyyMMddHHmmss").format(new Date()) + ".zip");
		zipOutputStream = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(file)));
		File[] files = new File(path).listFiles();
		FileInputStream fileInputStream = null;
		byte[] buf = new byte[1024];
		int len = 0;

		if (files != null && files.length > 0) {
			for (File excelFile : files) {
				String fileName = excelFile.getName();
				fileInputStream = new FileInputStream(excelFile);
				// 放入压缩zip包中;
				zipOutputStream.putNextEntry(new ZipEntry(path + "/" + fileName));

				// 读取文件;
				while ((len = fileInputStream.read(buf)) > 0) {
					zipOutputStream.write(buf, 0, len);
				}
				// 关闭;
				zipOutputStream.closeEntry();
				if (fileInputStream != null) {
					fileInputStream.close();
				}
			}
		}

		if (zipOutputStream != null) {
			zipOutputStream.close();
		}
	}

	/**
	 * @throws FileNotFoundException
	 * 
	 */

	public void CreateZipFile() throws Exception {
		String path = "F:\\Test";
		File file = new File(path);
		//将路径下所有文件放入数组中
		File[] files = file.listFiles();
		//创建自己的zip文件，并指定全路径
		File zip = new File(path + "/" + "myZip.zip");
		//创建压缩文件的输出流
		ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(zip)));
		byte[] b = new byte[1024];
		int len = 0;

		FileInputStream fis = null;
		//循环  为每一个文件压缩到压缩文件中
		for (File file2 : files) {
			//获取文件名
			String fileName = file2.getName();
			try {
				//获取输入流
				fis = new FileInputStream(file2);
				//放入zip压缩包中
				zos.putNextEntry(new ZipEntry(path + "/" + fileName));
				// 读取文件;
				while ((len = fis.read(b)) > 0) {
					zos.write(b, 0, len);
				}
				//关闭每次放入的流
				zos.closeEntry();
				//关闭读取的流
				if (fis != null) {
					fis.close();
				}
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} 
		}
		/**
		 * 关闭输出的压缩文件流
		 * 如果再循环中关闭，只会写入一个文件，
		 */
		if (zos!=null) {
			zos.close();
		}
	}

	/**
	 * 删除目录下所有的文件;
	 * 
	 * @param path
	 */
	public static boolean deleteExcelPath(File file) {
		String[] files = null;
		if (file != null) {
			files = file.list();
		}

		if (file.isDirectory()) {
			for (int i = 0; i < files.length; i++) {
				boolean bol = deleteExcelPath(new File(file, files[i]));
				if (bol) {
					System.out.println("删除成功!");
				} else {
					System.out.println("删除失败!");
				}
			}
		}
		return file.delete();
	}

	/**
	 * 自己学习的笔记，创建自己想要的Excel文件
	 * 
	 * @throws IOException
	 * @throws WriteException
	 */
	public void CreateExcel() throws IOException, WriteException {
		// 创建新建Excel文件的文件夹
		String path = "F:\\Test";
		File dir = new File(path);
		if (dir.isDirectory()) {
			System.out.println("文件夹已经存在");
			File[] listFiles = dir.listFiles();
			for (File file : listFiles) {
				if (file.isFile()) {
					file.delete();
				}
			}
		} else {
			dir.mkdir();
			System.out.println("创建文件夹成功");
		}

		// 设置默认宽度
		// 创建WritableWorkbook Excel文件时，要一步执行下来，否则没结果
		WritableWorkbook workBook = Workbook.createWorkbook(new File(path + "/" + "庆凯的Excel文件，时间为："
				+ new SimpleDateFormat("yyyyMMddHHmmsss").format(new Date()) + "_" + 1 + ".xls"));

		WritableSheet sheet = workBook.createSheet("庆凯的第一个sheet", 0);

		sheet.getSettings().setDefaultColumnWidth(30);
		// 设置字体;
		WritableFont font1 = new WritableFont(WritableFont.ARIAL, 14, WritableFont.BOLD, false,
				UnderlineStyle.NO_UNDERLINE, Colour.RED);

		WritableCellFormat cellFormat1 = new WritableCellFormat(font1);
		// 设置背景颜色;
		cellFormat1.setBackground(Colour.BLUE_GREY);
		// 设置边框;
		cellFormat1.setBorder(Border.ALL, BorderLineStyle.DASH_DOT);
		// 设置自动换行;
		cellFormat1.setWrap(true);
		// 设置文字居中对齐方式;
		cellFormat1.setAlignment(Alignment.CENTRE);
		// 设置垂直居中;
		cellFormat1.setVerticalAlignment(VerticalAlignment.CENTRE);

		// 创建单元格
		Label label1 = new Label(0, 0, "第一行第一个单元格(测试是否自动换行!)", cellFormat1);
		Label label2 = new Label(1, 0, "第一行第二个单元格", cellFormat1);
		Label label3 = new Label(2, 0, "第一行第三个单元格", cellFormat1);
		Label label4 = new Label(3, 0, "第一行第四个单元格", cellFormat1);

		// 添加到行中;
		sheet.addCell(label1);
		sheet.addCell(label2);
		sheet.addCell(label3);
		sheet.addCell(label4);

		// 给第二行设置背景、字体颜色、对齐方式等等;
		WritableFont font2 = new WritableFont(WritableFont.ARIAL, 14, WritableFont.NO_BOLD, false,
				UnderlineStyle.NO_UNDERLINE, Colour.BLUE2);
		WritableCellFormat cellFormat2 = new WritableCellFormat(font2);
		cellFormat2.setAlignment(Alignment.CENTRE);
		cellFormat2.setBackground(Colour.PINK);
		cellFormat2.setBorder(Border.ALL, BorderLineStyle.THIN);
		cellFormat2.setWrap(true);

		// 创建单元格;
		Label label11 = new Label(0, 1, "第二行第一个单元格(测试是否自动换行!)", cellFormat2);
		Label label22 = new Label(1, 1, "第二行第二个单元格", cellFormat2);
		Label label33 = new Label(2, 1, "第二行第三个单元格", cellFormat2);
		Label label44 = new Label(3, 1, "第二行第四个单元格", cellFormat2);

		sheet.addCell(label11);
		sheet.addCell(label22);
		sheet.addCell(label33);
		sheet.addCell(label44);

		/**
		 * 最终通过workBook进行写入，所有的操作在这个对象中进行 sheet为Excel一个面儿 cell为样式 label单元格
		 */
		WritableSheet sheet2 = workBook.createSheet("庆凯的第二个sheet", 1);
		sheet2.getSettings().setDefaultColumnWidth(30);
		WritableFont font = new WritableFont(WritableFont.ARIAL, 14, WritableFont.BOLD, false,
				UnderlineStyle.NO_UNDERLINE, Colour.RED);
		WritableCellFormat cell = new WritableCellFormat(font);
		cell.setAlignment(Alignment.CENTRE);
		cell.setBackground(Colour.BLACK);
		cell.setWrap(true);
		// 创建单元格
		Label lable211 = new Label(0, 0, "第一行第一列的值", cell);
		Label lable212 = new Label(1, 0, "第一行第二列的值", cell);
		Label lable213 = new Label(2, 0, "第一行第三列的值", cell);
		Label lable214 = new Label(3, 0, "第一行第四列的值", cell);
		Label lable215 = new Label(4, 0, "第一行第五列的值", cell);
		sheet2.addCell(lable211);
		sheet2.addCell(lable212);
		sheet2.addCell(lable213);
		sheet2.addCell(lable214);
		sheet2.addCell(lable215);

		// 写入Excel表格中;
		workBook.write();
		// 关闭流;
		workBook.close();

	}

}
