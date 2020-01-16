package com.sinosoft.dyn.nio;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

import org.junit.Test;

/**
 * 	阻塞式IO示例
 * 
 * 
 * @author zhouqk
 * 一.使用NIO完成网络通信的三个核心
 * 	1.通道Channel负责连接
 * 		java.nio.channels.Channel  接口：
 * 			|-- SelectableChannel
 * 				|--SocketChannel
 * 				|--ServerSocketChannel
 * 				|--DatagramChannel
 * 
 * 				|--Pipe.SinkChannel
 * 				|--Pipe.SourceChannel
 * 
 * 	2.缓冲区Buffer负责数据的读取
 * 
 * 	3.选择器Selector是SelectableChannel的多路复用器，用于监控SelectableChannel的IO状况
 * 
 *
 */
public class BlockingNIO {
	//客户端
	@Test
	public void client() throws IOException {
		//1.获取通道
		SocketChannel socketChannel = SocketChannel.open(new InetSocketAddress("127.0.0.1",8090));
		
		FileChannel inChannel = FileChannel.open(Paths.get("1.jpg"),StandardOpenOption.READ);

		//2.分配指定大小的缓冲区
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		
		//3.读取本地文件并发送到服务器
		while (inChannel.read(buffer)!=-1) {
			buffer.flip();
			socketChannel.write(buffer);
			buffer.clear();
		}
		
		//4.关闭通道
		inChannel.close();
		socketChannel.close();
		
	}
	//服务端	需要先运行
	@Test
	public void server() throws IOException {
		//1.获取通道
		ServerSocketChannel ssChannel = ServerSocketChannel.open();
		
		FileChannel outChannel = FileChannel.open(Paths.get("5.jpg"), StandardOpenOption.WRITE,StandardOpenOption.CREATE);
		
		//2.绑定连接指定的端口号
		ssChannel.bind(new InetSocketAddress(8090));
		
		//3.获取客户端连接的通道
		SocketChannel socketChannel = ssChannel.accept();
		
		//4.分配指定大小的缓冲区
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		
		//5.接收客户端的数据，并保存到本地
		while (socketChannel.read(buffer)!=-1) {
			buffer.flip();
			outChannel.write(buffer);
			buffer.clear();
		}
		
		//6.关闭通道
		ssChannel.close();
		outChannel.close();
		socketChannel.close();
		
	}
	

}
