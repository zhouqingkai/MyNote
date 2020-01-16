package danyimoshi;

public class ehanshi {
	public static void main(String[] args) {
		Teacher teacher1 = Teacher.getTeacher();
		Teacher teacher2 = Teacher.getTeacher();
		System.out.println(teacher1==teacher2);
	}
}

/**
 * 单例模式：饿汉式7h* @author Lenovo
 *	定义成员变量定义为静态的final修饰的实体化对象
 *	同时构造器为简单构造器，加上super()，方法为静态方法返回在成员属性中创建的实例
 *
 */
class Teacher{
	private static final Teacher teacher =new Teacher();
	
	private Teacher() {
		super();
	}
	
	public static Teacher getTeacher() {
		return teacher;
	}
	
}