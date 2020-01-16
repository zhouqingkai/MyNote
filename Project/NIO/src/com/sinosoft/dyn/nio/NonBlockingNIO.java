package com.sinosoft.dyn.nio;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Date;
import java.util.Iterator;
import java.util.Scanner;

import org.junit.Test;

/**
 * 											阻塞式IO示例
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
public class NonBlockingNIO {
	//客户端
	@Test
	public void client() throws IOException {
		//1.获取通道
		SocketChannel socketChannel = SocketChannel.open(new InetSocketAddress("127.0.0.1",8090));
		
		//2.切换为非阻塞模式
		socketChannel.configureBlocking(false);
		
		//3.分配指定大小的缓冲区
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		
		//4.发送数据给服务器
		Scanner scan = new Scanner(System.in);
		
		
		
		buffer.put(new Date().toString().getBytes());
		buffer.flip();
		socketChannel.write(buffer);
		buffer.clear();
		
		
		
		
		//5,关闭通道
		socketChannel.close();
		
	}
	//服务端	先运行可以
	@Test
	public void server() throws IOException {
		//1.获取通道
		ServerSocketChannel ssChannel = ServerSocketChannel.open();
		
//		FileChannel outChannel = FileChannel.open(Paths.get("7.jpg"), StandardOpenOption.WRITE,StandardOpenOption.CREATE);
		
		//2.切换为非阻塞模式
		ssChannel.configureBlocking(false);
		
		//3.绑定连接指定的端口号
		ssChannel.bind(new InetSocketAddress(8090));
		
		//4.获取选择器
		Selector select = Selector.open();
		
		//5.将通道注册到选择器中,并且指定监听接收事件
		ssChannel.register(select, SelectionKey.OP_ACCEPT);
		
		//6.轮训式获取选择器上已经准备就绪的事件
		while (select.select()>0) {
			//7.获取当前选择器中所有注册的选择键(已经就绪的监听事件)
			Iterator<SelectionKey> iterator = select.selectedKeys().iterator();
			

			while (iterator.hasNext()) {
				//8.迭代获取准备就绪的事件
				SelectionKey sk = iterator.next();
				//9.判断具体是什么事件准备就绪
				if (sk.isAcceptable()) {
					//10.如果是接受就绪，那么获取客户端连接
					SocketChannel sChannel = ssChannel.accept();
					//11.切换为非阻塞模式
					sChannel.configureBlocking(false);
					//12.将该通道注册到选择器上
					sChannel.register(select, SelectionKey.OP_READ);
					
				}else if (sk.isReadable()) {
					//13.获取当前选择器上"读就绪"状态的通道
					SocketChannel sChannel = (SocketChannel)sk.channel();
					//14.读取数据
					ByteBuffer buffer = ByteBuffer.allocate(1024);
					
					int len = 0;
					while ((len=sChannel.read(buffer))!=-1) {
						buffer.flip();
						System.out.println(new String(buffer.array(),0,len));
						buffer.clear();
					}
				}
				
				//15.取消选择键  SelectionKey
				iterator.remove();
				
				
			}
		}
		
	}

}
