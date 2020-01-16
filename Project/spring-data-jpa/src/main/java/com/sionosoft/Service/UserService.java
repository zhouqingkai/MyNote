package com.sionosoft.Service;

import com.sionosoft.Entity.User;
import com.sionosoft.Repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Created by zhouqk on 2019/11/5.
 */
@Service
public class UserService {
    @Autowired
    UserRepository userRepository;

    //更改操作
    @Transactional
    public void updateUsereamil(){
        userRepository.updateUsereamil(12,"updateEmai333333333");
    }
    //新增操作
    @Transactional
    public void saveUser(List<User> users){

        userRepository.saveAll(users);

    }

}
