package com.sinosoft;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@MapperScan(value="com.sinosoft.Mapper")
@SpringBootApplication
public class SpringMybatiesApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringMybatiesApplication.class, args);
	}

}
