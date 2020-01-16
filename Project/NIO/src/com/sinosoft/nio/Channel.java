package com.sinosoft.nio;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CharsetEncoder;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.junit.Test;

public class Channel {
/**
 * 一.通道
 * 	用于源节点与目标节点的链接，在Java  NIO中负责
 * 	缓冲区中数据的传输，Channel本身不存储数据
 * 	因此需要配合缓冲区进行传输
 * 二  通道的主要实现类
 * 	java.nio.channels.Channel  接口:
 * 		|--FileChannel
 * 		|--SocketChannel
 * 		|--ServerSocketChannel
 * 		|--DatagramChannel
 * 三  获取通道
 * 	1.Java针对于支持通道的类提供了getChannel方法
 * 		本地IO:
 * 		FileInputStream/FileOutputStream
 * 		RandomAccessFile
 * 		网络IO:
 * 		Socket
 * 		ServerSocket
 * 		DatagramSocket
 * 	2.在JDK1.7中NIO.2针对于各个通道提供了静态方法open()
 *  3.在JDK1.7中NIO.2的Files工具类的newByteChannel()
 * @throws CharacterCodingException 
 * @throws IOException 
 * 
 *  4.通道之间的数据传输
 * 		transferFrom()
 * 		transferTo()
 * 	5.分散(Scatter)与聚集(Gather)
 * 		分散读取(Scattering Reads) 将通道中的数据分散到多个缓冲区中
 * 		
 * 	6.字符集:  Charset
 * 		编码:字符串 -> 字节数组
 * 		解码:字节数组 -> 字符串
 * 
 * 	7.NIO的非阻塞模式
 * 		selector选择器
 * 
 * 
 */
	//字符集
	@Test
	public void test5() throws CharacterCodingException {
		Map<String, Charset> map = Charset.availableCharsets();
		
		Set<Entry<String,Charset>> set = map.entrySet();
		
		for (Entry<String, Charset> entry : set) {
			System.out.println(entry.getKey()+"==="+entry.getValue());
		}
		System.out.println("==============分割线==============");
		
		Charset cs = Charset.forName("GBK");
		//获取编码器和解码器
		CharsetEncoder ce = cs.newEncoder();
		CharsetDecoder cd = cs.newDecoder();
		
		CharBuffer buff = CharBuffer.allocate(1024);
		buff.put("明天就要回家了");
		buff.flip();
		
		//编码
		ByteBuffer bBuff = ce.encode(buff);
		
		for (int i = 0; i <12; i++) {
			System.out.println("编码为:"+bBuff.get());
		}
		//解码
		bBuff.flip();
		CharBuffer cBuff = cd.decode(bBuff);
		System.out.println(cBuff.toString());
		
		System.out.println("==========使用UTF-8进行解码==========");
		
		Charset cs2 = Charset.forName("GBK");
		bBuff.flip();
		CharBuffer cBuff2 = cs2.decode(bBuff);
		System.out.println(cBuff2.toString());
		
		
	}
	
	
	//分散和聚集
	@Test
	public void test4() throws IOException {
		RandomAccessFile raf1 = new RandomAccessFile("1.txt", "rw");
		//1.获取通道
		FileChannel channel = raf1.getChannel();
		
		//2.分配指定大小的缓冲区
		ByteBuffer buf1 = ByteBuffer.allocate(100);
		ByteBuffer buf2 = ByteBuffer.allocate(1024);
		
		//3.分散读取
		ByteBuffer[] buff = {buf1,buf2};
		channel.read(buff);
		
		for (ByteBuffer byteBuffer : buff) {
			byteBuffer.flip();
		}
		
		System.out.println(new String(buff[0].array(),0,buff[0].limit()));
		System.out.println("==============");
		System.out.println(new String(buff[1].array(),0,buff[1].limit()));
		
		//4.聚集写入
		RandomAccessFile raf2 = new RandomAccessFile("2.txt", "rw");
		FileChannel channe2 = raf2.getChannel();
		
		channe2.write(buff);
	}
	
	//通道之间的数据传输(直接缓冲区的方式)
	@Test
	public void test3() throws IOException {
		FileChannel inChannel = FileChannel.open(Paths.get("1.jpg"), StandardOpenOption.READ);
		FileChannel outChannel = FileChannel.open(Paths.get("5.jpg"), StandardOpenOption.WRITE,StandardOpenOption.READ,StandardOpenOption.CREATE_NEW);
		
		//inChannel.transferTo(0,inChannel.size(),outChannel );
		outChannel.transferFrom(inChannel, 0, inChannel.size());
		
		outChannel.close();
		inChannel.close();
		
		
	}
	
	
	//2.使用直接缓冲区完成文件的复制(在物理内存中建立缓冲区)
	@Test
	public void test2() throws IOException {
		FileChannel inChannel = FileChannel.open(Paths.get("1.jpg"), StandardOpenOption.READ);
		FileChannel outChannel = FileChannel.open(Paths.get("13.jpg"), StandardOpenOption.WRITE,StandardOpenOption.READ,StandardOpenOption.CREATE_NEW);
		//内存映射文件
		MappedByteBuffer inMappedBuff = inChannel.map(MapMode.READ_ONLY,0, inChannel.size());
		MappedByteBuffer outMappedBuff = outChannel.map(MapMode.READ_WRITE, 0,inChannel.size());
		
		//直接对缓冲区进行数据的读写操作
		byte[] bt=new byte[inMappedBuff.limit()];
		inMappedBuff.get(bt);
		outMappedBuff.put(bt);
		outChannel.close();
		inChannel.close();
	
	}
	
	
	//1.利用通道完成文件的复制(非直接缓冲区，在JVM当中建立缓冲区)
	@Test
	public void test1() throws IOException {
		FileInputStream fis =new FileInputStream("1.jpg");
		FileOutputStream fos =new FileOutputStream("2.jpg");
		//获取通道
		FileChannel inChannel = fis.getChannel();
		FileChannel outChannel = fos.getChannel();
		//分配指定大小的缓冲区
		ByteBuffer buff = ByteBuffer.allocate(1024);
		//将通道里面的数据存入缓冲区
		while(inChannel.read(buff)!=-1) {
			//切换为读取模式
			buff.flip();
			//将缓冲区中的数据写入通道中
			outChannel.write(buff);
			//清空缓冲区
			buff.clear();
		}
		outChannel.close();
		inChannel.close();
		fis.close();
		fos.close();
		
	}
	
	
	
	
	
	
	
	
	
	
}
