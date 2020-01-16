package com.sionosoft.Repository;

import com.sionosoft.Dao.UserDao;
import com.sionosoft.Entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

/**
 * Created by zhouqk on 2019/11/3.
 */
//@RepositoryDefinition(domainClass = User.class,idClass = Integer.class)
public interface UserRepository extends JpaRepository<User,Integer>,
        JpaSpecificationExecutor<User>,UserDao{

    User getUserById(Integer id);

    User getByLastName(String lastName);

    //where lastName like ?% and id <?
    List<User> getByLastNameStartingWithAndIdLessThan(String lastName,Integer id);

    //where email in (?,?,?) or lastName like %?
    List<User> findByEmailInOrLastNameEndingWith(List<String> email,String lastName);

    //子查询，使用自己写的sql语句进行查询
    @Query("select p from User p where p.id = (select max(a.id) from User a)")
    User getMaxIdUser();

    /**
     * @Query注解传递参数的方法1：
     *      使用占位符
     * @return
     */
    @Query("select p from User p where p.lastName = ?1 and p.email =?2")
    List<User> para1Query1(String lastName,String email);
    /**
     * @Query注解传递参数的方法2：
     *      使用绑定参数名
     * @return
     */
    @Query("select p from User p where p.lastName = :lastName and p.email =:email")
    List<User> para1Query2(@Param("email") String email, @Param("lastName") String lastName);

    @Query("select p from User p where p.lastName like ?1 or p.email like ?2 ")
    List<User> para1Query3(String lastName,String email);

    //使用nativeQuery=true，使用sql语句进行查询
    @Query(value = "select count(id) from tbl_user",nativeQuery = true)
    long getTotalCount();

    //使用@Modifying进行数据更改
    @Modifying
    @Query("update User u set u.email= :email where id = :id")
    void updateUsereamil(@Param("id")Integer id,@Param("email")String eamil);

}
