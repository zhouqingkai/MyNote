package com.sinosoft.nio;

import java.nio.ByteBuffer;

import org.junit.Test;

/**
 * 
 * @author zhouqk
 *
 *Buffer缓冲区：负责存取数据，在Java  NIO中负责数据的存取，
 *底层为数组，用于存储不同数据类型的的数据
 *根据数据类型不同，提供对应的类型的缓冲区(除了boolean以外)
 *ByteBuffer(最常用)
 *charbuffer
 *intbuffer
 *shortbuffer
 *longbuffer
 *floatbuffer
 *doublebuffer
 *
 *1.以上缓冲区的管理方式几乎一致，通过allocate()获取缓冲区
 *2.缓冲区存取数据的两个核心方法:
 *		put():存入数据到缓冲区当中
 *		get():获取缓冲区中的数据
 *	1)Buffer的四个基本属性含义:
 *		private int mark = -1:标记，表示记录当前position的位置
 *							  可以通过reset()恢复到mark的位置
    	private int position = 0:位置，表示缓冲区中正在操作的数据的位置
    	private int limit:界限，表示缓冲区中可以操作数据的大小，limit后的数据不能进行读写
    	private int capacity:容量，表示缓冲区中最大存储数据的容量,一旦声明，不能改变
 *
 *		0 <= mark <= position <= limit <= capacity
 *
 *3.直接缓冲区，非直接缓冲区
 *	非直接缓冲区:通过allocate()方法分配缓冲区，将缓冲区建立在JVM当中
 *	直接缓冲区:通过allocateDirect()方法分配直接缓冲区，将缓冲区建立在物理内存中
 *
 *
 */
public class Buffer {
	
	@Test
	public void test03() {
		//1.建立直接缓冲区
		ByteBuffer buff = ByteBuffer.allocateDirect(1024);
		//2.判断是不是直接缓冲区
		System.out.println(buff.isDirect());
		
	}
	
	
	@Test
	public void test02() {
		String str = "asdfg";
		
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		
		buffer.put(str.getBytes());
		
		buffer.flip();
		
		byte[] bt =new byte[buffer.limit()];
		
		buffer.get(bt,0,2);
		
		System.out.println(new String(bt,0,2));
		
		System.out.println("位置为:"+buffer.position());
		
		//mark()标记
		buffer.mark();
		
		buffer.get(bt,2,2);
		
		System.out.println(new String(bt,2,2));
		
		System.out.println("位置为:"+buffer.position());
		
		//reset():恢复到mark的位置上
		buffer.reset();
		
		System.out.println("位置为:"+buffer.position());
		
		//判断缓冲区中是否还有剩余数据
		if (buffer.hasRemaining()) {
			//获取缓冲区中可以操作的数量
			System.out.println("剩余数量为"+buffer.remaining());
		}
	}

	@Test
	public void test01() {
		String str = "zhouqingkaiwenqingxin";
		//1.分配一个指定大小的缓冲区
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		System.out.println("==============初始化allocate方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		//2.使用put()方法存入数据到缓冲区中
		buffer.put(str.getBytes());
		
		System.out.println("==============执行put方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		//3.切换到读取数据模式
		buffer.flip();
		
		System.out.println("==============执行flip方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		//4.利用get方法读取缓冲区中的数据,读取到字节数组当中去
		byte[] bt = new byte[buffer.limit()];
		buffer.get(bt);
		System.out.println(new String(bt,0,bt.length));
		
		System.out.println("==============执行get方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		//5.rewind()方法:可重复读数据
		buffer.rewind();
		
		System.out.println("==============执行rewind方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		//6.清空缓冲区，但是缓冲区正宗的数据依然存在，但是处于被遗忘状态
		buffer.clear();
		
		System.out.println("==============执行clear方法==============");
		System.out.println("现在的位置:"+buffer.position());
		System.out.println("现在的界限:"+buffer.limit());
		System.out.println("现在的容量:"+buffer.capacity());
		
		
	}
}















