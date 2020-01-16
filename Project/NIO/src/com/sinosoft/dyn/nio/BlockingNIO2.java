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

public class BlockingNIO2 {

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
			
			socketChannel.shutdownOutput();
			
			//4.             新增                     接收服务端的反馈内容
			int len = 0;
			while ((len=socketChannel.read(buffer))!=-1) {
				buffer.flip();
				System.out.println(new String(buffer.array(),0,len));
				buffer.clear();
			}
			
			
			//5.关闭通道
			inChannel.close();
			socketChannel.close();
			
		}
		//服务端	先运行可以
		@Test
		public void server() throws IOException {
			//1.获取通道
			ServerSocketChannel ssChannel = ServerSocketChannel.open();
			
			FileChannel outChannel = FileChannel.open(Paths.get("7.jpg"), StandardOpenOption.WRITE,StandardOpenOption.CREATE);
			
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
			
			//6.			新增    		发送反馈到客户端
			buffer.put("服务器接收数据成功".getBytes());
			buffer.flip();
			socketChannel.write(buffer);
			
			
			
			
			//7.关闭通道
			ssChannel.close();
			outChannel.close();
			socketChannel.close();
			
		}
}
