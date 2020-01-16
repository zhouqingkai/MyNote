package com.sinosoft.duixiang;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;

import org.junit.Test;

public class xuliehua {
	/**
	 * 序列化对象存入磁盘中
	 */
	@Test
	public void estObjectOutputStream() {
		Person person1 = new Person("zhangsan", 23);
		Person person2 = new Person("lisi", 23);
		ObjectOutputStream oos=null;
		try {
			 oos = new ObjectOutputStream(new FileOutputStream("person.txt"));
			 oos.writeObject(person1);
			 oos.flush();
			 oos.writeObject(person2);
			 oos.flush();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}finally {
			try {
				oos.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
	/**
	 */
	@Test
	public void testObjectInputStream() {
		ObjectInputStream ois=null;
		try {
			ois = new ObjectInputStream(new FileInputStream("person.txt"));
			Person p1=(Person)ois.readObject();
			System.out.println(p1);
			Person p2=(Person)ois.readObject();
			System.out.println(p2);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}finally {
			try {
				ois.close();
			} catch (Exception e2) {
				// TODO: handle exception
			}
		}
	}
	
}
/**
 * @author Lenovo
 *
 */
class Person implements Serializable{
	String name;
	Integer age;
	public Person(String name, Integer age) {
		super();
		this.name = name;
		this.age = age;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public Integer getAge() {
		return age;
	}
	public void setAge(Integer age) {
		this.age = age;
	}
	@Override
	public String toString() {
		return "Person [name=" + name + ", age=" + age + "]";
	}
	
}