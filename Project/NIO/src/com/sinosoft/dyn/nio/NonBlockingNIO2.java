package com.sinosoft.dyn.nio;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.util.Date;
import java.util.Iterator;
import java.util.Scanner;

import org.junit.Test;

public class NonBlockingNIO2 {

	@Test
	public void send() throws IOException {
		DatagramChannel dc = DatagramChannel.open();
		
		dc.configureBlocking(false);
		
		ByteBuffer buffer = ByteBuffer.allocate(1024);
		
		Scanner scan =new Scanner(System.in);
		
		while (scan.hasNext()) {
			String str =scan.next();
			buffer.put((new Date().toString()+":\n"+str).getBytes());
			buffer.flip();
			dc.send(buffer, new InetSocketAddress("127.0.0.1",8090));
			buffer.clear();
		}
		dc.close();
	}
	
	@Test
	public void receive() throws IOException {
		DatagramChannel dc = DatagramChannel.open();
		
		dc.configureBlocking(false);
		
		dc.bind(new InetSocketAddress(8090));
		
		Selector selector = Selector.open();
		
		dc.register(selector, SelectionKey.OP_READ);
		
		while (selector.select()>0) {
			Iterator<SelectionKey> it = selector.selectedKeys().iterator();
			
			while (it.hasNext()) {
				SelectionKey sk = it.next();
				if (sk.isReadable()) {
					ByteBuffer buffer = ByteBuffer.allocate(1024);
					dc.receive(buffer);
					buffer.flip();
					System.out.println(new String(buffer.array(),0,buffer.limit()));
					buffer.clear();
				}
			}
			
			it.remove();
		}
	}










}
