package com.sionosoft.Repository;

import com.sionosoft.Dao.UserDao;
import com.sionosoft.Entity.User;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 * Created by zhouqk on 2019/11/7.
 */
public class UserRepsotoryImpl implements UserDao {
    @PersistenceContext
    private EntityManager entityManager;


    @Override
    public void test() {
        User user = entityManager.find(User.class,33);
        System.out.println(user);
    }
}
