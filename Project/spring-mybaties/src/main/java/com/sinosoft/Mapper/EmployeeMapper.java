package com.sinosoft.Mapper;

import com.sinosoft.Bean.Employee;

/**
 * Created by zhouqk on 2019/11/3.
 * 已经在主方法上面添加MapperScan注解
 */
public interface EmployeeMapper {

    public Employee getEmpById(Integer id);

    public void insertEmp(Employee emp);

}
