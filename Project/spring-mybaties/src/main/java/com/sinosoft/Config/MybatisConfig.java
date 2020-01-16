package com.sinosoft.Config;


import org.apache.ibatis.session.Configuration;
import org.mybatis.spring.boot.autoconfigure.ConfigurationCustomizer;
import org.springframework.context.annotation.Bean;

/**
 * Created by zhouqk on 2019/11/1.
 */
@org.springframework.context.annotation.Configuration
public class MybatisConfig {
    /**
     * 设置mybaties驼峰命名转换
     * @return
     */
    @Bean
    public ConfigurationCustomizer configurationCustomizer(){
        return new ConfigurationCustomizer() {
            @Override
            public void customize(Configuration configuration) {
                configuration.setMapUnderscoreToCamelCase(true);
            }
        };
    }

}
