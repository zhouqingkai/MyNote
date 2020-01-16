package com.sionosoft.Entity;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * Created by zhouqk on 2019/11/5.
 */
@Table(name = "tbl_address")
@Entity
public class Address {
    @Id
    private Integer id;
    @Column//省略默认列名就是属性名
    private String province;
    @Column//省略默认列名就是属性名
    private String city;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getProvince() {
        return province;
    }

    public void setProvince(String province) {
        this.province = province;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    @Override
    public String toString() {
        return "Address{" +
                "id=" + id +
                ", province='" + province + '\'' +
                ", city='" + city + '\'' +
                '}';
    }
}
