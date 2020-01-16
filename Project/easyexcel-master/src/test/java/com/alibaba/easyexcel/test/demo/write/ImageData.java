package com.alibaba.easyexcel.test.demo.write;

import java.io.File;
import java.io.InputStream;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;
import com.alibaba.excel.annotation.write.style.ContentRowHeight;
import com.alibaba.excel.converters.string.StringImageConverter;

import lombok.Data;

/**
 * 图片导出类
 *
 * @author Jiaju Zhuang
 */
@Data
@ContentRowHeight(100)
@ColumnWidth(100 / 8)
public class ImageData {
    private File file;
    private InputStream inputStream;
    /**
     * 如果string类型 必须指定转换器，string默认转换成string
     */
    @ExcelProperty(converter = StringImageConverter.class)
    private String string;
    private byte[] byteArray;
	public File getFile() {
		return file;
	}
	public void setFile(File file) {
		this.file = file;
	}
	public InputStream getInputStream() {
		return inputStream;
	}
	public void setInputStream(InputStream inputStream) {
		this.inputStream = inputStream;
	}
	public String getString() {
		return string;
	}
	public void setString(String string) {
		this.string = string;
	}
	public byte[] getByteArray() {
		return byteArray;
	}
	public void setByteArray(byte[] byteArray) {
		this.byteArray = byteArray;
	}
    
}
