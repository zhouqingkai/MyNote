package com.sinosoft.Controller;

import com.sinosoft.Bean.Department;
import com.sinosoft.Bean.Employee;
import com.sinosoft.Mapper.DepartmentMapper;
import com.sinosoft.Mapper.EmployeeMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Created by zhouqk on 2019/11/1.
 */
@RestController
public class DeptController {
    @Autowired
    DepartmentMapper departmentMapper;

    @Autowired
    EmployeeMapper employeeMapper;

    @GetMapping("/dept/{id}")
    public Department getDept(@PathVariable("id")Integer id){
        return departmentMapper.getDeptById(id);
    }

    @GetMapping("/dept")
    public Department insertDept(Department dept){
        departmentMapper.insertDept(dept);
        return dept;
    }
    @GetMapping("/emp/{id}")
    public Employee getEmp(@PathVariable("id") Integer id){
        return employeeMapper.getEmpById(id);
    }
}
