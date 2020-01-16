package com.sinosoft.Mapper;

import com.sinosoft.Bean.Department;
import org.apache.ibatis.annotations.*;

/**
 * Created by zhouqk on 2019/11/1.
 * 这是一个操作数据库的Mapper
 *  或者不用这个注解，在Application上加上MapperScan注解也行
 *
 */
//@Mapper
public interface DepartmentMapper {

    @Select("select * from department where id=#{id}")
    public Department getDeptById(Integer id);

    @Delete("delete from department where id #{id}")
    public int deleteDeptById(Integer id);

    //将主键封装到返回的实体类对象中
    //适用于mysql自增序列@Options(useGeneratedKeys = true,keyProperty = "id")
    @Insert("insert into department(id,departmentname)values(id_sequence.nextval,#{departmentName})")
    public int insertDept(Department dept);

    @Update("update department set departmentname=#{departmentName} where id=#{id}")
    public int updateDept(Department dept);
}
