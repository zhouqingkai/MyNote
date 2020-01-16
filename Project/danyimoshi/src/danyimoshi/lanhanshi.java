package danyimoshi;

public class lanhanshi {
	public static void main(String[] args) {
		Student student1 = Student.getStudent();
		Student student2 = Student.getStudent();
		System.out.println(student1==student2);
		
	}
}

/**
 * 静态的成员变量，构造器私有化
 * @author Lenovo
 *	静态方法先判断属性是否为空，不为空加锁，监控器为此类的.class  文件
 *	创建对象的实例
 */

class Student{
	
	private static Student student;
	
	private Student() {
		System.out.println("123");
	}
	
	public static Student getStudent() {
		if (student==null) {
			synchronized(Student.class) {
				student=new Student();
			}
		}
		return student;
	}
	
}