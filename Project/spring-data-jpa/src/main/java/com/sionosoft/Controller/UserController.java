package com.sionosoft.Controller;

import com.sionosoft.Entity.User;
import com.sionosoft.Repository.UserRepository;
import com.sionosoft.Service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.lang.Nullable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import javax.persistence.criteria.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Created by zhouqk on 2019/11/3.
 */
@RestController
public class UserController {
    @Autowired
    UserRepository userRepository;
    @Autowired
    UserService userService;

    @GetMapping("/user/{id}")
    public User getUser(@PathVariable("id") Integer id){
        User user = userRepository.getUserById(id);
        return user;
    }
    @GetMapping("/user")
    public User insertUser(User user){
        User insertUser = userRepository.save(user);
        return insertUser;
    }
    @GetMapping("/userName/{lastName}")
    public User getByLastName(@PathVariable("lastName")String lastName){
        User userByName = userRepository.getByLastName(lastName);
        return userByName;
    }
    @GetMapping("/byLastNameStartingWithAndIdLessThan")
    public User getByLastNameStartingWithAndIdLessThan(){
        List<User> byLastNameStartingWithAndIdLessThan = userRepository.getByLastNameStartingWithAndIdLessThan("wangwu", 22);
        return byLastNameStartingWithAndIdLessThan.get(0);
    }
    @GetMapping("/findByEmailInOrLastNameEndingWith")
    public void findByEmailInOrLastNameEndingWith(){
        List<User> findByEmailInOrLastNameEndingWith = userRepository.findByEmailInOrLastNameEndingWith(Arrays.asList("email","aa"),"dsad");
        System.out.println(findByEmailInOrLastNameEndingWith);
    }
    //子查询
    @GetMapping("/getMaxIdUser")
    public void getMaxIdUser(){
        User maxIdUser = userRepository.getMaxIdUser();
        System.out.println(maxIdUser);
    }
    //使用占位符
    @GetMapping("/para1Query1")
    public void para1Query1(){
        List<User> users = userRepository.para1Query1("wangwu", "aa");
        System.out.println(users);
    }
    //使用绑定参数的方法
    @GetMapping("/para1Query2")
    public void para1Query2(){
        List<User> users = userRepository.para1Query2("aa", "wangwu");
        System.out.println(users);
    }
    //模糊查询
    @GetMapping("/para1Query3")
    public void para1Query3(){
        List<User> users = userRepository.para1Query3("%wangwu%", "%aa%");
        System.out.println(users);
    }
    //原生的sql语句查询
    @GetMapping("/getTotalCount")
    public void getTotalCount(){
        long totalCount = userRepository.getTotalCount();
        System.out.println(totalCount);
    }
    //改删数据
    @GetMapping("/updateUsereamil")
    public void updateUsereamil(){
        userService.updateUsereamil();
    }
    //增加数据，使用CrudRepository接口方法
    @GetMapping("/saveUser")
    public void saveUser(){
        List<User> users = new ArrayList<>();
        for (int i = 1; i <= 200; i++) {
            User user = new User();
            user.setId(i);
            user.setLastName(i+"");
            user.setEmail(i+"email");

            users.add(user);
        }
        userService.saveUser(users);
    }

    //使用翻页接口进行翻页
    @GetMapping("/pagingAndSortingRespositoty")
    public void pagingAndSortingRespositoty(){
        int pageNo = 3;
        int pageSize = 10;
        //排序相关  sort封装了排序的信息
        //Order是具体针对于某一个属性进行升序还是降序
        Sort.Order order1 = Sort.Order.desc("id");
        Sort.Order order2 = Sort.Order.asc("email");

        Sort sort = Sort.by(order1,order2);

        PageRequest pageRequest = PageRequest.of(pageNo, pageSize,sort);
        Page<User> userPage = userRepository.findAll(pageRequest);
        System.out.println("总记录数："+userPage.getTotalElements());
        System.out.println("当前第几页"+userPage.getNumber());
        System.out.println("总页数"+userPage.getTotalPages());
        System.out.println("当前页面的List"+userPage.getContent());
        System.out.println("当前页面的记录数"+userPage.getNumberOfElements());
    }

    @GetMapping("/saveAndFlush")
    public void saveAndFlush(){
        User user = new User();
        user.setId(300);
        user.setEmail("zhouqk@qq.com");
        user.setLastName("zhouqk");

        userRepository.saveAndFlush(user);
    }

    /**
     * 实现带查询条件的分页：   id>5  的分页
     * 调用JpaSpecificationExecutor的Page<T> findAll(@Nullable Specification<T> var1, Pageable var2);
     * 方法
     * Specification封装了  JPA  Criteria  查询的条件
     * Pageable封装了请求分页的信息，例如：pageNo，pageSize，Sort
     */
    @GetMapping("/JpaSpecificationExecutor")
    public void JpaSpecificationExecutor(){
        int pageNo = 2;
        int pageSize = 10;
        PageRequest pageRequest = PageRequest.of(pageNo, pageSize);
        //通常使用Specification的匿名内部类
        Specification<User> specification = new Specification<User>() {
            /**
             *
             * @param root:代表查询的实体类
             * @param criteriaQuery:可以从中得到Root对象，即告知JPA  Criteria查询要查询哪一个
             *           实体类，还可以来增加查询条件，还可以结合EntityManager对象得到最终查询的
             *           TypeQuery对象
             * @param criteriaBuilder：用于创建Criteria相关对象的工厂，当然可以从中获取到Predicate
             *            对象
             * @return Predicate
             */
            @Nullable
            @Override
            public Predicate toPredicate(Root<User> root, CriteriaQuery<?> criteriaQuery, CriteriaBuilder criteriaBuilder) {
                Path path = root.get("id");
                Predicate predicate = criteriaBuilder.gt(path,100);
                return predicate;
            }
        };
        Page<User> userPage = userRepository.findAll(specification, pageRequest);
        System.out.println("总记录数："+userPage.getTotalElements());
        System.out.println("当前第几页"+userPage.getNumber());
        System.out.println("总页数"+userPage.getTotalPages());
        System.out.println("当前页面的List"+userPage.getContent());
        System.out.println("当前页面的记录数"+userPage.getNumberOfElements());
    }

    @GetMapping("/test")
    public void test(){
        userRepository.test();
    }



}
