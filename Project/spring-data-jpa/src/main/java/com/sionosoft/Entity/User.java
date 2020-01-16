package com.sionosoft.Entity;

import javax.persistence.*;

/**
 * Created by zhouqk on 2019/11/3.
 * 使用JPA注解配置映射关系
 */
@Entity//告诉JPA这是一个实体类(和数据表映射的类)
@Table(name = "tbl_user")//指定来和哪个数据表进行映射；如果省略那么默认是表名小写
public class User {
    @Id//主键
    //@GeneratedValue(strategy = GenerationType.IDENTITY)//自增主键
    private Integer id;
    @Column(name = "last_name",length = 50)//这是和数据表对应的一个列
    private String lastName;
    @Column//省略默认列名就是属性名
    private String email;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", lastName='" + lastName + '\'' +
                ", email='" + email + '\'' +
                '}';
    }
}
