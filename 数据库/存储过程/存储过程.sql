prompt PL/SQL Developer Export User Objects for user URP_AIA@FRFR.F3322.NET:702/ORCL
prompt Created by zhouqk on 2020年3月17日
set define off
spool 存储过程.log

prompt
prompt Creating procedure GROUP_AML_INS_LXADDRESS
prompt ==========================================
prompt
create or replace procedure group_aml_ins_lxaddress(
	i_dealno in lxaddress_temp.dealno%type,
	i_clientno in cr_address.clientno%type
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXADDRESS_TEMP表
  -- parameter in: i_dealno    交易编号(业务表)
  --               i_clientno  客户号
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     baishuai    2019/12/31 初版
  -- =============================================

  INSERT INTO LXADDRESS_TEMP (
    serialno,
		DealNo,
		ListNo,
		CSNM,
		Nationality,
		LinkNumber,
		Adress,
		CusOthContact,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
  (
		select
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,--保单号
			ROW_NUMBER () OVER (ORDER BY clientno) AS ListNo,--客户号
			A.clientno AS CSNM,--客户号
			A.nationality AS Nationality,--国籍
			A.linknumber AS LinkNumber,--联系电话
			A.adress AS Adress,--客户地址
			A.cusothcontact AS CusOthContact,--客户其他联系地址
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'hh24:mi:ss') AS MakeTime,
			'' AS ModifyDate,
			'' AS ModifyTime
		from
			GR_ADDRESS A
		where
			A.clientno = i_clientno
  );

  dbms_output.put_line('插入交易主体联系方式筛选辅助表--执行完毕');

end group_aml_ins_lxaddress;
/

prompt
prompt Creating procedure GROUP_AML_INS_LXISTRADEBNF
prompt =============================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_INS_LXISTRADEBNF (
	i_dealno in NUMBER,
	i_contno in VARCHAR2
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lLXISTRADEBNF_TEMP表
  -- parameter in: i_dealno 交易编号(业务表)
  --               i_contno 保单号
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/12/31  初版
  -- =============================================

  insert into LXISTRADEBNF_TEMP(
    serialno,
		DealNo,
		CSNM,
		InsuredNo,
		BnfNo,
		BNNM,
		BITP,
		OITP,
		BNID,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
(
			SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_contno AS CSNM,
			r.insureno AS InsuredNo,
			c.clientno AS BnfNo,
			c.NAME AS BNNM,
			c.cardtype AS BITP,
			nvl(c .OtherCardType, '@N') AS OITP,
      nvl((case c.cardtype when '营业执照号' then c.BUSINESSLICENSENO when '组织代码证号' then c.ORGCOMCODE  when '税务登记号' then c.TAXREGISTCERTNO else c.cardid end),'@N') as BNID,
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'HH:mm:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime
			FROM
					gr_client c,
					gr_rel r
			WHERE
					c.clientno = r.clientno
			AND r.custype = 'B'
			and r.contno=i_contno

  );
end GROUP_AML_INS_LXISTRADEBNF;
/

prompt
prompt Creating procedure GROUP_AML_INS_LXISTRADECONT
prompt ==============================================
prompt
create or replace procedure GROUP_AML_INS_LXISTRADECONT(
  i_dealno in varchar2,
  i_clientno in varchar2,
  i_contno in varchar2
) is
begin
  -- ============================================
  -- Description: 根据规则筛选结果更新LXISTRADECONT_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_clientno 客户号
  --               i_contno   保单号
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     baishuai    2019/12/31 初版
  -- ============================================

   --可疑交易合同信息筛选辅助表
  insert into LXISTRADECONT_TEMP(
    serialno,
    DealNo,
    CSNM,
    ALNM,
    AppNo,
    ContType,
    AITP,
    OITP,
    ALID,
    ALTP,
    ISTP,
    ISNM,
    RiskCode,
    Effectivedate,
    Expiredate,
    ITNM,
    ISOG,
    ISAT,
    ISFE,
    ISPT,
    CTES,
    FINC,
    DataBatchNo,
    MakeDate,
    MakeTime,
    ModifyDate,
    ModifyTime)
  (
    SELECT
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') AS DealNo,--交易编号
      i_contno AS CSNM,     --保单号
      (select c.name from gr_client ct,gr_rel rl where rl.clientno=ct.clientno and rl.custype='O' and rl.contno=r.contno) AS ALNM,--客户名
      (select c.clientno from gr_client ct,gr_rel rl where rl.clientno=ct.clientno and rl.custype='O' and rl.contno=r.contno) AS APPNO,--客户号
      p.conttype AS ContType,--团个险标志
      c.cardtype AS AITP,--证件类型
      nvl(c.OtherCardType,'@N') AS OITP,--其他证件类型
      --nvl(c.cardid,'@N') AS ALID,
     (case when c.cardtype='B' then c.BusinessLicenseNo
           when c.cardtype='O' then c.OrgComCode
           when c.cardtype='T' then c.TaxRegistCertNo
       end) AS ALID,--证件号
      c.clienttype AS ALTP,--客户类型
      (select risktype from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from gr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS ISTP,--险种类型
      (select riskname from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from gr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS ISNM,  --险种名称
      (select riskcode from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from gr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS RiskCode,--险种编码
      p.effectivedate AS Effectivedate,--生效日
      p.expiredate AS Expiredate,--终止日
      p.insuredpeoples AS ITNM,--被保险人数
      p.inssubject AS ISOG,--保险标的
      p.amnt AS ISAT,--保险金额
      p.prem AS ISFE,--保险费
      p.paymethod AS ISPT,--缴费方式
      nvl(p.othercontinfo, '@N') AS CTES,--保险合同其他信息
      p.locid AS FINC,--金融机构网点代码
      NULL AS DataBatchNo,
      to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') AS MakeDate,
      to_char(sysdate,'HH:mm:ss') AS MakeTime,
      NULL AS ModifyDate,
      NULL AS ModifyTime
      from
        GR_POLICY p,
        GR_CLIENT c,
        GR_REL r
      where
          p.contno=r.contno
      and c.clientno=r.clientno
      and r.custype='O'
      and r.contno=i_contno
  );

  dbms_output.put_line('插入可疑交易合同信息筛选辅助表--执行完毕');

end GROUP_AML_INS_LXISTRADECONT;
/

prompt
prompt Creating procedure GROUP_AML_INS_LXISTRADEDETAIL
prompt ================================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_INS_LXISTRADEDETAIL (
i_dealno in NUMBER,
	i_contno in VARCHAR2,
	i_transno in VARCHAR2,
	i_triggerflag in VARCHAR2
	) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXISTRADEDETAIL_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_ocontno  保单号
  --               i_transno  交易编号(平台表)
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/12/31  初版
  -- =============================================


  insert into LXISTRADEDETAIL_TEMP(
    serialno,
    DealNo,
		TICD,
		ICNM,
		TSTM,
		TRCD,
		ITTP,
		CRTP,
		CRAT,
		CRDR,
		CSTP,
		CAOI,
		TCAN,
		ROTF,
		DataState,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime,
		TRIGGERFLAG)
  (
    SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_transno AS TICD,
			i_contno AS ICNM,
			to_char(t.transdate,'yyyymmddHHmmss') AS TSTM,
			t.transfromregion AS TRCD,
			t.transtype AS ITTP,
			t.curetype AS CRTP,
			t.payamt AS CRAT,
			T.PAYWAY AS CRDR,
			T.PAYMODE AS CSTP,
			nvl(t.accbank,'@N') AS CAOI,
			nvl(t.accno,'@N') AS TCAN,
			nvl(t.remark, '@N') AS ROTF,
      'A01' as DataState,
			NULL  AS DataBatchNo,
		  to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') AS MakeDate,
			to_char(sysdate,'HH24:mi:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime,
			i_triggerflag AS TRIGGERFLAG
		from
			gr_trans t
		where
				t.contno = i_contno
		and t.transno = i_transno
  );

end GROUP_AML_INS_LXISTRADEDETAIL;
/

prompt
prompt Creating procedure GROUP_AML_INS_LXISTRADEINSURED
prompt =================================================
prompt
create or replace procedure GROUP_AML_INS_LXISTRADEINSURED(
	i_dealno in LXISTRADEINSURED_TEMP.Dealno%type,
	i_contno in LXISTRADEINSURED_TEMP.CSNM%type
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXISTRADEINSURED_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_contno   保单号
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     baishuai    2019/12/31  初版
  -- =============================================

  --可疑交易被保人信息筛选辅助表
  insert into LXISTRADEINSURED_TEMP(
    serialno,
		DEALNO,
		CSNM,
		INSUREDNO,
		ISTN,
		IITP,
		OITP,
		ISID,
		RLTP,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
(
    SELECT
      getSerialno(sysdate) as serialno,
 			LPAD(i_dealno,20,'0') AS DealNo,--交易编号
			i_contno AS CSNM,     --保单号
			c.clientno AS INSUREDNO, --客户号
			c.NAME AS ISTN,          --被保人姓名
			nvl(c.cardtype, '@N') AS IITP,--被保人证件类型
			nvl(c.OtherCardType, '@N') AS OITP,--其他证件类型
			c.cardid AS ISID,--证件号码
			nvl(r.relaappnt, '@N') AS RLTP,--投保人与被保险人关系
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'HH:mm:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime
			FROM
					gr_client c,
					gr_rel r
			WHERE
					c.clientno = r.clientno
			AND r.custype = 'I'
			AND r.contno = i_contno
  );

  dbms_output.put_line('插入可疑交易被保人信息筛选辅助表--执行完毕');

end GROUP_AML_INS_LXISTRADEINSURED;
/

prompt
prompt Creating procedure GROUP_AML_INS_LXISTRADEMAIN
prompt ==============================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_INS_LXISTRADEMAIN (
	i_dealno in NUMBER,
  i_clientno in varchar2,
  i_contno in varchar2,
  i_operator in varchar2,
  i_stcr in varchar2 ,
  i_baseLine in DATE) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lxistrademain_temp表
  -- parameter in: i_clientno 客户号
  --               i_dealno   交易编号
	--               i_operator 操作人
  --               i_stcr     可疑交易特征编码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     xn    2019/12/31  初版
  -- =============================================

  insert into lxistrademain_temp(
    serialno,
    dealno, -- 交易编号
    rpnc,   -- 上报网点代码
    detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
    torp,   -- 报送次数标志
    dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
    odrp,   -- 其他报送方向
    tptr,   -- 可疑交易报告触发点
    otpr,   -- 其他可疑交易报告触发点
    stcb,   -- 资金交易及客户行为情况
    aosp,   -- 疑点分析
    stcr,   -- 可疑交易特征
    csnm,   -- 客户号
    senm,   -- 可疑主体姓名/名称
    setp,   -- 可疑主体身份证件/证明文件类型
    oitp,   -- 其他身份证件/证明文件类型
    seid,   -- 可疑主体身份证件/证明文件号码
    sevc,   -- 客户职业或行业
    srnm,   -- 可疑主体法定代表人姓名
    srit,   -- 可疑主体法定代表人身份证件类型
    orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
    srid,   -- 可疑主体法定代表人身份证件号码
    scnm,   -- 可疑主体控股股东或实际控制人名称
    scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
    ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
    scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
    strs,   -- 补充交易标识
    datastate, -- 数据状态
    filename,  -- 附件名称
    filepath,  -- 附件路径
    rpnm,      -- 填报人
    operator,  -- 操作员
    managecom, -- 管理机构
    conttype,  -- 保险类型（01-个单, 02-团单）
    notes,     -- 备注
		baseline,       -- 日期基准
    getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入）
    nextfiletype,   -- 下次上报报文类型
    nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
    nextpackagetype,-- 下次上报报文包类型
    databatchno,    -- 数据批次号
    makedate,       -- 入库时间
    maketime,       -- 入库日期
    modifydate,     -- 最后更新日期
    modifytime,			-- 最后更新时间
		judgmentdate,   -- 终审日期
    ORXN,           -- 接续报告首次上报成功的报文名称
		ReportSuccessDate)-- 上报成功日期
(
    select
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') as dealno,
      '@N' as rpnc,
      '01' as detr,  -- 报告紧急程度（01-非特别紧急）
      '1' as torp,
      '01' as dorp,  -- 报送方向（01-报告中国反洗钱监测分析中心）
      '@N' as odrp,
      '01' as tptr,  -- 可疑交易报告触发点（01-模型筛选）
      '@N' as otpr,
      '' as stcb,
      '' as aosp,
      i_stcr as stcr,
      c.clientno as csnm,
      c.name as senm,
      nvl(c.cardtype,'@N') as setp,
      nvl(c.othercardtype,'@N') as oitp,
      --团单是取 营业执照号或组织代码证号或税务登记号
      nvl((case c.cardtype when '营业执照号' then c.BUSINESSLICENSENO when '组织代码证号' then c.ORGCOMCODE  when '税务登记号' then c.TAXREGISTCERTNO else c.cardid end),'@N') as seid,
      nvl(c.occupation,'@N') as sevc,
      nvl(c.legalperson,'@N') as srnm,
      nvl(c.legalpersoncardtype,'@N') as srit,
      nvl(c.otherlpcardtype,'@N') as orit,
      nvl(c.legalpersoncardid,'@N') as srid,
      nvl(c.holdername,'@N') as scnm,
      nvl(c.holdercardtype,'@N') as scit,
      nvl(c.otherholdercardtype,'@N') as ocit,
      nvl(c.holdercardid,'@N') as scid,
      '@N' as strs,
      'A01' as datastate,
      '' as filename,
      '' as filepath,
      (select username from lduser where usercode = i_operator) as rpnm,
      i_operator as operator,
      (select locid from gr_policy where contno=i_contno) as managecom,
      c.conttype as conttype,
      '' as notes,
      i_baseLine as baseline,
      '01' as getdatamethod,  -- 数据获取方式（01-系统抓取）
      '' as nextfiletype,
      '' as nextreferfileno,
      '' as nextpackagetype,
      null as databatchno,
      to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
      to_char(sysdate,'hh24:mi:ss') as maketime,
      null as modifydate,  -- 最后更新时间
      null as modifytime,
			null as judgmentdate,--终审日期
      null as ORXN,        -- 接续报告首次上报成功的报文名称
			null as ReportSuccessDate--上报成功日期
    from
      gr_client c
    where
     c.clientno = i_clientno
  );

end GROUP_AML_INS_LXISTRADEMAIN;
/

prompt
prompt Creating procedure GROUP_AML_A0101
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_A0101(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)

begin
  -- =============================================
  -- Rule:
  --  根据保单上的投保单位、被保险人、受益人（包括受益所有人）、股东、法人、单位负责人和第三方付款人/领款人的唯一业务主键匹配是否属于禁止类名单,即被系统抓取生成可疑交易
  --  统计维度: 保单
  --  唯一业务主键：
  --  投保单位：单位名称+证件类型+证件号码
  --  被保险人:
  --     1.证件类型如果是身份证：名字+证件号码；
  --     2.其他为：姓名+性别+出生日期+证件类型+证件号码
  --  受益人：
  --     1.证件类型如果是身份证：名字+证件号码，
  --     2.其他为：姓名+性别+出生日期+证件类型+证件号码
  --  股东：股东名称+证件类型+证件号码
  --  法人：法人名称+证件类型+证件号码
  --  负责人：负责人名称+证件类型+证件号码
  --      抽取条件：
  --        1) 抽取保单维度
  --          抽取前一天有收/付费交易的保单；
  --      抽取结果：
  --        1）抽取命中制裁名单的该保单客户作为投保人或被保人或受益人名下所有保单的收/付费的交易行为；
  --        2）报送数据格式同现有可疑交易格式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: xn
  -- Create date: 2020/01/07
  -- ============================================
dbms_output.put_line('开始执行团险规则A0101');
    -- 先清空临时表
  delete from Assist;
  
  insert into Assist(
       clientno,
       contno,
       transno,
       transdate,
       custype,
       args1, -- name
       args2, -- sex
       args3, -- birthday
       args4, -- cardtype
       args5, -- cardid
       args6, -- 股东
       args7,
       args8,
       args9, -- 法人
       args10,
       args11,
       args12,-- 负责人 
       args13,
       args14,
       mark   -- 标记
  )select 
       r.clientno,
       r.contno,
       t.transno,
       t.transdate,
       r.custype,
       
       c.name,
       c.sex,
       c.birthday,
       c.cardtype,
       c.cardid,
       
       c.holdername,             -- 股东
       c.holdercardtype,         
       c.holdercardid,
       
       c.legalperson,            -- 法人
       c.legalpersoncardtype,
       c.legalpersoncardid,
       
       c.satrap,                 -- 负责人
       c.satrapidtype,           
       c.satrapid,
                 
       'A0101_1'
    from 
       gr_client c, gr_rel r, gr_trans t
    where c.clientno = r.clientno
      and r.contno = t.contno
      and r.custype in ('O', 'I', 'B') -- 客户类型：O-投保人/I-被保人/B-受益人
      and t.payway in ('01', '02')
      and t.conttype = '2'             -- 保单类型：2-团单
      and trunc(t.transdate) = trunc(i_baseLine);
  
  -- 从辅助表中筛选数据
  
  -- 投保人
  insert into Assist(
       clientno,
       transno,
       contno,
       mark
  )
  select
       clientno,
       transno,
       contno,
       '投保人'
    from
       Assist a
    where
        a.custype = 'O'              -- 投保人
    and GR_isValidCont(a.contno)='yes'  -- 有效保单
    and a.mark = 'A0101_1'
    and exists(
        select 
             1 
          from 
            lxblacklist 
          where 
              source = '1'
          and isactive ='0'
          -- 投保人 
          and (name = a.args1 and cardtype = a.args4 and idnumber = a.args5)
           -- 股东
           or (name = a.args6 and cardtype = a.args7 and idnumber = a.args8)
           -- 法人
           or (name = a.args9 and cardtype = a.args10 and idnumber = a.args11)
           -- 负责人
           or (name = a.args12 and cardtype = a.args13 and idnumber = a.args14)
      );
      
  -- 被保人和受益人
  insert into Assist(
       clientno,
       transno,
       contno,
       mark
  )
  select
       -- 取投保人的客户号
       (select clientno from Assist where custype ='O' and transno = a.transno and contno = a.contno),
       transno,
       contno,
       '被保人和受益人'
    from
       Assist a
    where
        a.custype in ('I','B')       -- 被保人和受益人
    and GR_isValidCont(a.contno)='yes'    -- 有效保单
    and a.mark = 'A0101_1'
    and exists(
        select 
             1 
          from 
            lxblacklist 
          where 
              source = '1'
          and isactive ='0'
          -- 被保人或者受益人
          and (a.args4 = '110001' and name = a.args1 and idnumber = a.args5)
           -- 不是身份证
           or (name = a.args1 and sex = a.args2 and to_date(substr(birthday,1,10),'yyyy-MM-dd') = a.args3 
              
              and cardtype = a.args4 and idnumber = a.args5)
              
           -- 股东
           or (name = a.args6 and cardtype = a.args7 and idnumber = a.args8)
           -- 法人
           or (name = a.args9 and cardtype = a.args10 and idnumber = a.args11)
           -- 负责人
           or (name = a.args12 and cardtype = a.args13 and idnumber = a.args14)
      );
  
  
  

  declare
     cursor baseInfo_sor is
        select
            distinct
            clientno,
            transno,
            contno
          from
            Assist a
          where
              a.mark in ('投保人','被保人和受益人')
          order by clientno;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GA0101', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则A0101执行成功');
  delete from Assist a where a.mark in ( 'A0101_1','投保人','被保人和受益人');

  commit;
end Group_aml_A0101;
/

prompt
prompt Creating procedure GROUP_AML_A0102
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_A0102(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)

begin
  -- ============================================
  -- Rule:
  -- 客户与关注类名单匹配。其中，客户包括投保人、被保人、受益人、第三方付款人/领款人，
  --   以及团险中的受益所有人、股东和高级管理层等采集了身份信息的对象。
  -- 1) 统计维度：保单
  --     抓取前一天生效的有效保单及赔案信息
  --     根据保单上的投保单位、被保险人、受益人（包括受益所有人）、
  --     股东、法人、单位负责人和第三方付款人/领款人的唯一业务主键匹配是否属于关注类名单；
  --     唯一业务主键匹配规则参照"PNR系统场景列"；
  -- 2) 如果保单上的任意一项（自然人或单位）进入禁止类名单，则抓取该数据生成监测数据。
  -- 3) 其中：团险新核心系统：
  --     第三方付款人取"是否第三方委托缴纳"对应的开户名称；
  --     第三方领取人的判断：如果是保全退保的情况取除投保单位以外的领款人开户名称；
  --     如果是理赔支付的第三方领款人取除被保险人及受益人以外的其他人的开户名称，
  --     即：理赔领款人名称跟被保险人和受益人名称进行比较，都不一致为第三方领款人。
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/08
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/08     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则A0102');
    -- 先清空临时表
  delete from Assist;
  
  insert into Assist(
       clientno,
       contno,
       transno,
       transdate,
       custype,
       args1, -- name
       args2, -- sex
       args3, -- birthday
       args4, -- cardtype
       args5, -- cardid
       args6, -- 股东
       args7,
       args8,
       args9, -- 法人
       args10,
       args11,
       args12,-- 负责人 
       args13,
       args14,
       mark   -- 标记
  )select 
       r.clientno,
       r.contno,
       t.transno,
       t.transdate,
       r.custype,
       
       c.name,
       c.sex,
       c.birthday,
       c.cardtype,
       c.cardid,
       
       c.holdername,             -- 股东
       c.holdercardtype,         
       c.holdercardid,
       
       c.legalperson,            -- 法人
       c.legalpersoncardtype,
       c.legalpersoncardid,
       
       c.satrap,                 -- 负责人
       c.satrapidtype,           
       c.satrapid,
                 
       'A0102_1'
    from 
       gr_client c, gr_rel r, gr_trans t
    where c.clientno = r.clientno
      and r.contno = t.contno
      and r.custype in ('O', 'I', 'B') -- 客户类型：O-投保人/I-被保人/B-受益人
      and t.payway in ('01', '02')
      and t.conttype = '2'             -- 保单类型：2-团单
      and trunc(t.transdate) = trunc(i_baseLine);
  
  -- 从辅助表中筛选数据
  
  -- 投保人
  insert into Assist(
       clientno,
       transno,
       contno,
       mark
  )
  select
       clientno,
       transno,
       contno,
       '投保人'
    from
       Assist a
    where
        a.custype = 'O'              -- 投保人
    and GR_isValidCont(a.contno)='yes'  -- 有效保单
    and a.mark = 'A0102_1'
    and exists(
        select 
             1 
          from 
            lxblacklist 
          where 
              source = '2'
          and isactive ='0'
          -- 投保人 
          and (name = a.args1 and cardtype = a.args4 and idnumber = a.args5)
           -- 股东
           or (name = a.args6 and cardtype = a.args7 and idnumber = a.args8)
           -- 法人
           or (name = a.args9 and cardtype = a.args10 and idnumber = a.args11)
           -- 负责人
           or (name = a.args12 and cardtype = a.args13 and idnumber = a.args14)
      );
      
  -- 被保人和受益人
  insert into Assist(
       clientno,
       transno,
       contno,
       mark
  )
  select
       -- 取投保人的客户号
       (select clientno from Assist where custype ='O' and transno = a.transno and contno = a.contno),
       transno,
       contno,
       '被保人和受益人'
    from
       Assist a
    where
        a.custype in ('I','B')       -- 被保人和受益人
    and GR_isValidCont(a.contno)='yes'    -- 有效保单
    and a.mark = 'A0102_1'
    and exists(
        select 
             1 
          from 
            lxblacklist 
          where 
              source = '2'
          and isactive ='0'
          -- 被保人或者受益人
          and (a.args4 = '110001' and name = a.args1 and idnumber = a.args5)
           -- 不是身份证
           or (name = a.args1 and sex = a.args2 and to_date(birthday,'yyyy-MM-dd') = a.args3 
              
              and cardtype = a.args4 and idnumber = a.args5)
              
           -- 股东
           or (name = a.args6 and cardtype = a.args7 and idnumber = a.args8)
           -- 法人
           or (name = a.args9 and cardtype = a.args10 and idnumber = a.args11)
           -- 负责人
           or (name = a.args12 and cardtype = a.args13 and idnumber = a.args14)
      );
  
  
  

  declare
     cursor baseInfo_sor is
        select
            distinct
            clientno,
            transno,
            contno
          from
            Assist a
          where
              a.mark in ('投保人','被保人和受益人')
          order by clientno;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GA0102', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则A0102执行成功');
  delete from Assist a where a.mark in ( 'A0102_1','投保人','被保人和受益人');

  commit;
end Group_aml_A0102;
/

prompt
prompt Creating procedure GROUP_AML_A0200
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_A0200(
    i_baseLine IN DATE,
    i_oprater  IN VARCHAR2)
IS
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号(业务表)
  v_clientno gr_client.clientno%type;                       -- 客户号
  v_threshold_money NUMBER := getparavalue('GA0200', 'M1'); -- 阀值 累计保费金额
BEGIN
  -- =============================================
  -- Rule:
  -- 投保人的国籍属于高风险国家或地区，且累计已交保费金额大于等于阀值。
  --  1) 抽取保单维度
  --   1.抓取前一天生效的有效保单数据
  --2.根据保单的投保单位的国籍或地区字段匹配是否属于高风险国家或地区；
  --3.如果属于高风险国家或地区，统计该投保单位名下所有有效保单且累计已交保费（收/付费交易数据）大于等于阈值；
  --3.阈值配置为：100万
  --4.以上条件满足生成监测数据
  --数据来源：PNR
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2019/1/6
  -- Changes log:
  -- ============================================
  delete from lxassista;

    dbms_output.put_line('开始执行团险规则A0200');

--获取当天投保的投保人属于高风险国家或地区的保单信息
insert into lxassista
  (policyno,
   CustomerNo,
   args4, --交易编号
   args1, --投保企业名称
   args2, --证件号
   args3, --证件类型
   args5)
  select t.contno,
         r.clientno,
         t.transno,
         c.name,
         (case
           when c.CardType = 'B' then
            c.BusinessLicenseNo --营业执照号
           when c.CardType = 'O' then
            c.OrgComCode --组织代码证号
           else
            c.TaxRegistCertNo --税务登记号
         end),
         c.CardType,
         'A0200_1'
    from gr_client c，gr_rel r，gr_trans t
   where c.clientno = r.clientno
     and t.contno = r.contno
     and exists
   ( --高风险国家
          select 1
            from lxriskinfo lx
           where lx.code = c.nationality
             and lx.recordtype = '02' -- 风险类型：02-国家
             and lx.risklevel = '3' -- 风险等级：3-高风险等级
          )
     and GR_isValidCont(t.contno) = 'yes' -- 有效保单
     and t.payway = '01'  --收
     and r.custype = 'O' -- 客户类型：O-投保人
     and t.transtype = 'AA001' -- 交易类型为投保
     and t.source='1'  --1-PNR 
     and t.conttype = '2' -- 保单类型：2-团单
     and trunc(t.transdate) = trunc(i_baseLine);

--去重 :根据企业名称和证件号去重
insert into lxassista
  (args1, args2, args3, args5)
  select args1, args2, args3, 'A0200_2'
    from lxassista lx
   where lx.args5 = 'A0200_1'
   group by args2, args1, args3;

--获取投保人名下所有保单和该保单下的累计已交保费
insert into lxassista
  (policyno, numargs1, CustomerNo,args1, args2, args3, args5)
  select p.contno,
         p.SumPrem,    --累计已交保费
         r.clientno,
         c.name,
         (case
           when c.CardType = 'B' then
            c.BusinessLicenseNo --营业执照号
           when c.CardType = 'O' then
            c.OrgComCode --组织代码证号
           else
            c.TaxRegistCertNo --税务登记号
         end),
         c.CardType,
         'A0200_3'
    from gr_policy p, gr_rel r, gr_client c
   where p.contno = r.contno
     and r.clientno = c.clientno
     and exists
   (select 1
            from lxassista la
           where la.args1 = c.name
             and la.args3 = c.cardtype
             and (la.args2 = c.BusinessLicenseNo or la.args2 = c.OrgComCode or
                 la.args2 = c.TaxRegistCertNo)
             and la.args5 = 'A0200_2')
     and GR_isValidCont(p.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and p.source='1'  --1-PNR 
     and p.conttype = '2' -- 保单类型：2-团单
     order by r.clientno,p.contno desc;

--获取客户名下有效保单的累计投保金额大于100万的保单信息
   declare
   cursor baseInfo_sor is
          select 
             r.clientno,
             t.transno,
             t.contno
          from gr_trans t, gr_rel r, gr_client c
          where t.contno = r.contno
          and exists
          (select 1
                  from lxassista la
                  where 
                       la.args1 = c.name
                       and la.args3 = c.cardtype
                       and (la.args2 = c.BusinessLicenseNo or la.args2 = c.OrgComCode or
                       la.args2 = c.TaxRegistCertNo)
                       and la.args5 = 'A0200_3'
                       group by la.args1,la.args2, la.args3
                       having sum(la.numargs1) >= v_threshold_money)
     and r.clientno = c.clientno
     and t.payway = '01'  --收
     and GR_isValidCont(t.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and t.transtype = 'AA001' -- 交易类型为投保
     and t.source = '1' --1-PNR 2-RPAS 3-GTA
     and t.conttype = '2' -- 保单类型：1-个单
     order by r.clientno,t.contno desc;
   

    -- 定义游标变量
    c_clientno gr_client.clientno%type; -- 客户号
    c_contno gr_trans.contno%type;      -- 保单号
    c_tranid gr_trans.transno%type;     -- 交易号


  BEGIN
    OPEN baseInfo_sor;
    LOOP
      -- 获取当前游标值并赋值给变量
      FETCH baseInfo_sor INTO c_clientno, c_contno,c_tranid;
      EXIT
    WHEN baseInfo_sor%notfound; -- 游标循环出口
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      IF v_clientno IS NULL OR c_clientno <> v_clientno THEN
        v_dealNo    :=NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GA0200', i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_tranid,'1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号
      ELSE
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno ,c_tranid,'');
      END IF;
      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);
      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);
      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    END LOOP;
    CLOSE baseInfo_sor;
  END;
  DELETE FROM LXAssistA;
    dbms_output.put_line('团险规则A0200执行成功');
  commit;
END GROUP_AML_A0200;
/

prompt
prompt Creating procedure GROUP_AML_A0300
prompt ==================================
prompt
create or replace procedure GROUP_AML_A0300(i_baseLine in date,
                                           i_oprater  in varchar2) is
  v_threshold_money NUMBER := getparavalue('GA0300', 'M1'); -- 阀值 累计保费金额
  v_dealNo   lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno gr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --  高风险客户在保单存续期间，发生加保、追加保费、退保、贷款、提取现金价值等资金进出公司的请况且达到阈值，不包括正常给付和缴纳保费。
  --"规则处理逻辑同个险
  --反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天生效的有效保单数据
  --2.根据保单的投保单位的行业分类字段匹配是否属于高风险行业客户；
  --3.如果属于高风险行业客户，统计该投保单位名下所有有效保单且累计已交保费（收/付费交易数据）大于等于阈值；
  --4.阈值配置为：100万，实现可配置形式
  --5.以上条件满足生成监测数据"
  --数据来源：RPAS、PNR
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/09
  -- ============================================
dbms_output.put_line('开始执行团险规则A0300');

DELETE FROM LXAssistA;

--获取投保人投保当天,投保企业所在行业的风险等级为高风险的保单
insert into lxassista
  (policyno,
   CustomerNo,
   args4, --交易编号
   args1, --投保企业名称
   args2, --证件号
   args3, --证件类型
   args5)
  select t.contno,
         r.clientno,
         t.transno,
         c.name,
         (case
           when c.CardType = 'B' then
            c.BusinessLicenseNo --营业执照号
           when c.CardType = 'O' then
            c.OrgComCode --组织代码证号
           else
            c.TaxRegistCertNo --税务登记号
         end),
         c.CardType,
         'A0300_01'
    from gr_trans t, gr_rel r, gr_client c
   where t.contno = r.contno
     and exists
   ( --投保企业行业为高风险行业
          select 1
            from lxriskinfo lx
           where lx.code = c.BusinessType
             and lx.recordtype = '04'
             and lx.risklevel = '3')
     and r.clientno = c.clientno
     and t.payway = '01'  --收
     and GR_isValidCont(t.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and t.transtype = 'AA001' -- 交易类型为投保
     and t.source in ('2','1') --1-PNR 2-RPAS 3-GTA
     and t.conttype = '2' -- 保单类型：1-个单
     and trunc(t.transdate) = trunc(i_baseLine);

--去重
insert into lxassista
  (args1, args2, args3, args5)
  select args1, args2, args3, 'A0300_02'
    from lxassista lx
   where lx.args5 = 'A0300_01'
   group by args2, args1, args3;

--获取投保人名下所有保单
insert into lxassista
  (policyno, numargs1, CustomerNo,args1, args2, args3, args5)
  select p.contno,
         p.SumPrem,    --累计已交保费
         r.clientno,
         c.name,
         (case
           when c.CardType = 'B' then
            c.BusinessLicenseNo --营业执照号
           when c.CardType = 'O' then
            c.OrgComCode --组织代码证号
           else
            c.TaxRegistCertNo --税务登记号
         end),
         c.CardType,
         'A0300_03'
    from gr_policy p, gr_rel r, gr_client c
   where p.contno = r.contno
     and r.clientno = c.clientno
     and exists
   (select 1
            from lxassista la
           where la.args1 = c.name
             and la.args3 = c.cardtype
             and (la.args2 = c.BusinessLicenseNo or la.args2 = c.OrgComCode or
                 la.args2 = c.TaxRegistCertNo)
             and la.args5 = 'A0300_02')
     and GR_isValidCont(p.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and p.source in ('2','1') --1-PNR 2-RPAS 3-GTA
     and p.conttype = '2' -- 保单类型：1-个单
     order by r.clientno;

--获取客户名下有效保单的累计投保金额大于100万的保单信息
declare
   cursor baseInfo_sor is
          select 
             r.clientno,
             t.transno,
             t.contno
          from gr_trans t, gr_rel r, gr_client c
          where t.contno = r.contno
          and exists
          (select 1
                  from lxassista la
                  where 
                       la.args1 = c.name
                       and la.args3 = c.cardtype
                       and (la.args2 = c.BusinessLicenseNo or la.args2 = c.OrgComCode or
                       la.args2 = c.TaxRegistCertNo)
                       and la.args5 = 'A0300_03'
                       group by la.args1,la.args2, la.args3
                       having sum(la.numargs1) >= v_threshold_money)
     and r.clientno = c.clientno
     and t.payway = '01'  --收
     and GR_isValidCont(t.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and t.transtype = 'AA001' -- 交易类型为投保
     and t.source in ('2','1') --1-PNR 2-RPAS 3-GTA
     and t.conttype = '2' -- 保单类型：1-个单
     order by r.clientno,t.contno desc;

    -- 定义游标变量
    g_clientno  gr_client.clientno%type; -- 客户号
    g_transno   gr_trans.transno%type; -- 交易号
    g_contno    gr_trans.contno%type; -- 保单号

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor
        into g_clientno, g_transno, g_contno;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表
      if v_clientno is null or g_clientno <> v_clientno then

        v_dealNo   := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        v_clientno := g_clientno; -- 更新可疑主体的客户号

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        GROUP_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   g_clientno,
                                   g_contno,
                                   i_oprater,
                                   'GA0300',
                                   i_baseLine);

        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '1');
      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, g_clientno, g_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, g_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, g_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, g_clientno);

    end loop;
    close baseInfo_sor;
  end;
  DELETE FROM LXAssistA;
    dbms_output.put_line('团险规则A0300执行成功');
  commit;
END GROUP_AML_A0300;
/

prompt
prompt Creating procedure GROUP_AML_A0801
prompt ==================================
prompt
create or replace procedure GROUP_AML_A0801(i_baseLine in date,
                                           i_oprater  in varchar2) is
  v_dealNo   lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno gr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --  系统评定为超高风险客户的投保行为。
  --"规则处理逻辑同个险
  --反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天生效的有效保单数据
  --2.根据保单的投保单位唯一业务主键匹配客户名单是否为超高风险客户，如果是，系统生成可疑数据。"
  --数据来源：RPAS、GTA、PNR
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/09
  -- ============================================
dbms_output.put_line('开始执行团险规则A0801');

declare
   cursor baseInfo_sor is
   select r.clientno, t.transno, t.contno
   from gr_trans t, gr_rel r
   where t.contno = r.contno
         and exists
             (select 1
              from lxriskinfo lx
              where lx.CODE = r.clientno
              and lx.RECORDTYPE = '01'
              and lx.RISKLEVEL = '4')
        and GR_isValidCont(t.contno) = 'yes' -- 有效保单
        and t.payway = '01'  --收
        and r.custype = 'O' -- 客户类型：O-投保人
        and t.transtype = 'AA001' -- 交易类型为投保
        and t.source in ('3','2','1') --1-PNR 2-RPAS 3-GTA
        and t.conttype = '2' -- 保单类型：2-团单
        and trunc(t.transdate) = trunc(i_baseLine)
       
        order by r.clientno, t.transdate desc;

    -- 定义游标变量
    g_clientno  gr_client.clientno%type; -- 客户号
    g_transno   gr_trans.transno%type; -- 交易号
    g_contno    gr_trans.contno%type; -- 保单号

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor
        into g_clientno, g_transno, g_contno;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表
      if v_clientno is null or g_clientno <> v_clientno then

        v_dealNo   := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        v_clientno := g_clientno; -- 更新可疑主体的客户号

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        GROUP_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   g_clientno,
                                   g_contno,
                                   i_oprater,
                                   'GA0801',
                                   i_baseLine);

        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '1');
      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, g_clientno, g_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, g_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, g_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, g_clientno);

    end loop;
    close baseInfo_sor;
  end;
    dbms_output.put_line('团险规则A0801执行成功');
  commit;
END GROUP_AML_A0801;
/

prompt
prompt Creating procedure GROUP_AML_A0802
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_A0802 (i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_clientno gr_client.clientno%type;                         -- 客户号
BEGIN
  -- =============================================
  -- Rule:
  -- 超高风险客户在保单存续期间，发生加保、追加保费、退保、贷款、提取现金价值等资金进出公司的请况，排除正常给付和缴纳保费。
  --"反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天生效的有效保单数据
  --2.根据保单的投保单位唯一业务主键匹配客户名单是否为超高风险客户；
  --3.如果是，根据有效保单的保全项目类型判断该客户是否发生加保，减人、整单退保，提取现金价值（RPAS）行为，如发生以上保全项，生成可疑数据。

  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- i_oprater 操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/09
  -- Changes log:
  --     Author     Date     Description
  -- =============================================
 dbms_output.put_line('开始执行团险规则A0802');

  DECLARE
  -- 定义游标：同一投保单位半年内付费类保全项目付至同一第三方账户到达3次及以上
  cursor baseInfo_sor is
         select r.clientno, t.transno, t.contno
         from gr_trans t, gr_rel r, gr_policy p
         where t.contno = r.contno
               and r.contno = p.contno
               and exists
                   ( --- 1超高风险客户
                     select 1
                     from lxriskinfo rinfo
                     where r.clientno = rinfo.code
                     and rinfo.recordtype = '01' -- 风险类型：01-客户级别风险等级
                     and rinfo.risklevel = '4' -- 风险等级：4-超高风险等级
                    )
               and GR_isvalidcont(t.contno) = 'yes'
               and t.payway in ('01', '02') -- 存在支付方式为收和付
               and r.custype = 'O' -- 客户类型：O-投保单位
               and (t.transtype in ('NI','ZT','CT') or t.transtype in(select code from ldcode where codetype ='transtype_thirdparty')) --加保，减人、整单退保，提取现金价值（RPAS）行为,排除正常给付和缴纳保费。
               and t.conttype = '2' -- 保单类型：2-团单
               and t.source in ('2','1')     --1-PNR 2-RPAS 3-GTA
               and trunc(t.transdate) >= trunc(p.effectivedate) -- 交易日期>=保单生效日
               and trunc(t.transdate) < trunc(p.expiredate) -- 交易日期<保单终止日
               and trunc(t.transdate) = trunc(i_baseLine)
               order by r.clientno, t.transdate desc;


     -- 定义游标变量
      c_clientno gr_client.clientno%type;   -- 客户号
      c_transno gr_trans.transno%type;      -- 客户身份证件号码
      c_contno gr_trans.contno%type;        -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'GA0802', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
         GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
         GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
         GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

 dbms_output.put_line('团险规则A0802执行成功');
  commit;

END GROUP_AML_A0802;
/

prompt
prompt Creating procedure GROUP_AML_A0900
prompt ==================================
prompt
create or replace procedure GROUP_AML_A0900(i_baseLine in date,
                                           i_oprater  in varchar2) is
  v_threshold_money NUMBER := getparavalue('GA0900', 'M1'); -- 阀值 累计保费金额
  v_dealNo   lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno gr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --高风险客户在保单存续期间，发生加保、追加保费、退保、贷款、提取现金价值等资金进出公司的请况且达到阈值，不包括正常给付和缴纳保费。
  --"反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天生效的有效保单数据
  --2.根据保单的投保单位唯一业务主键匹配客户名单是否为高风险客户；
  --3.如果是，根据保单的保全项目类型判断该客户是否发生加保，减人、整单退保，提取现金价值，如发生以上保全项，统计该投保单位下所有保单累计已交保费大于等于阈值，则生成可疑数据。
  --4.阈值配置为：200万，实现可配置形式
  --数据来源：RPAS、PNR
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/09
  -- ============================================
dbms_output.put_line('开始执行团险规则A0900');

delete from lxassista;

--获取当天保单类型是加保，减人、整单退保，提取现金价值的高风险客户保单信息
insert into lxassista
  (tranid, policyno, customerno, args5)
  select t.transno, t.contno, r.clientno, 'GR_A0900_1'
    from gr_trans t, gr_rel r, gr_policy p
   where t.contno = r.contno
     and r.contno = p.contno
     and exists
   ( --客户属于高风险客户
          select 1
            from lxriskinfo lx
           where lx.code = r.clientno
             and lx.recordtype = '01'
             and lx.risklevel = '3')
     and GR_isValidCont(t.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人
     and t.payway in ('01', '02') -- 存在资金进出
     and (t.transtype in ('NI','ZT','CT') or t.transtype in(select code from ldcode where codetype ='transtype_thirdparty')) --加保，减人、整单退保，提取现金价值（RPAS）行为,排除正常给付和缴纳保费。
     and trunc(t.transdate) >= trunc(p.effectivedate) -- 交易日期>=保单生效日
     and trunc(t.transdate) < trunc(p.expiredate) -- 交易日期<保单终止日
     and t.source in ('2','1')--1-PNR 2-RPAS 3-GTA
     and t.conttype = '2' -- 保单类型：2-团单
     and trunc(t.transdate) = trunc(i_baseLine)
     order by r.clientno, t.contno desc;

--获取上步中的投保单位
insert into lxassista
  (args1, args2, args3, args5)
  select distinct c.name,
                  c.cardtype,
                  (case
                    when c.CardType = 'B' then
                     c.BusinessLicenseNo --营业执照号
                    when c.CardType = 'O' then
                     c.OrgComCode --组织代码证号
                    else
                     c.TaxRegistCertNo --税务登记号
                  end),
                  'GR_A0900_2'
    from lxassista lx, gr_client c
   where lx.customerno = c.clientno
     and lx.args5 = 'GR_A0900_1';


 --获取第二步中的投保单位下的所有保单
insert into lxassista
  (numargs1, customerno, policyno, args1, args2, args3, args5)
  select p.sumprem,    --交易金额
         c.clientno, --客户号
         p.contno, --保单号
         c.name, --公司名称
         c.cardtype, --证件类型
         ( --证件号码
         case
           when c.CardType = 'B' then
            c.BusinessLicenseNo --营业执照号
           when c.CardType = 'O' then
            c.OrgComCode --组织代码证号
           else
            c.TaxRegistCertNo --税务登记号
         end),
         'GR_A0900_3'
    from gr_policy p, gr_client c, gr_rel r
   where p.contno = r.contno
     and c.clientno = r.clientno
     and exists(select 1 from lxassista lx
           where lx.args1 = c.name
             and lx.args2 = c.cardtype
             and (lx.args3 = c.BusinessLicenseNo or lx.args3 = c.OrgComCode or
                 lx.args3 = c.TaxRegistCertNo)
             and lx.args5 = 'GR_A0900_2')
     and GR_isValidCont(p.contno) = 'yes' -- 有效保单
     and r.custype = 'O' -- 客户类型：O-投保人   
     and p.source in ('2','1')--1-PNR 2-RPAS 3-GTA
     and p.conttype = '2' -- 保单类型：2-团单
     order by c.clientno,p.contno desc;

--获取超过阀值的当天保单
declare
   cursor baseInfo_sor is
select lx.customerno,lx.tranid, lx.policyno
  from lxassista lx, gr_client c
 where lx.customerno = c.clientno
   and exists( --累计保费超过阀值
        select 1
          from lxassista la
         where c.name = la.args1
           and c.cardtype = la.args2
           and (la.args3 = c.BusinessLicenseNo or la.args3 = c.OrgComCode or
               la.args3 = c.TaxRegistCertNo)
           and la.args5 = 'GR_A0900_3'
         group by la.args1, la.args3
        having sum(la.numargs1) >= v_threshold_money
        )
   and lx.args5 = 'GR_A0900_1'
   order by lx.customerno desc;



    -- 定义游标变量
    g_clientno  gr_client.clientno%type; -- 客户号
    g_transno   gr_trans.transno%type; -- 交易号
    g_contno    gr_trans.contno%type; -- 保单号

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor
        into g_clientno, g_transno, g_contno;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表
      if v_clientno is null or g_clientno <> v_clientno then

        v_dealNo   := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        v_clientno := g_clientno; -- 更新可疑主体的客户号

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        GROUP_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   g_clientno,
                                   g_contno,
                                   i_oprater,
                                   'GA0900',
                                   i_baseLine);

        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '1');
      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, g_contno, g_transno, '');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, g_clientno, g_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, g_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, g_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, g_clientno);

    end loop;
    close baseInfo_sor;
  end;
    dbms_output.put_line('团险规则A0900执行成功');

    delete from lxassista;
  commit;
END GROUP_AML_A0900;
/

prompt
prompt Creating procedure GROUP_AML_B0101
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_B0101(
    i_baseLine IN DATE,
    i_oprater  IN VARCHAR2)
IS
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号(业务表)
  v_clientno gr_client.clientno%type;                       -- 客户号
  v_threshold_money NUMBER := getparavalue('GB0101', 'M1'); -- 阀值 累计保费金额
  v_threshold_month NUMBER := getparavalue('GB0101', 'D1'); -- 阀值 自然月
  v_threshold_count NUMBER := getparavalue('GB0101', 'N1'); -- 阀值 变更次数
BEGIN
  -- =============================================
  -- Rule:
  -- 投保单位3个月内变更超过三次（不包括三次）联系电话，且该投保单位作为投保人的所有有效保单且累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --  1) 抽取保单维度
  --     抓取前一天生效的有效保单数据;
  --     期限为3个月的判断逻辑为系统当前时间跟保全变更申请时间是否在3个月内
  --     变更联系电话仅统计手机号的变更次数，且同一投保人变更多张保单手机号，变更后手机号相同的，将变更次数进行合并记为一次变更；
  --     满足3个月内变更3次及以上的投保单位，统计该投保单位下所有有效保单的累计已交保费总额大于等于阀值，则生成可疑数据
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 阈值配置：已交保费为200万，期限为3个月，次数为3次，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: XN
  -- Create date: 2019/12/30
  -- Changes log:
  -- ============================================
    dbms_output.put_line('开始执行团险规则B0101');
  INSERT INTO LXAssistA
    (CustomerNo,
     TranId,
     PolicyNo,
     TranMoney,
     Trantime,
     args1,
     args2,
     args4,
     args5)
    SELECT r.clientno,
           t.transno,
           t.contno,
           (SELECT p.sumprem FROM gr_policy p WHERE p.contno = t.contno) AS sumprem,
           t.transdate,
           t.transtype,
           td.ext1,
           td.ext2,
           'GB0101_1'
      FROM gr_trans t, gr_rel r, gr_transdetail td
     WHERE t.contno = r.contno
       AND t.contno = td.contno
       AND t.transno = td.transno
       AND EXISTS
     (SELECT 1
              FROM gr_trans tmp_t, gr_rel tmp_r
             WHERE r.clientno = tmp_r.clientno
               AND tmp_t.contno = tmp_r.contno
               and exists
             (select 1
                      from gr_transdetail tmp_td
                     where tmp_td.contno = tmp_t.contno
                       and tmp_td.transno = tmp_t.transno
                       and tmp_td.remark = '投保人联系电话')
               AND tmp_r.custype = 'O' -- 投保人
               AND tmp_t.transtype = 'AC'
               AND tmp_t.conttype = '2' -- 团单
               AND TRUNC(tmp_t.transdate) = TRUNC(i_baseline))
       AND GR_isValidCont(t.contno) = 'yes'
       AND r.custype = 'O' --同一投保人
       AND td.remark = '投保人联系电话'
       AND t.transtype = 'AC'
       AND t.conttype = '2'
       AND TRUNC(t.transdate) <= TRUNC(i_baseline)
       AND TRUNC(t.transdate) >
           TRUNC(add_months(i_baseline, v_threshold_month * (-1))); --当前时间的前3个月                                  --当前时间
  
  --同一投保人3个月内3次（不包括3）以上变更联系电话，累计已交保费大于阀值
  DECLARE
    CURSOR baseInfo_sor
    IS
    SELECT CustomerNo, PolicyNo, TranId
      FROM LXAssistA a
     WHERE EXISTS (SELECT 1
              FROM LXAssistA tmp
             WHERE tmp.customerno = a.customerno
             GROUP BY tmp.customerno
            HAVING -- 保证变更为同一联系电话不算入次数
            COUNT(DISTINCT tmp.args4) > v_threshold_count)
       AND ( -- 计算名下所有有效保单累计已交保费总额
            SELECT SUM(NVL(p.sumprem, 0))
              FROM gr_rel r, gr_policy p
             WHERE r.clientno = a.customerno
               AND r.contno = p.contno
               AND GR_isValidCont(r.contno) = 'yes'
               AND r.custype = 'O') >= v_threshold_money
       AND args5 = 'GB0101_1'
     ORDER BY a.customerno, a.Trantime;
      
      
    -- 定义游标变量
    c_clientno gr_client.clientno%type; -- 客户号
    c_contno gr_trans.contno%type;      -- 保单号
    c_tranid gr_trans.transno%type;     -- 交易号
    
    
  BEGIN
    OPEN baseInfo_sor;
    LOOP
      -- 获取当前游标值并赋值给变量
      FETCH baseInfo_sor INTO c_clientno, c_contno,c_tranid;
      EXIT
    WHEN baseInfo_sor%notfound; -- 游标循环出口
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      IF v_clientno IS NULL OR c_clientno <> v_clientno THEN
        v_dealNo    :=NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GB0101', i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_tranid,'1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号
      ELSE
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno ,c_tranid,'');
      END IF;
      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);
      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);
      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    END LOOP;
    CLOSE baseInfo_sor;
  END;
  DELETE FROM LXAssistA WHERE args5 IN ('GB0101_1');
    dbms_output.put_line('团险规则B0101执行成功');
  commit;
END GROUP_AML_B0101;
/

prompt
prompt Creating procedure GROUP_AML_B0102
prompt ==================================
prompt
create or replace procedure GROUP_AML_B0102(i_baseLine in date, i_oprater in varchar2)
is
    v_dealNo lxistrademain.dealno%type; -- 交易编号(业务表)
    v_clientno gr_client.clientno%type; -- 客户号

    v_threshold_money number := getparavalue('GB0102', 'M1'); -- 阀值 累计保费金额
    v_threshold_month number := getparavalue('GB0102', 'D1'); -- 阀值 自然月
    v_threshold_count number := getparavalue('GB0102', 'N1'); -- 阀值 变更次数
    
BEGIN
  -- =============================================
  -- Rule:
  -- 投保单位3个月内变更超过三次（不包括三次）通信地址，且该投保单位作为投保人的所有有效保单且累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --  1) 抽取保单维度
  --     抓取前一天生效的有效保单数据;
  --     期限为3个月的判断逻辑为系统当前时间跟保全变更申请时间是否在3个月内
  --     变更通信地址仅统计手机号的变更次数，且同一投保单位变更多张保单通信地址，变更后通信地址相同的，将变更次数进行合并记为一次变更；
  --     满足3个月内变更3次及以上的投保单位，统计该投保单位下所有有效保单的累计已交保费总额大于等于阀值，则生成可疑数据
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 阈值配置：已交保费为200万，期限为3个月，次数为3次，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: XN
  -- Create date: 2019/12/30
  -- Changes log:
  -- ============================================
      dbms_output.put_line('开始执行团险规则B0102');
  INSERT INTO LXAssistA
    (
      CustomerNo,
      TranId,
      PolicyNo,
      TranMoney,
      Trantime,
      args1,
      args2,
      args4,         --  ext2   用于判断次数
      args5          -- 'B0102_1'
    )
     SELECT r.clientno,
       t.transno,
       t.contno,
       (SELECT p.sumprem FROM gr_policy p WHERE p.contno = t.contno) AS sumprem,
       t.transdate,
       t.transtype,
       td.ext1,
       td.ext2,
       'GB0102_1'
     FROM gr_trans t,
          gr_rel r,
          gr_transdetail td
     WHERE t.contno = r.contno
           AND t.contno   = td.contno
           AND t.transno  = td.transno
           AND EXISTS  (
              SELECT 1
                 FROM gr_trans tmp_t, gr_rel tmp_r
                 WHERE r.clientno = tmp_r.clientno
                      AND tmp_t.contno = tmp_r.contno
                      and exists
                         (select 1
                             from gr_transdetail tmp_td
                             where tmp_td.contno = tmp_t.contno
                              and tmp_td.transno = tmp_t.transno
                              and tmp_td.remark = '投保人通讯地址')
                      AND tmp_r.custype = 'O' -- 投保人
                      AND tmp_t.transtype = 'AC'
                      AND tmp_t.conttype = '2' -- 团单
                      AND TRUNC(tmp_t.transdate) = TRUNC(i_baseline))        
       AND r.custype            ='O' --同一投保人
       AND td.remark           = '投保人通讯地址'
       AND t.transtype         ='AC'
       AND t.conttype           ='2'
       AND GR_isValidCont(t.contno)='yes'
       AND TRUNC(t.transdate)   > TRUNC(add_months(i_baseLine,v_threshold_month*(-1))) --当前时间的前3个月
       AND TRUNC(t.transdate)   <= TRUNC(i_baseLine);                                    --当前时间
       
  --同一投保单位3个月内3次（不包括3）以上变更通信地址，累计已交保费大于阀值
  DECLARE
    CURSOR baseInfo_sor
    IS
      SELECT CustomerNo,
        PolicyNo,
        TranId
      FROM LXAssistA a
      WHERE EXISTS
        (SELECT 1
        FROM LXAssistA tmp
        WHERE tmp.customerno = a.customerno
        GROUP BY tmp.customerno
        HAVING -- 保证变更为同一通信地址不算入次数
          COUNT(DISTINCT tmp.args4) > v_threshold_count
        )
    AND ( -- 计算名下所有有效保单累计已交保费总额 
      SELECT SUM(NVL(p.sumprem,0))
      FROM gr_rel r,
        gr_policy p
      WHERE r.clientno          = a.customerno
      AND r.contno              = p.contno
      AND GR_isValidCont(r.contno) = 'yes'
      AND r.custype             ='O') >= v_threshold_money
    and args5 = 'GB0102_1'
    ORDER BY a.customerno,
      a.Trantime;
    -- 定义游标变量
    c_clientno gr_client.clientno%type; -- 客户号
    c_contno gr_trans.contno%type;      -- 保单号
    c_tranid gr_trans.transno%type;      -- 交易号
     
  BEGIN
    OPEN baseInfo_sor;
    LOOP
      -- 获取当前游标值并赋值给变量
      FETCH baseInfo_sor INTO c_clientno, c_contno,c_tranid;
      EXIT
    WHEN baseInfo_sor%notfound; -- 游标循环出口
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      IF v_clientno IS NULL OR c_clientno <> v_clientno THEN
        v_dealNo    :=NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
       GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GB0102', i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
       GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_tranid,'1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号
      ELSE
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno ,c_tranid,'');
      END IF;
      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);
      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);
      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    END LOOP;
    CLOSE baseInfo_sor;
  END;
    delete from LXAssistA where args5 in ('GB0102_1');
   dbms_output.put_line('团险规则B0102执行成功');
  commit;
END GROUP_AML_B0102;
/

prompt
prompt Creating procedure GROUP_AML_B0103
prompt ==================================
prompt
create or replace procedure GROUP_AML_B0103(i_baseLine in date, i_oprater in varchar2) is

    v_threshold_money number := getparavalue('GB0103', 'M1'); -- 阀值 累计保费金额
		v_threshold_month number := getparavalue('GB0103', 'D1'); -- 阀值 自然月
		v_threshold_count number := getparavalue('GB0103', 'N1'); -- 阀值 变更次数
		v_dealNo lxistrademain.dealno%type;												-- 交易编号(业务表)
		v_clientno gr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --     投保人3个月内(按变更申请日计算）三次以上（包括三次）变更受益人、联系人、法定代表人或者负责人，且该投保单位下所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --     1) 同一投保单位变更多张保单受益人、联系人、法定代表人或者负责人相同的，将变更次数进行合并记为一次变更（按各同类变更项同一天结案的为一次）。
--          其中受益人的变更的统计口径为：增加受益人、删除受益人、修改受益人；变更联系人、法定代表人或者或者人的统计口径都为变更人的姓名
  --     2) 累计已交保费逻辑同7.1.1
  --     3) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        前一天变更职业、签名、受益人或代理人生效保全的保单
  --     4) 报送数据格式同现有可疑交易格式
  --     5) 此条规则阀值为200万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: xn
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天发生变更投保单位下三个月内所有变更记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    Trantime,
    args2,     --remark
    args4,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.transdate,
        td.remark,
        td.ext2,
        'GB0103_1'
      from
        gr_trans t,gr_rel r,gr_transdetail td
      where
          t.contno=r.contno
      and t.contno=td.contno
      and t.transno=td.transno
      and exists(
          select 1
          from
              gr_trans tmp_t, gr_rel tmp_r, gr_transdetail tmp_td
          where
              tmp_r.clientno = r.clientno
          and tmp_t.contno = tmp_r.contno
          and tmp_t.contno = tmp_td.contno
          and tmp_t.transno = tmp_td.transno
          and tmp_r.custype = 'O'
          and tmp_t.conttype='2'
          and tmp_td.remark in ('增加受益人','修改受益人','删除受益人','联系人姓名变更','法定代表人姓名变更','负责人姓名变更')
          and tmp_t.transtype in  ('AC','BC')
          and trunc(tmp_t.transdate)=trunc(i_baseline)
          )
      and r.custype = 'O'
      and td.remark in ('增加受益人','修改受益人','删除受益人','联系人姓名变更','法定代表人姓名变更','负责人姓名变更')
      and t.transtype in  ('AC','BC')
      and GR_isValidCont(t.contno) = 'yes'
      and t.conttype = '2'
      and trunc(t.transdate) > trunc(add_months(i_baseLine,v_threshold_month*(-1)))  --交易日日3个月前
      and trunc(t.transdate) <= trunc(i_baseLine);   --交易日当日;

--同一个保单同一笔交易将remark和改变后的值各自拼接成1个字段    
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    Trantime,
    args2,     --remark
    args4,
		args5)
      select 
        a.CustomerNo,
        a.TranId,
        a.PolicyNo,
        a.Trantime,
        listagg(a.args2,',') WITHIN group  (ORDER BY a.args2),
        listagg(a.args4,',') WITHIN group  (ORDER BY a.args2),
        'GB0103_2'
      from LXAssistA a where a.args5 = 'GB0103_1'
      group by a.CustomerNo, a.TranId, a.PolicyNo, a.Trantime, 'GB0103_2';

-- 判断累计次数和阈值
	 --同一投保单位3个月内3次（不包括3）以上变更保单的受益人、公司名称、签章、经办人、联系人、法定代表人或者负责人，累计已交保费大于阀值
  DECLARE
    CURSOR baseInfo_sor
    IS
      SELECT CustomerNo,
        PolicyNo,
        TranId
      FROM LXAssistA a
      WHERE EXISTS
        (SELECT 1
        FROM LXAssistA tmp
        WHERE tmp.customerno = a.customerno and tmp.args5 = 'GB0103_2'
        GROUP BY tmp.customerno
        HAVING -- 保证变更为同一保单的受益人、公司名称、签章、经办人、联系人、法定代表人或者负责人不算入次数
          COUNT(DISTINCT tmp.args4) >= v_threshold_count
        )
    AND ( -- 计算名下所有有效保单累计已交保费总额 
      SELECT SUM(NVL(p.sumprem,0))
      FROM gr_rel r,
        gr_policy p
      WHERE r.clientno          = a.customerno
      AND r.contno              = p.contno
      AND GR_isValidCont(r.contno) = 'yes'
      AND r.custype             ='O') >= v_threshold_money
    and a.args5 = 'GB0103_2'
    ORDER BY a.customerno,
      a.Trantime;
       
      
    -- 定义游标变量
    c_clientno gr_client.clientno%type; -- 客户号
    c_contno gr_trans.contno%type;      -- 保单号
    c_tranid gr_trans.transno%type;      -- 交易号
     
  BEGIN
    OPEN baseInfo_sor;
    LOOP
      -- 获取当前游标值并赋值给变量
      FETCH baseInfo_sor INTO c_clientno, c_contno,c_tranid;
      EXIT
    WHEN baseInfo_sor%notfound; -- 游标循环出口
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      IF v_clientno IS NULL OR c_clientno <> v_clientno THEN
        v_dealNo    :=NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
       GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GB0103', i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
       GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_tranid,'1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号
      ELSE
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno ,c_tranid,'');
      END IF;
      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);
      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);
      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    END LOOP;
    CLOSE baseInfo_sor;
  END;
    delete from LXAssistA where args5 in ('GB0103_1','GB0103_2');
   dbms_output.put_line('团险规则B0103执行成功');
  commit;
END GROUP_AML_B0103;
/

prompt
prompt Creating procedure GROUP_AML_C0400
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_C0400(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_money NUMBER := getparavalue ('GC0400', 'M1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 投保人、被保人以外的第三方账户交纳保费（含追加保费），且达到一定金额。
  -- 1) 统计维度：投保单位
  --     抽取前一天生效的有效保单数据
  -- 2) 统计同一个投保单位下不同第三方委托缴费账户的所有有效保单
  --     且累计已交保费大于等于阈值
  -- 3) 此条规则阀值为20万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/02
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/02     初版
  --     baishuai  2020/02/03    累计已交保费的逻辑修改，累计已交保费为统计投保单位维度下的累计已交保费
  -- ============================================
  
  dbms_output.put_line('开始执行团险规则C0400');
  
  -- 同一个投保单位下不同第三方委托缴费账户的所有有效保单,累计已交保费大于等于阈值
  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
             t.contno = r.contno
           -- 同一个投保单位下不同第三方委托缴费账户的所有有效保单且累计已交保费大于等于阈值
           and exists (
                  select 1
                  from
                    gr_policy temp_p,gr_rel temp_r
                  where 
                        r.clientno = temp_r.clientno
                    and temp_p.contno=temp_r.contno
                    and gr_isValidCont(temp_p.contno) = 'yes' -- 有效保单
                    and temp_r.custype='O'
                    and temp_p.source = '1'                -- 来源：PNR系统
                    and temp_p.conttype = '2'              -- 团单 
                  group by 
                     temp_r.clientno
                  having 
                     sum(abs(temp_p.sumprem))>= v_threshold_money      -- 发生第三方缴纳保费，且有效保单的累计保费大于等于阀值
              )
              -- 同一个投保单位下不同第三方委托缴费账户的所有有效保单且累计已交保费大于等于阈值
           /*and exists (                       原逻辑
                  select 1
                  from
                    gr_trans temp_t,gr_rel temp_r
                  where 
                        r.clientno = temp_r.clientno
                    and temp_t.contno=temp_r.contno
                    and isValidCont(temp_t.contno) = 'yes' -- 有效保单
                    and temp_r.custype='O'
                    and temp_t.payway='01'                 -- 资金进出方向：01-收
                    and temp_t.isthirdaccount = '1'        -- 第三方账户
                    and temp_t.source = '1'                -- 来源：PNR系统
                    and temp_t.conttype = '2'              -- 团单 
                  group by 
                     temp_r.contno
                  having 
                     sum(abs(temp_t.payamt))>=v_threshold_money
              )*/
            -- 当天发生第三方缴纳保费
            and exists(
                select
                      1
                  from gr_trans tr, gr_rel re
                   where
                        tr.contno = re.contno
                    and r.clientno=re.clientno
                    and tr.isthirdaccount='1'
                    and tr.payway='01'         -- 资金进出方向：01-收
                    and re.custype='O'
                    and tr.source = '1'        -- 来源：PNR系统
                    and tr.conttype='2'
                    and trunc(tr.transdate) = trunc(i_baseLine)
            )
            and GR_isValidCont(r.contno) = 'yes' -- 有效保单
            and t.IsThirdAccount= '1'         -- 使用第三方账户
            and t.payway='01'                 -- 资金进出方向：01-收
            and r.custype = 'O'               -- 客户类型：O-投保人
            and t.source = '1'                -- 来源：PNR系统
            and t.conttype = '2'              -- 保单类型：2-团单
            order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GC0400', i_baseLine);
          
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          
          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);
        
        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
        
        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
        
      end loop;
    close baseInfo_sor;
  end;
  
  dbms_output.put_line('团险规则C0400执行成功');
  
  commit;
end Group_aml_C0400;
/

prompt
prompt Creating procedure GROUP_AML_C0500
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_C0500(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_money NUMBER := getparavalue ('GC0500', 'M1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 要求将退保金、生存金（分开计算）支付至保单权利人以外的第三方账户，且达到一定金额
  -- 1) 统计维度：保单
  --     抽取前一天生效的有效保单数据
  -- 2) 用领款人的账户名跟投保单位名称进行对比，如果帐户名信息不同统称第三方
  --     且累计已交保费大于等于阈值
  -- 3) 此条规则阀值为20万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/02
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/02     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则C0500');
  -- 当天发生第三方账户退保 金额大于阈值
  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
                t.contno = r.contno
            -- 保单名下以往的第三方给付金额和阈值进行比较    
            and exists(
                  select
                     1
                  from
                      gr_trans temp_t, gr_rel temp_r
                  where temp_t.contno = t.contno
                  and temp_t.contno = temp_r.contno
                  and temp_t.payway='02'            -- 资金进出方向：02-付
                  and temp_r.custype = 'O'               -- 客户类型：O-投保人
                  and temp_t.accname != (select temp_c.name from gr_client temp_c where temp_c.clientno = r.clientno)-- 第三方账户
                  and t.transtype = 'CT'            -- 交易类型为退保
                  and t.source = '1'                -- 来源：PNR系统
                  and t.conttype = '2'              -- 保单类型：2-团单
                  group by 
                      temp_t.contno
                  having
                      sum(abs(temp_t.payamt)) >= v_threshold_money
            )
            -- 当天发生第三方退保交易
            and exists(
                  select
                     1
                  from
                      gr_trans temp_t, gr_rel temp_r
                  where
                      temp_t.contno = temp_r.contno
                  and temp_t.contno = t.contno
                  and temp_t.payway='02'            -- 资金进出方向：02-付
                  and temp_r.custype = 'O'               -- 客户类型：O-投保人
                  and temp_t.accname != (select temp_c.name from gr_client temp_c where temp_c.clientno = r.clientno)-- 第三方账户
                  and t.transtype = 'CT'            -- 交易类型为退保
                  and t.source = '1'                -- 来源：PNR系统
                  and t.conttype = '2'              -- 保单类型：2-团单
                  and trunc(t.transdate) = trunc(i_baseLine) -- 当天
            )
            and t.payway='02'                 -- 资金进出方向：02-付
            and r.custype = 'O'               -- 客户类型：O-投保人
            and t.accname != (select temp_r.name from gr_client temp_r where temp_r.clientno = r.clientno)-- 第三方账户
            and t.transtype = 'CT'            -- 交易类型为退保
            and t.source = '1'                -- 来源：PNR系统
            and t.conttype = '2'              -- 保单类型：2-团单
            order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GC0500', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则C0500执行成功');

  commit;
end Group_aml_C0500;
/

prompt
prompt Creating procedure GROUP_AML_C0600
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_C0600(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_money NUMBER := getparavalue ('GC0600', 'M1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 领款信息上payment后，进行的领款人变更
  -- 1) 统计维度：保单
  --     抽取前一天在payment上操作“领款人变更”的保单
  -- 2) 单张保单累计，该保单名下所有进行了“变更领款人”的给付交易累计（包括退保，理赔）金额
  -- 3) 阀值为5万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/02
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/02     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则C0600');

  -- 同一个投保单位下不同第三方委托缴费账户的所有有效保单,累计已交保费大于等于阈值
  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
             t.contno = r.contno
            -- 保单中所有变更领款人的交易金额大于阈值
            and exists(
                select
                      1
                  from
                      gr_trans tr
                   where
                        t.contno = tr.contno
                    and tr.transtype in ('PAY01','PAY02','PAY03','PAY04') -- 交易类型为变更领款人
                    and tr.source = '1'                -- 来源：PNR系统
                    and tr.conttype='2'
                    group by
                      tr.contno
                    having
                      sum(abs(tr.payamt)) >= v_threshold_money
            )
            -- 当天发生领款人变更交易           
            and exists(
                select
                      1
                  from 
                      gr_trans tr
                   where
                        r.contno=tr.contno
                    and tr.transtype in ('PAY01','PAY02','PAY03','PAY04') -- 交易类型为变更领款人
                    and t.source = '1' -- 来源：PNR系统
                    and tr.conttype='2'
                    and trunc(tr.transdate) = trunc(i_baseLine)
            )
            and r.custype = 'O'               -- 客户类型：O-投保人
            and t.transtype in ('PAY01','PAY02','PAY03','PAY04')
            and t.source = '1'                -- 来源：PNR系统
            and t.conttype = '2'              -- 保单类型：2-团单
            order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GC0600', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则C0600执行成功');

  commit;
end Group_aml_C0600;
/

prompt
prompt Creating procedure GROUP_AML_C0801
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_C0801 (i_baseLine in date,i_oprater in varchar2) is
  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_count number := getparavalue('GC0801', 'N1');   -- 阀值 累计次数
  v_threshold_month NUMBER := getparavalue ('GC0801', 'D1' ); -- 阀值 自然月
BEGIN
  -- =============================================
  -- Rule:
  -- （同一投保单位的保单）付费类保全项目，付至同一第三方账户，半年达到三次及以上。
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM；
  --    抽取前一天付费类保全生效的保单；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为3次，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- i_oprater 操作人
  -- parameter out: none
  -- Author: xn
  -- Create date: 2020/01/03
  -- Changes log:
  --     Author     Date     Description
  -- =============================================
 dbms_output.put_line('开始执行团险规则C0801');
 
  DECLARE
  -- 定义游标：同一投保单位半年内付费类保全项目付至同一第三方账户到达3次及以上
  cursor baseInfo_sor is
      select
         r.clientno,t.transno,t.contno
            from
         gr_trans t,gr_rel r
            where
              t.contno=r.contno
             -- 交易日期当天发生付费类保全项目事件以及达到了阈值
              and exists(
                  select
                          1
                      from
                        gr_trans tmp_tr,gr_rel tmp_re
                      where r.clientno=tmp_re.clientno
                        and tmp_tr.contno=tmp_re.contno
                        and tmp_tr.accname = t.accname
                         --交易次数达到阈值
                        and exists
                        (
                          select
                            1
                          from
                            gr_trans tr,gr_rel re
                          where
                                re.clientno=tmp_re.clientno
                            and tr.accname = tmp_tr.accname
                            and tr.contno=re.contno
                            and tr.accname <> (select c.name from gr_client c where c.clientno = re.clientno)
                            and re.custype='O'
                            and tr.payway='02'
                            and tr.transtype in ('CT','ZT')        -- 交易类型：付费类保全项目
                            and tr.conttype='2'
                            and GR_isValidCont(tmp_tr.contno) = 'yes' -- 有效保单
                            and trunc(tr.transdate) <= trunc(i_baseLine)                                 -- 交易日期在半年内 
                            and trunc(tr.transdate) > trunc(ADD_MONTHS( i_baseLine, - v_threshold_month))  -- 交易日期在半年内
                            group by re.clientno,tr.accname
                            having  count(tr.transno)>= v_threshold_count
                        )
                        and tmp_re.custype='O'
                        and tmp_tr.payway='02'
                        and tmp_tr.transtype in ('CT','ZT')        -- 交易类型：付费类保全项目
                        and tmp_tr.conttype='2'
                        and GR_isValidCont(tmp_tr.contno) = 'yes' -- 有效保单
                        and trunc(tmp_tr.transdate) = trunc(i_baseLine)    -- 交易日期当天
                  )
              and t.accname <> (select c.name from gr_client c where c.clientno = r.clientno)
              and r.custype='O'
              and t.payway='02'
              and T.transtype in ('CT','ZT')        -- 交易类型：付费类保全项目
              and t.conttype='2'
              and GR_isValidCont(t.contno) = 'yes' -- 有效保单
              and trunc(t.transdate) <= trunc(i_baseLine)                                  -- 交易日期在半年内
              and trunc(t.transdate) > trunc(ADD_MONTHS( i_baseLine, - v_threshold_month)) 	 -- 交易日期在半年内
              order by r.clientno,t.transdate desc;

     -- 定义游标变量
      c_clientno gr_client.clientno%type;   -- 客户号
      c_transno gr_trans.transno%type;      -- 客户身份证件号码
      c_contno gr_trans.contno%type;        -- 保单号

      v_clientno gr_client.clientno%type;   -- 客户号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'GC0801', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
         GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
         GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
         GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
         
      end loop;
    close baseInfo_sor;
  end;
  
 dbms_output.put_line('团险规则C0801执行成功');
  commit;
  
END GROUP_AML_C0801;
/

prompt
prompt Creating procedure GROUP_AML_C0802
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE GROUP_AML_C0802(i_baseLine in date,i_oprater in varchar2) is

	v_dealNo lxistrademain.dealno%type;													-- 交易编号(业务表)
	v_threshold_count number := getparavalue('GC0802', 'N1');		-- 阀值 累计次数
	v_threshold_month NUMBER := getparavalue ('GC0802', 'D1' );		-- 阀值 自然日

BEGIN
	-- ============================================
	-- Rule:
	-- 身故案件，若理赔金支付给受益人或者被保人以外的第三方账户，半年达到三次及以上
	-- 1) 投保单位维度
	--    单渠道：OLAS、IGM
	--    抽取前一天生效理赔付费类的有效保单数据
	-- 2) 报送数据格式同现有可疑交易格式
	-- 3) 此条规则阀值为3次，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater 操作人
	-- parameter out: none
	-- Author: xn
	-- Create date: 2020/01/03
	-- Changes log:
	--     Author     Date     Description
	-- ============================================
  
dbms_output.put_line('开始执行团险规则C0802');

	DECLARE
	-- 定义游标：半年内理赔付费类支付给受益人或者被保人以外的第三方账户到达3次及以上
	cursor baseInfo_sor is
        select
              r.clientno,t.transno,t.contno
            from
              gr_trans t,gr_rel r,gr_client c
            where
              t.contno=r.contno
              and c.clientno = r.clientno
             
              -- 被保人和受益人
              and not exists(
                    select
                        1
                    from
                       gr_client cl,gr_rel re
                    where
                        cl.name  =  t.accname
                    and re.contno = r.contno
                    and cl.clientno=re.clientno
                    and re.custype in ('B','I')
                )
                 -- 交易日期当天发生理赔付费类事件
              and exists(
                  select
                     1
                  from
                    gr_trans tmp_tr,gr_rel tmp_re
                  where
                      r.clientno=tmp_re.clientno
                      and tmp_tr.contno=tmp_re.contno
                      and tmp_tr.accname = t.accname
                       -- 判断半年内支付第三方账户3次及以上
                      and exists
                      (
                        select
                          1
                        from
                          gr_trans tr,gr_rel re
                        where
                              re.clientno=tmp_re.clientno
                          and tr.accname = tmp_tr.accname
                          and tr.contno=re.contno
                          and re.custype='O'
                          and tr.transtype = 'CLM'       -- 交易类型：理赔付费类
                          and tr.conttype='2'
                          and tr.payway='02'
                          and GR_isValidCont(tr.contno) = 'yes' -- 有效保单
                          and trunc(tr.transdate) > trunc(ADD_MONTHS( i_baseLine, - v_threshold_month))  -- 交易日期在半年内
                          and trunc(tr.transdate) <= trunc(i_baseLine)                                 -- 交易日期在半年内
                          and tr.accname <> (select c.name from gr_client c where c.clientno = re.clientno)
                          group by re.clientno,tr.accname
                          having  count(tr.transno)>= v_threshold_count
                      )
                      and GR_isValidCont(tmp_tr.contno) = 'yes' -- 有效保单
                      and tmp_re.custype='O'
                      and tmp_tr.payway='02'
                      and tmp_tr.transtype = 'CLM'        -- 交易类型：理赔支付
                      and tmp_tr.conttype='2'
                      and trunc(tmp_tr.transdate) = trunc(i_baseLine)    -- 交易日期当天
               )
              and GR_isValidCont(t.contno) = 'yes' -- 有效保单
              and r.custype='O'
              and t.payway='02'
              and t.transtype='CLM'
              and t.conttype='2'
              and trunc(t.transdate) > trunc(ADD_MONTHS( i_baseLine, - v_threshold_month)) 	 -- 交易日期在半年内
              and trunc(t.transdate) <= trunc(i_baseLine)                                  -- 交易日期在半年内
              order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno gr_client.clientno%type;   -- 客户号
      c_transno gr_trans.transno%type;      -- 客户身份证件号码
      c_contno gr_trans.contno%type;        -- 保单号
      v_clientno gr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

				-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'GC0802', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
         GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          GROUP_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;
  end;
  
  dbms_output.put_line('团险规则C0802执行成功');
  commit;
  
end GROUP_AML_C0802;
/

prompt
prompt Creating procedure GROUP_AML_C1000
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_C1000(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_money NUMBER := getparavalue ('GC1000', 'M1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 较大损失退保,明知退保有较大损失仍然要求退保，且达到一定金额。
  -- 1) 统计维度：保单
  --     提供保全类型（退保）交易信息
  -- 2) 整单退保的保单金额损失达到阈值，损失值：损失金额=累计已交保费-退保金额之差，
  --     如果该损失金额大于等于阈值，生成可疑数据
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/02
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/02     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则C1000');

  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
              t.contno = r.contno         
          and
          -- 损失金额=累计已交保费-退保金额之差  大于等于阈值
          (
              (select 
                   temp_p.sumprem 
               from 
                   gr_policy temp_p 
               where 
                   temp_p.contno = r.contno
               and temp_p.conttype = '2'
              )
                - t.payamt) >= v_threshold_money
          and t.payway = '02'               -- 资金进出方向：付
          and r.custype = 'O'               -- 客户类型：O-投保人
          and t.source = '1'                -- 来源：PNR系统
          and t.conttype = '2'              -- 保单类型：2-团单
          and t.transtype = 'CT'            -- 交易类型：整单退保
          and trunc(t.transdate) = trunc(i_baseLine) -- 当天
          order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GC1000', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则C1000执行成功');

  commit;
  
end Group_aml_C1000;
/

prompt
prompt Creating procedure GROUP_AML_D1100
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_D1100(i_baseLine in date,i_oprater in varchar2) is

       v_threshold_money NUMBER := getparavalue('GD1100', 'M1'); -- 阀值 累计保费金额
       v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
       v_clientno cr_client.clientno%type;                         -- 客户号

begin
  -- ============================================
  -- Rule:
  -- 退费/给付领取等单笔领取大于或等于设定的阈值
  --"反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天保全生效付费类的有效保单数据
  --2.整单退保的保单金额单笔达到阈值或同一个投保单位下保全结算金额（定期结算汇总账单数据）单笔达到阈值，生成可疑数据
  --3.阈值配置：500W，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/14
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/14    初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则D1100');

  declare
     cursor baseInfo_sor is
select r.clientno, t.transno, t.contno
  from gr_trans t, gr_rel r, gr_client c
 where t.contno = r.contno
   and exists
        ( --保全结算金额单笔达到阀值
         select 1
           from gr_trans cms_tb, gr_rel cms_rb, gr_client cms_cb
          where cms_cb.name = c.name
            and cms_cb.cardtype = c.cardtype
            and (cms_cb.BusinessLicenseNo = c.BusinessLicenseNo or
                cms_cb.OrgComCode = c.OrgComCode or
                cms_cb.TaxRegistCertNo = c.TaxRegistCertNo)
            and cms_cb.clientno = cms_rb.clientno
            and cms_rb.contno = cms_tb.contno
            and cms_tb.payamt >= v_threshold_money
            and cms_tb.payway = '02' --付
            and cms_rb.custype = 'O'
            and cms_tb.transtype in ('CT', 'CLM01', 'CLM02', 'CLM03') --退保，理赔
            and cms_tb.conttype = '2'
            and trunc(t.transdate) = trunc(i_baseLine)
          group by cms_cb.name
       )
   and c.clientno = r.clientno
   and t.payway = '02' --付
   and r.custype = 'O' --投保人
   and t.transtype in ('CT', 'CLM01', 'CLM02', 'CLM03') --交易类型是退保、理赔
   and t.conttype = '2' -- 保单类型：1-个单
   and trunc(t.transdate) = trunc(i_baseLine)
 order by r.clientno, t.contno;


      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号



  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GD1100', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则D1100执行成功');

  commit;

end Group_aml_D1100;
/

prompt
prompt Creating procedure GROUP_AML_D1200
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_D1200(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_ratio NUMBER := getparavalue ('GD1200', 'N1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 指定期限内离职权益达到设定的阈值。
  -- 1) 统计维度：投保单位
  --     提供保全类型（退保）交易信息
  -- 2) 离职人员归属比例 （当参保一年内离职权益归属比例）
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/06     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则D1200');

  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
              t.contno = r.contno
          -- 一年期以内（一年内发生投保或者一年内发生新增被保险人）
          and (
                exists(
                   select 
                       1 
                   from 
                       gr_trans temp_t 
                   where
                       temp_t.contno = t.contno   
                   and temp_t.source = '2'        -- 来源：RPAS系统
                   and temp_t.conttype = '2'      -- 保单类型：2-团单
                   and temp_t.transtype = 'AA001' -- 交易类型：投保
                   and trunc(temp_t.transdate) > add_months(i_baseLine,-12)
                   )
             or 
                 exists(
                      select
                           1
                       from
                           gr_trans temp_t,gr_transdetail temp_td
                       where
                           temp_t.contno = temp_td.contno
                       and temp_t.transno = temp_td.transno
                       and temp_t.contno = t.contno
                       -- 本次离职的人(减少的被保险人)客户号在保单新增被保险人的一年明细中存在
                       and temp_td.ext1 = 
                           (select gtd.ext1 from gr_transdetail gtd where gtd.contno = t.contno and gtd.transno = t.transno)
                       and temp_t.source = '2'        -- 来源：RPAS系统
                       and temp_td.remark = '变更被保险人'
                       and temp_t.conttype = '2'      -- 保单类型：2-团单
                       and temp_t.transtype = 'N1'    -- 交易类型：新增被保险人
                       and trunc(temp_t.transdate) > add_months(i_baseLine,-12)    -- 从系统时间往前推一年
                 )
               )
          -- 保单变更项中存在离职比例为阈值的数据(当天发生减少被保险人离职会产生离职归属比例的明细)
          and exists(
              select
                  1
              from
                  gr_trans temp_t,gr_transdetail temp_td
              where
                  temp_t.contno = temp_td.contno
              and temp_t.transno = temp_td.transno
              and temp_td.contno = r.contno
              and temp_t.payway = '02'               -- 资金进出方向：付
              and temp_t.source = '2'                -- 来源：RPAS系统
              and temp_t.conttype = '2'              -- 保单类型：2-团单
              and temp_t.transtype = 'ZT'            -- 交易类型：减少被保险人(就是有人退出保单，离职)
              and temp_td.remark = '离职归属比例'
              and to_number(temp_td.ext4) = v_threshold_ratio -- 当天发生的离职比例为100
              and trunc(temp_t.transdate) = trunc(i_baseLine)
          )          
          and r.custype = 'O'               -- 客户类型：O-投保人
          and t.payway in ('01','02')       -- 资金进出方向：付
          and t.source = '2'                -- 来源：RPAS系统
          and t.conttype = '2'              -- 保单类型：2-团单
          and t.transtype in('ZT','AA001','N1') -- 交易类型：减少被保险人，投保或者新增被保险人
          order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GD1200', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则D1200执行成功');

  commit;

end Group_aml_D1200;
/

prompt
prompt Creating procedure GROUP_AML_D1300
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_D1300(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_ratio NUMBER := getparavalue ('GD1300', 'N1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 不同被保险人之间相同缴费类型下保险费相差超过设定的阈值
  -- 1) 统计维度：投保单位
  --     抓取前一天保单下同一投保单位，相同供款期间内的成员供款的最高额和最低额，
  --     然后进行比较 （去到具体的Sub office 层面)
  -- 2) 阈值配置：相差比例=20倍
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/06     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则D1300');

  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
              t.contno = r.contno
          -- 保险费相差大于阈值
          and ((
              select
                   max(temp_td.ext4) / min(temp_td.ext4)
              from
                    gr_transdetail temp_td
              where temp_td.contno = r.contno
                and temp_td.remark =  (select gtd.remark from gr_transdetail gtd where gtd.contno = r.contno and gtd.transno = t.transno)         
              )  > v_threshold_ratio   )
         and exists(
            SELECT 1
                 FROM gr_trans tmp_t, gr_rel tmp_r
                 WHERE r.clientno = tmp_r.clientno
                   and tmp_t.contno = t.contno
                   and tmp_r.custype = 'O'               -- 客户类型：O-投保人
                   and tmp_t.transtype = 'NI'            -- 当天发生交易类型为：新增被保险人
                   and tmp_t.source = '2'                -- 来源：RPAS系统
                   and tmp_t.conttype = '2'              -- 保单类型：2-团单
                   and TRUNC(tmp_t.transdate) = TRUNC(i_baseLine))     -- 当天
          and r.custype = 'O'               -- 客户类型：O-投保人
          and t.transtype = 'NI'            -- 当天发生交易类型为：新增被保险人
          and t.source = '2'                -- 来源：RPAS系统
          and t.conttype = '2'              -- 保单类型：2-团单
          order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GD1300', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则D1300执行成功');

  commit;

end Group_aml_D1300;
/

prompt
prompt Creating procedure GROUP_AML_D1400
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_D1400(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_ratio NUMBER := getparavalue ('GD1400', 'M1' ); -- 阀值比例（小数）
  v_threshold_year NUMBER := getparavalue ('GD1400', 'D1' );  -- 期限（年数）

begin
  -- ============================================
  -- Rule:
  -- 指定期限内，离职人数超过有效人数或离职保险金领取超过总缴费金额的比例达到设定的阈值
  -- 1) 统计维度：投保单位
  --     抓取1年内， 离职的人数，以及有效的人数 （去到具体的Sub office 层面)
  --     抓取一年内，离职保险金领取和总缴费金额 （去到具体的Sub office 层面)
  -- 2) 阈值配置：阈值比例=50%
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/06     初版
  --     baishuai 2020/2/21      测试时修改，测试时发现计算金额时gr_transdetail与gr_trans与外表关联，会出现重复计算payamt的情况
  -- ============================================

  dbms_output.put_line('开始执行团险规则D1400');

  declare
     cursor baseInfo_sor is
        select
            r.clientno,
            t.transno,
            t.contno
          from
            gr_trans t, gr_rel r
          where
              t.contno = r.contno
          -- 离职人数超过被保险人数量
          and (
          
              (
              (select 
                   count(1) 
                 from
                   gr_trans temp_t,gr_transdetail temp_td
                 where
                     temp_t.contno = temp_td.contno
                 and temp_t.transno = temp_td.transno
                 and temp_t.contno = r.contno
                 and temp_td.remark = '离职'          -- 离职标识
                 and temp_t.transtype in ('CT','ZT')  -- 交易类型为：整单退保或者减少被保险人
                 and temp_t.source = '2'              -- 来源：RPAS系统
                 and temp_t.conttype = '2'            -- 保单类型：2-团单
                 and trunc(temp_t.transdate) >= trunc(add_months(i_baseLine,-12*v_threshold_year))
                 and trunc(temp_t.transdate) <= trunc(i_baseLine)  -- 抓取指定期限内的数据信息
               )      >   -- 大于
                -- 保单现在的被保险人数量
               (select 
                  count(1) 
                from 
                  gr_rel temp_r
                where
                    temp_r.contno = r.contno
                and temp_r.custype = 'I'               -- 被保人
               )
          ) or 
          -- 离职保险金领取超过总缴费金额的比例达到设定的阈值
          (
             (select 
                   sum(abs(temp_t.payamt))
                 from
                   gr_trans temp_t --,gr_transdetail temp_td
                 where
                     --temp_t.contno = temp_td.contno
                 --and temp_t.transno = temp_td.transno
                 temp_t.contno = r.contno
                 --and temp_td.remark = '离职'          -- 离职标识
                 and temp_t.contno in (select contno from gr_transdetail temp_td 
                                       where temp_t.contno = temp_td.contno 
                                             and temp_t.transno = temp_td.transno 
                                             and temp_td.remark = '离职' )
                 and temp_t.transtype in ('CT','ZT')  -- 交易类型为：整单退保或者减少被保险人
                 and temp_t.source = '2'              -- 来源：RPAS系统
                 and temp_t.conttype = '2'            -- 保单类型：2-团单
                 and trunc(temp_t.transdate) >= trunc(add_months(i_baseLine,-12*v_threshold_year))
                 and trunc(temp_t.transdate) <= trunc(i_baseLine)  -- 抓取指定期限内的数据信息
             ) > 
             (select temp_p.sumprem from gr_policy temp_p where temp_p.contno = r.contno)* v_threshold_ratio 
          )
          
          )
          -- 当天发生退保或者减少被保险人的交易
          and exists(
              select
                   1
                from
                  gr_trans temp_t,gr_rel temp_r
                where
                    temp_t.contno  = temp_r.contno
                and temp_r.clientno = r.clientno
                and temp_r.custype = 'O'             -- 客户类型：O-投保人
                and temp_t.transtype in ('CT','ZT')  -- 交易类型为：整单退保或者减少被保险人
                and temp_t.source = '2'              -- 来源：RPAS系统
                and temp_t.conttype = '2'            -- 保单类型：2-团单
                and trunc(temp_t.transdate) = trunc(i_baseLine) -- 当天
          )
          and r.custype = 'O'               -- 客户类型：O-投保人
          and t.transtype in ('CT','ZT')    -- 交易类型为：整单退保或者减少被保险人
          and t.source = '2'                -- 来源：RPAS系统
          and t.conttype = '2'              -- 保单类型：2-团单
          and trunc(t.transdate) >= trunc(add_months(i_baseLine,-12*v_threshold_year))
          and trunc(t.transdate) <= trunc(i_baseLine)  -- 抓取指定期限内的数据信息
          order by r.clientno,t.transdate desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GD1400', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则D1400执行成功');

  commit;

end Group_aml_D1400;
/

prompt
prompt Creating procedure GROUP_AML_D1500
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE Group_aml_D1500(i_baseLine in date,i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;                         -- 客户号
  v_threshold_ratio NUMBER := getparavalue ('GD1500', 'N1' ); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 设定阀值及以上团体客户经办人为同一人
  -- "反洗钱抓取数据条件：
  --统计维度：投保单位
  --1.抓取前一天生效的有效保单数据
  --2.判断不同保单下的联系人是否为同一人，如果是，在判断对应的投保单位是否为同一个，不是则需要生成可疑数据
  --3.阈值配置：团体客户个数：2个，实现可配置形式
  --数据来源：RPAS、GTA、PNR
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date      Description
  --     zhouqk   2020/01/06     初版
  -- ============================================

  dbms_output.put_line('开始执行团险规则D1500');

  delete from lxassista;
--1、获取当天发生投保的并且联系人相同的交易信息
insert into lxassista
  (tranid,
   policyno,
   customerno,
   args1, --联系人
   args2,
   args3,
   args4,
   args5)
  select t.transno,
         t.contno,
         r.clientno,
         LINKMAN, --联系人
         c.name,  --客户名
         c.CardType,--证件类型
         (case when c.cardtype='B' then c.Businesslicenseno--证件号
               when c.cardtype ='O' then c.OrgComCode
               when c.cardtype='T' then c.Taxregistcertno
           end),
         'SD1500_1'
    from gr_client c ,gr_rel r,gr_trans t
   where t.contno = r.contno
     and c.clientno=r.clientno
     and exists(
         select 1 from
         gr_client tmp_c,gr_rel tmp_r,gr_trans tmp_t
         where
         tmp_c.clientno=tmp_r.clientno
         and tmp_r.contno=tmp_t.contno
         and c.linkman=tmp_c.linkman
         and GR_isvalidcont(tmp_t.contno) = 'yes' --有效保单
         and tmp_r.custype = 'O'
         and tmp_t.payway='01'
         and tmp_t.transtype in ('AA001','BC')    --
         and tmp_t.conttype = '2'
         and trunc(tmp_t.transdate) = trunc(i_baseLine) --生效日期
     )
     and GR_isvalidcont(t.contno) = 'yes' --有效保单
     and r.custype = 'O'
     and t.payway='01'
     and t.transtype in ('AA001','BC')    --
     and t.conttype = '2'
     order by r.clientno desc;
 
--获取相同联系人下，不同保单所对应的企业不是同一个，且超过阀值
  declare
     cursor baseInfo_sor is
select lx.customerno, lx.policyno, lx.tranid
  from lxassista lx
 where exists ( --相同联系人下，不同保单所对应的企业不是同一个，且超过阀值
        select 1
          from lxassista la
         where lx.args1 = la.args1 --联系人相同
           and  exists (select 1   --对应企业不是同一个
                      from lxassista lb
                      where lb.args1 = la.args1
                      and (lb.args2!=la.args2 or lb.args3!=la.args3 or lb.args4!=la.args4)
                      and lb.args5 = 'SD1500_1'
                   )
           and la.args5 = 'SD1500_1'
         group by la.args1
        having count(distinct la.customerno) >= v_threshold_ratio)
   and lx.args5 = 'SD1500_1'
 order by lx.customerno, lx.policyno desc;

      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号



  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          --获取交易编号(业务表)
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          GROUP_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'GD1500', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号

        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          GROUP_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        GROUP_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        GROUP_AML_INS_LXISTRADEINSURED(v_dealNo,c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        GROUP_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        GROUP_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;

  dbms_output.put_line('团险规则D1500执行成功');

  delete from lxassista;

  commit;

end Group_aml_D1500;
/

prompt
prompt Creating procedure GROUP_AML_MID_TO_GR
prompt ======================================
prompt
create or replace procedure Group_aml_mid_to_gr(
  
  startDate in VARCHAR2
       
) is

  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息
  v_errormsg LLogTrace.DealDesc%type;
  v_TraceId LLogTrace.TraceId%type;

begin
  -- =============================================
  -- Description: 根据批次号将数据从中间表(mid)迁移到团险平台表(gr)中
  -- parameter in:  startDate 开始时间
  --                endDate 结束时间
  -- parameter out: none
  -- Author: zhouqk
  -- Create date:  2019/12/30
  -- Changes log:
  --     Author       Date        Description
  --     zhouqk    2019/12/       初版
  
  
  -- 批次号需要从推到mid表的日志中获取，现在暂时用主键作为批次号
  
  
  -- =============================================
   dbms_output.put_line('开始执行团险数据从中间表迁移到平台表中');
  
   --获取日期作为日志主键
   SELECT TO_char(sysdate, 'yyyymmddHH24mmss') into v_TraceId from dual;

   -- 插入
   insert into LLogTrace(
     TraceId,
     FuncCode,
     StartTime,
     DealState,
     DealDesc,
     DataBatchNo,
     DataState,
     Operator,
     InsertTime,
     ModifyTime)
  values(
     v_TraceId,
     '000002',
     sysdate,
     '00',
     '团险中间表推数到平台表执行中',
     v_TraceId,
     '01',
     'system',
     sysdate,
     sysdate);
     
     commit;
  
    dbms_output.put_line('日志插入成功');
    --将平台表已经存在的数据删除
  
    delete from gr_client gc where exists(
      
      select 1 from mid_g_client mgc where mgc.clientno = gc.clientno 
      
    );
      
    delete from gr_policy gp where exists(
      
      select 1 from mid_g_policy mgp where mgp.contno = gp.contno
      
    );
      
    delete from gr_rel gr where exists(
      
      select 1 from mid_g_rel mgr where mgr.contno = gr.contno
      
    );

    delete from gr_risk gs where exists(
      
      select 1 from mid_g_risk mgs where mgs.contno = gs.contno 
      
    );
      
    delete from gr_trans gt where exists(
      
      select 1 from mid_g_trans mgt where mgt.transno = gt.transno
      
    );
      
    delete from gr_transdetail gtt where exists (
      
      select 1 from mid_g_transdetail mgtt where mgtt.transno = gtt.transno
      
    );
      
    delete from gr_address gd where exists(
      
      select 1 from mid_g_Address mgd where mgd.clientno=gd.clientno 
        
      and mgd.contno=gd.contno 
      
    );
    dbms_output.put_line('增量插入，删除平台表成功');

  -- 将客户表数据进行迁移
  insert into gr_client(
      ClientNo,--客户号,
      OriginalClientNo,--原始客户号,
      Source,--客户来源,
      Name,--客户名称/姓名,
      Birthday,--生日,
      Age,--年龄,
      Sex,--性别,
      CardType,--客户身份证件/证明文件类型,
      OtherCardType,--其他身份证件/证明文件类型,
      CardID,--证件号码,
      CardExpireDate,--证件有效期,
      ClientType,--客户类型,
      WorkPhone,--工作电话,
      FamilyPhone,--家庭电话,
      Telephone,--手机,
      Occupation,--客户职业,
      Businesstype,--行业分类,
      Income,--投保人年收入,
      GrpName,--单位名称,
      Address,--客户详细地址,
      OtherClientInfo,--客户其他信息,
      ZipCode,--邮编,
      Nationality,--国籍,
      ComCode,--管理机构,
      ContType,--个团标识,
      BusinessLicenseNo,--营业执照号,
      OrgComCode,--组织代码证号,
      TaxRegistCertNo,--税务登记号,
      LegalPerson,--法定代表人,
      LegalPersonCardType,--法定代表人证件类型,
      OtherLPCardType,--可疑主体法定代表人其他身份证件/证明文件类型,
      LegalPersonCardID,--法定代表人证件号码,
      LinkMan,--联系人,
      ComRegistArea,--公司注册地,
      ComRegistType,--单位注册类型,
      ComBusinessArea,--公司经营所在地,
      ComBusinessScope,--公司经营范围,
      AppntNum,--机构客户投保人数,
      ComStaffSize,--企业总人数,
      GrpNature,--单位性质,
      FoundDate,--机构成立时间,
      HolderKey,--股东编号,
      HolderName,--股东姓名,
      HolderCardType,--股东证件类型,
      OtherHolderCardType,--可疑主体控股股东或实际控制人其他身份证件/证明文件类型,
      HolderCardID,--股东证件号码,
      HolderOccupation,--股东职业或行业,
      HolderRadio,--股东持股比例,
      HolderOtherInfo,--股东其他信息,
      RelaSpecArea,--与特殊地区关联,
      FATCTRY,--纳税地区代码,
      CountryCode,--国家代码,
      SuspiciousCode,--客户可疑特征,
      FundSource,--资金来源,
      MakeDate,--入库日期,
      MakeTime,--入库时间,
      BatchNo--批处理号
  )select
     ClientNo,--客户号,
      OriginalClientNo,--原始客户号,
      Source,--客户来源,
      Name,--客户名称/姓名,
      Birthday,--生日,
      Age,--年龄,
      Sex,--性别,
      CardType,--客户身份证件/证明文件类型,
      OtherCardType,--其他身份证件/证明文件类型,
      CardID,--证件号码,
      CardExpireDate,--证件有效期,
      ClientType,--客户类型,
      WorkPhone,--工作电话,
      FamilyPhone,--家庭电话,
      Telephone,--手机,
      Occupation,--客户职业,
      Businesstype,--行业分类,
      Income,--投保人年收入,
      GrpName,--单位名称,
      Address,--客户详细地址,
      OtherClientInfo,--客户其他信息,
      ZipCode,--邮编,
      Nationality,--国籍,
      ComCode,--管理机构,
      ContType,--个团标识,
      BusinessLicenseNo,--营业执照号,
      OrgComCode,--组织代码证号,
      TaxRegistCertNo,--税务登记号,
      LegalPerson,--法定代表人,
      LegalPersonCardType,--法定代表人证件类型,
      OtherLPCardType,--可疑主体法定代表人其他身份证件/证明文件类型,
      LegalPersonCardID,--法定代表人证件号码,
      LinkMan,--联系人,
      ComRegistArea,--公司注册地,
      ComRegistType,--单位注册类型,
      ComBusinessArea,--公司经营所在地,
      ComBusinessScope,--公司经营范围,
      AppntNum,--机构客户投保人数,
      ComStaffSize,--企业总人数,
      GrpNature,--单位性质,
      FoundDate,--机构成立时间,
      HolderKey,--股东编号,
      HolderName,--股东姓名,
      HolderCardType,--股东证件类型,
      OtherHolderCardType,--可疑主体控股股东或实际控制人其他身份证件/证明文件类型,
      HolderCardID,--股东证件号码,
      HolderOccupation,--股东职业或行业,
      HolderRadio,--股东持股比例,
      HolderOtherInfo,--股东其他信息,
      RelaSpecArea,--与特殊地区关联,
      FATCTRY,--纳税地区代码,
      CountryCode,--国家代码,
      SuspiciousCode,--客户可疑特征,
      FundSource,--资金来源,
      MakeDate,--入库日期,
      MakeTime,--入库时间,
      BatchNo--批处理号
   from
      mid_client;
   
   -- 保单信息表
   insert into gr_policy(
      ContNo,--保险合同号
      ContType,--团个险标志
      LocId,--金融机构网点代码
      Prem,--保险费
      Amnt,--保险金额
      PayMethod,--缴费方式
      ContStatus,--保单状态
      Effectivedate,--生效日
      Expiredate,--终止日
      AccountNo,--入账帐号
      SumPrem,--累计保费
      MainYearPrem,--主约年度保费
      YearPrem,--年度保费
      AgentCode,--代理人代码
      GrpFlag,--汇缴件标志
      Source,--保单来源
      InsSubject,--保险标的
      InvestFlag,--投连标识
      RemainAccount,--有效保单剩余账户价值
      PayPeriod,--缴费期限
      SaleChnl,--销售渠道
      InsuredPeoples,--被保险人数
      PayInteval,--交费间隔
      OtherContInfo,--保险合同其他信息
      CashValue,--保单当前现金价值
      INSTFROM,--保费起缴日期
      PolicyAddress,--保单联系地址
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo,--批处理号
      OverPrem,--溢缴保费
      phone,--联系电话
      PrimeYearPrem,--首期年度保费
      RestPayPeriod--剩余交费期数
   )select
      ContNo,--保险合同号
      ContType,--团个险标志
      LocId,--金融机构网点代码
      Prem,--保险费
      Amnt,--保险金额
      PayMethod,--缴费方式
      ContStatus,--保单状态
      Effectivedate,--生效日
      Expiredate,--终止日
      AccountNo,--入账帐号
      SumPrem,--累计保费
      MainYearPrem,--主约年度保费
      YearPrem,--年度保费
      AgentCode,--代理人代码
      GrpFlag,--汇缴件标志
      Source,--保单来源
      InsSubject,--保险标的
      InvestFlag,--投连标识
      RemainAccount,--有效保单剩余账户价值
      PayPeriod,--缴费期限
      SaleChnl,--销售渠道
      InsuredPeoples,--被保险人数
      PayInteval,--交费间隔
      OtherContInfo,--保险合同其他信息
      CashValue,--保单当前现金价值
      INSTFROM,--保费起缴日期
      PolicyAddress,--保单联系地址
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo,--批处理号
      OverPrem,--溢缴保费
      phone,--联系电话
      PrimeYearPrem,--首期年度保费
      RestPayPeriod--剩余交费期数
    from 
      mid_g_policy;
      
   -- 客户保单关联表
    insert into gr_rel(
      ContNo,--保险合同号
      ClientNo,--客户号
      CusType,--客户类型
      RelaAppnt,--投保人与被保险人关系
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo,--批处理号
      PolicyPhone,--保单联系电话
      UseCardType,--保单使用的证件类型
      UseOtherCardType,--保单使用的其它证件类型
      UseCardID,--保单使用的证件号
      Insureno--被保人客户号
    )select
      ContNo,--保险合同号
      ClientNo,--客户号
      CusType,--客户类型
      RelaAppnt,--投保人与被保险人关系
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo,--批处理号
      PolicyPhone,--保单联系电话
      UseCardType,--保单使用的证件类型
      UseOtherCardType,--保单使用的其它证件类型
      UseCardID,--保单使用的证件号
      Insureno--被保人客户号
    from
      mid_g_rel;
      
      
    insert into gr_risk(
      ContNo,--保险合同号
      RiskCode,--险种编码
      RiskName,--险种名称
      MainFlag,--主附险标识
      RiskType,--保险种类
      InsAmount,--保险金额
      Prem,--保险费
      PayInteval,--交费间隔
      Effectivedate,--生效日
      Expiredate,--终止日
      YearPrem,--年度保费
      SaleChnl,--销售渠道
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo--批处理号
    )select
      ContNo,--保险合同号
      RiskCode,--险种编码
      RiskName,--险种名称
      MainFlag,--主附险标识
      RiskType,--保险种类
      InsAmount,--保险金额
      Prem,--保险费
      PayInteval,--交费间隔
      Effectivedate,--生效日
      Expiredate,--终止日
      YearPrem,--年度保费
      SaleChnl,--销售渠道
      Makedate,--入库日期
      MakeTime,--入库时间
      BatchNo--批处理号
    from
      mid_g_risk;
      
      
   INSERT INTO GR_Address(
      ClientNo,      --客户号
      Contno,        --联系方式编码
      ClientType,    --客户类型
      LinkNumber,    --联系电话
      Adress,        --客户住址/经营地址
      CusOthContact, --客户其他联系方式
      Nationality,   --国籍
      Country,       --国家
      MakeDate,      --入库日期
      MakeTime,      --入库时间
      BatchNo,       --批处理号
      ContType       --团个险标志
    )SELECT 
      ClientNo, --客户号
      Contno,        --联系方式编码
      ClientType,    --客户类型
      LinkNumber,    --联系电话
      Adress,        --客户住址/经营地址
      CusOthContact, --客户其他联系方式
      Nationality,   --国籍
      Country,       --国家
      MakeDate,      --入库日期
      MakeTime,      --入库时间
      BatchNo,       --批处理号
      ContType       --团个险标志
    FROM 
      MID_G_Address;
      
      
    INSERT INTO GR_TransDetail(
      TransNo, --交易编号
      ContNo,  --保单合同号
      subno,   --序号
      remark,     --备注
      ext1,     --备用字段1
      ext2,     --备用字段2
      ext3,     --备用字段3
      ext4,     --备用字段4
      ext5,     --备用字段5
      Makedate, --入库日期
      MakeTime, --入库时间
      BatchNo   --批处理号
     )SELECT 
        TransNo, --交易编号
        ContNo,       --保单合同号
        subno,        --序号
        remark,     --备注
        ext1,     --备用字段1
        ext2,     --备用字段2
        ext3,     --备用字段3
        ext4,     --备用字段4
        ext5,     --备用字段5
        Makedate, --入库日期
        MakeTime, --入库时间
        BatchNo   --批处理号
      FROM 
        MID_G_TransDetail;
      
      
     INSERT INTO GR_Trans(
        TransNo,               --交易编号
        ContNo,                --保险合同号
        clientno,              --客户号
        ContType,              --团个险标志
        TransMethod,           --交易形式
        TransType,             --交易类型
        Transdate,             --交易日期
        TransFromRegion,       --交易发生地
        TransToRegion,         --交易去向地
        CureType,              --币种
        PayAmt,                --交易金额
        PayWay,                --资金进出方向
        PayMode,               --资金进出方式
        PayType,               --交易方式
        AccBank,               --资金账户开户行
        AccNo,                 --银行转账账号
        AccName,               --账户持有人姓名
        AccType,               --账户类型
        AgentName,             --交易代办人姓名
        AgentCardType,         --代办人身份证件类型
        AgentOtherCardType,    --代办人其他身份证件类型
        AgentCardID,           --代办人身份证件号码
        AgentNationality,      --代办人国籍
        OpposideFinaName,      --对方金融机构网点名称
        OpposideFinaType,      --对方金融机构代码类型
        OpposideFinaCode,      --对方金融交易网点代码
        OpposideZipCode,       --对方金融机构网点行政区划代码
        TradeCusName,          --交易对手名称
        TradeCusCardType,      --交易对手证件类型
        TradeCusOtherCardType, --交易对手其他证件类型
        TradeCusCardID,        --交易对手证件号码
        TradeCusAccType,       --交易对手账号类型
        TradeCusAccNo,         --交易对手账号
        Source,                --数据来源
        BusiMark,              --业务标识号
        RelationWithRegion,    --交易与机构网点关系
        UseOfFund,             --资金用途
        Makedate,              --入库日期
        MakeTime,              --入库时间
        BatchNo,               --批处理号
        AccOpenTime,           --账户开立时间
        BankCardType,          --客户银行卡类型
        BankCardOtherType,     --客户银行卡其他类型
        BankCardnumber,        --客户银行卡号码
        RPMatchNoType,         --收付款方匹配号类型
        RPMatchNumber,         --收付款方匹配号
        NonCounterTranType,    --非柜台交易方式
        NonCounterOthTranType, --其他非柜台交易方式
        NonCounterTranDevice,  --非柜台交易方式的设备代码
        BankPaymentTranCode,   --银行与支付机构之间的业务交易编码
        ForeignTransCode,      --涉外收支交易分类与代码
        CRMB,                  --交易金额（折人民币）
        CUSD,                  --交易金额（折美元）
        Remark,    --交易信息备注
        IsThirdAccount, --是否使用第三方账户
        RequestDate     --申请日
     )SELECT 
          TransNo,          --交易编号
          ContNo,                --保险合同号
          clientno,              --客户号
          ContType,              --团个险标志
          TransMethod,           --交易形式
          TransType,             --交易类型
          Transdate,             --交易日期
          TransFromRegion,       --交易发生地
          TransToRegion,         --交易去向地
          CureType,              --币种
          PayAmt,                --交易金额
          PayWay,                --资金进出方向
          PayMode,               --资金进出方式
          PayType,               --交易方式
          AccBank,               --资金账户开户行
          AccNo,                 --银行转账账号
          AccName,               --账户持有人姓名
          AccType,               --账户类型
          AgentName,             --交易代办人姓名
          AgentCardType,         --代办人身份证件类型
          AgentOtherCardType,    --代办人其他身份证件类型
          AgentCardID,           --代办人身份证件号码
          AgentNationality,      --代办人国籍
          OpposideFinaName,      --对方金融机构网点名称
          OpposideFinaType,      --对方金融机构代码类型
          OpposideFinaCode,      --对方金融交易网点代码
          OpposideZipCode,       --对方金融机构网点行政区划代码
          TradeCusName,          --交易对手名称
          TradeCusCardType,      --交易对手证件类型
          TradeCusOtherCardType, --交易对手其他证件类型
          TradeCusCardID,        --交易对手证件号码
          TradeCusAccType,       --交易对手账号类型
          TradeCusAccNo,         --交易对手账号
          Source,                --数据来源
          BusiMark,              --业务标识号
          RelationWithRegion,    --交易与机构网点关系
          UseOfFund,             --资金用途
          Makedate,              --入库日期
          MakeTime,              --入库时间
          BatchNo,               --批处理号
          AccOpenTime,           --账户开立时间
          BankCardType,          --客户银行卡类型
          BankCardOtherType,     --客户银行卡其他类型
          BankCardnumber,        --客户银行卡号码
          RPMatchNoType,         --收付款方匹配号类型
          RPMatchNumber,         --收付款方匹配号
          NonCounterTranType,    --非柜台交易方式
          NonCounterOthTranType, --其他非柜台交易方式
          NonCounterTranDevice,  --非柜台交易方式的设备代码
          BankPaymentTranCode,   --银行与支付机构之间的业务交易编码
          ForeignTransCode,      --涉外收支交易分类与代码
          CRMB,                  --交易金额（折人民币）
          CUSD,                  --交易金额（折美元）
          Remark,    --交易信息备注
          IsThirdAccount, --是否使用第三方账户
          RequestDate     --申请日
       FROM 
          MID_G_Trans;
      
      
     INSERT INTO GR_Trans(
          TransNo,    --交易编号
          ContNo,    --保险合同号
          clientno,    --客户号
          ContType,    --团个险标志
          TransMethod,    --交易形式
          TransType,    --交易类型
          Transdate,    --交易日期
          TransFromRegion,    --交易发生地
          TransToRegion,    --交易去向地
          CureType,    --币种
          PayAmt,    --交易金额
          PayWay,    --资金进出方向
          PayMode,    --资金进出方式
          PayType,    --交易方式
          AccBank,    --资金账户开户行
          AccNo,    --银行转账账号
          AccName,    --账户持有人姓名
          AccType,    --账户类型
          AgentName,    --交易代办人姓名
          AgentCardType,    --代办人身份证件类型
          AgentOtherCardType,    --代办人其他身份证件类型
          AgentCardID,    --代办人身份证件号码
          AgentNationality,    --代办人国籍
          OpposideFinaName,    --对方金融机构网点名称
          OpposideFinaType,    --对方金融机构代码类型
          OpposideFinaCode,    --对方金融交易网点代码
          OpposideZipCode,    --对方金融机构网点行政区划代码
          TradeCusName,    --交易对手名称
          TradeCusCardType,    --交易对手证件类型
          TradeCusOtherCardType,    --交易对手其他证件类型
          TradeCusCardID,    --交易对手证件号码
          TradeCusAccType,    --交易对手账号类型
          TradeCusAccNo,    --交易对手账号
          Source,    --数据来源
          BusiMark,    --业务标识号
          RelationWithRegion,    --交易与机构网点关系
          UseOfFund,    --资金用途
          Makedate,    --入库日期
          MakeTime,    --入库时间
          BatchNo,    --批处理号
          AccOpenTime,    --账户开立时间
          BankCardType,    --客户银行卡类型
          BankCardOtherType,    --客户银行卡其他类型
          BankCardnumber,    --客户银行卡号码
          RPMatchNoType,    --收付款方匹配号类型
          RPMatchNumber,    --收付款方匹配号      
          NonCounterTranType,    --非柜台交易方式
          NonCounterOthTranType,    --其他非柜台交易方式  
          NonCounterTranDevice,    --非柜台交易方式的设备代码
          BankPaymentTranCode,    --银行与支付机构之间的业务交易编码
          ForeignTransCode,    --涉外收支交易分类与代码
          CRMB,    --交易金额（折人民币）
          CUSD,    --交易金额（折美元）
          Remark,    --交易信息备注
          IsThirdAccount,    --是否使用第三方账户
          RequestDate    --申请日
       )SELECT 
            TransNo,    --交易编号
            ContNo,    --保险合同号
            clientno,    --客户号
            ContType,    --团个险标志
            TransMethod,    --交易形式
            TransType,    --交易类型
            Transdate,    --交易日期
            TransFromRegion,    --交易发生地
            TransToRegion,    --交易去向地
            CureType,    --币种
            PayAmt,    --交易金额
            PayWay,    --资金进出方向
            PayMode,    --资金进出方式
            PayType,    --交易方式
            AccBank,    --资金账户开户行
            AccNo,    --银行转账账号
            AccName,    --账户持有人姓名
            AccType,    --账户类型
            AgentName,    --交易代办人姓名
            AgentCardType,    --代办人身份证件类型
            AgentOtherCardType,    --代办人其他身份证件类型
            AgentCardID,    --代办人身份证件号码
            AgentNationality,    --代办人国籍
            OpposideFinaName,    --对方金融机构网点名称
            OpposideFinaType,    --对方金融机构代码类型
            OpposideFinaCode,    --对方金融交易网点代码
            OpposideZipCode,    --对方金融机构网点行政区划代码
            TradeCusName,    --交易对手名称
            TradeCusCardType,    --交易对手证件类型
            TradeCusOtherCardType,    --交易对手其他证件类型
            TradeCusCardID,    --交易对手证件号码
            TradeCusAccType,    --交易对手账号类型
            TradeCusAccNo,    --交易对手账号
            Source,    --数据来源
            BusiMark,    --业务标识号
            RelationWithRegion,    --交易与机构网点关系
            UseOfFund,    --资金用途
            Makedate,    --入库日期
            MakeTime,    --入库时间
            BatchNo,    --批处理号
            AccOpenTime,    --账户开立时间
            BankCardType,    --客户银行卡类型
            BankCardOtherType,    --客户银行卡其他类型
            BankCardnumber,    --客户银行卡号码
            RPMatchNoType,    --收付款方匹配号类型
            RPMatchNumber,    --收付款方匹配号      
            NonCounterTranType,    --非柜台交易方式
            NonCounterOthTranType,    --其他非柜台交易方式  
            NonCounterTranDevice,    --非柜台交易方式的设备代码
            BankPaymentTranCode,    --银行与支付机构之间的业务交易编码
            ForeignTransCode,    --涉外收支交易分类与代码
            CRMB,    --交易金额（折人民币）
            CUSD,    --交易金额（折美元）
            Remark,    --交易信息备注
            IsThirdAccount,    --是否使用第三方账户
            RequestDate    --申请日
         FROM  
            MID_G_Trans;
            
      dbms_output.put_line('数据插入已完成');            
     
      -- 将此次中间表的数据放入存档
      insert into mid_g_client_bak select * from mid_g_client;
      
      insert into mid_g_policy_bak select * from mid_g_policy;
      
      insert into mid_g_rel_bak select * from mid_g_rel;
      
      insert into mid_g_risk_bak select * from mid_g_risk;
      
      insert into mid_g_trans_bak select * from mid_g_trans;
      
      insert into mid_g_trans_bakdetail_bak select * from mid_g_transdetail;
      
      insert into mid_g_address_bak select * from mid_g_address;
     
      dbms_output.put_line('中间表数据归档结束');            
            
      -- 清除中间表所有数据
      delete from mid_g_client;
      
      delete from mid_g_policy;
      
      delete from mid_g_rel;
      
      delete from mid_g_risk;
      
      delete from mid_g_trans;
      
      delete from mid_g_transdetail;
      
      delete from mid_g_address;
      
      dbms_output.put_line('中间表数据已清除');                  
      
      -- 执行完毕，更新轨迹状态
      update 
        LLogTrace
      set 
       dealstate = '01',
       dealdesc = '团险中间表推数到平台表成功结束',
       InsertTime = to_date(startDate,'YYYY-MM-DD'),
       modifytime = to_date(startDate,'YYYY-MM-DD'),
       endtime = sysdate
      where traceid = v_TraceId;
      
      dbms_output.put_line('恭喜，提数完成！！');                        
      
      commit;
   -- 异常处理
EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=errorCode||errorMsg;

  -- 将提取失败的信息记录到提取结果表中
  
  update 
    LLogTrace
  set 
    dealstate  = '02',
    dealdesc   = v_errormsg,
    InsertTime = to_date(startDate,'YYYY-MM-DD'),
    modifytime = to_date(startDate,'YYYY-MM-DD')
  where 
    traceid = v_TraceId;
    
  commit;
end Group_aml_mid_to_gr;
/

prompt
prompt Creating procedure GROUP_INSURANCE_PROC_AML_RULE
prompt ================================================
prompt
create or replace procedure Group_insurance_proc_aml_rule(i_baseLine in date,i_oprater in VARCHAR2) is
begin
  -- =============================================
  -- Description:  调用大额/可疑各筛选规则相关处理
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/12/25
  -- Changes log:
  --     Author        Date         Description
  --     zhouqk     2019/12/25         初版
  -- =============================================

  --在这里对此次所有的团险规则进行循环攫取
  dbms_output.put_line('开始执行团险规则');
  ------------------------------许宝宝测试专属区----------------------------------
    Group_aml_A0101(i_baseLine,i_oprater);
    
--    Group_aml_A0300(i_baseLine,i_oprater);
    
    GROUP_AML_B0101(i_baseLine,i_oprater);
    
--    GROUP_AML_B0102(i_baseLine,i_oprater);
   
--    GROUP_AML_B0103(i_baseLine,i_oprater);
  
--    GROUP_AML_C0801(i_baseLine,i_oprater);
  
--   GROUP_AML_C0802(i_baseLine,i_oprater);
 
--    Group_aml_C1000(i_baseLine,i_oprater);
  
--    Group_aml_D1100(i_baseLine,i_oprater);

--    Group_aml_D1300(i_baseLine,i_oprater);
  
  ------------------------------------------------------------------------------
  
  --Group_aml_A0200(i_baseLine,i_oprater);
  
  -- Group_aml_A0900(i_baseLine,i_oprater);
  
  -- Group_aml_C0400(i_baseLine,i_oprater);
  
  Group_aml_C0500(i_baseLine,i_oprater);
   
  -- Group_aml_C0600(i_baseLine,i_oprater);
  
  --Group_aml_D1400(i_baseLine,i_oprater);
  
  -- Group_aml_D1500(i_baseLine,i_oprater);

  -- Group_aml_A0102(i_baseLine,i_oprater);

  --Group_aml_A0801(i_baseLine,i_oprater);
  
  --Group_aml_A0802(i_baseLine,i_oprater);
  
  Group_aml_D1200(i_baseLine,i_oprater);
  
  dbms_output.put_line('规则执行完毕');

end Group_insurance_proc_aml_rule;
/

prompt
prompt Creating procedure PROC_AML_DATA_MIGRATION
prompt ==========================================
prompt
create or replace procedure proc_aml_data_migration(i_dataBatchNo in varchar2) is
begin
  -- =============================================
  -- Description: 将大额/可疑业务临时表中数据迁移到业务表
  -- parameter in: i_dataBatchNo 批次号
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/05/10
  -- Changes log:
  --     Author     Date     Description
  --     xuexc   2019/05/10  初版
  -- =============================================

  -- 大额交易主表
  insert into Lxihtrademain
    select
      DealNo,
			CSNM,
			CRCD,
			CTVC,
			CustomerName,
			IDType,
			OITP,
			IDNo,
			HTDT,
			DataState,
			Operator,
			ManageCom,
			Typeflag,
			Notes,
			CustomerType,
			BaseLine,
			GetDataMethod,
			NextFileType,
			NextReferFileNo,
			NextPackageType,
			DataBatchNo,
			MakeDate,
			MakeTime,
			ModifyDate,
			ModifyTime,
			JudgmentDate,
      ReportSuccessDate
    from Lxihtrademain_Temp where DataBatchNo = i_dataBatchNo;

  -- 大额交易明细表（去重后，迁移到业务表）
  insert into Lxihtradedetail
    select
      DealNo,
		  PolicyNo,
      TICD,
      ContType,
      FINC,
      RLFC,
      CATP,
      CTAC,
      OATM,
      CBCT,
      OCBT,
      CBCN,
      TBNM,
      TBIT,
      OITP,
      TBID,
      TBNT,
      TSTM,
      RPMT,
      RPMN,
      TSTP,
      OCTT,
      OOCT,
      OCEC,
      BPTC,
      TSCT,
      TSDR,
      TRCD,
      CRPP,
      CRTP,
      CRAT,
      CFIN,
      CFCT,
      CFIC,
      CFRC,
      TCNM,
      TCIT,
      OTTP,
      TCID,
      TCAT,
      TCAC,
      CRMB,
      CUSD,
      ROTF,
      DataState,
      DataBatchNo,
      MakeDate,
      MakeTime,
      ModifyDate,
      ModifyTime,
      triggerflag
    from Lxihtradedetail_Temp tmp,
      (select row_number() over(partition by DealNo, PolicyNo, TICD order by serialno asc) as rowno, serialno
         from Lxihtradedetail_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;

  -- 可疑交易信息主表
  insert into Lxistrademain
    select
      dealno, -- 交易编号
      rpnc,   -- 上报网点代码
      detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
      torp,   -- 报送次数标志
      dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
      odrp,   -- 其他报送方向
      tptr,   -- 可疑交易报告触发点
      otpr,   -- 其他可疑交易报告触发点
      stcb,   -- 资金交易及客户行为情况
      aosp,   -- 疑点分析
      stcr,   -- 可疑交易特征
      csnm,   -- 客户号
      senm,   -- 可疑主体姓名/名称
      setp,   -- 可疑主体身份证件/证明文件类型
      oitp,   -- 其他身份证件/证明文件类型
      seid,   -- 可疑主体身份证件/证明文件号码
      sevc,   -- 客户职业或行业
      srnm,   -- 可疑主体法定代表人姓名
      srit,   -- 可疑主体法定代表人身份证件类型
      orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
      srid,   -- 可疑主体法定代表人身份证件号码
      scnm,   -- 可疑主体控股股东或实际控制人名称
      scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
      ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
      scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
      strs,   -- 补充交易标识
      datastate, -- 数据状态
      filename,  -- 附件名称
      filepath,  -- 附件路径
      rpnm,      -- 填报人
      operator,  -- 操作员
      managecom, -- 管理机构
      conttype,  -- 保险类型（01-个单, 02-团单）
      notes,     -- 备注
			baseline,       -- 日期基准
      getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入）
      nextfiletype,   -- 下次上报报文类型
      nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
      nextpackagetype,-- 下次上报报文包类型
      databatchno,    -- 数据批次号
      makedate,       -- 入库时间
      maketime,       -- 入库日期
      modifydate,     -- 最后更新日期
      modifytime,     -- 最后更新时间
      judgmentdate,   -- 终审日期
      ORXN,           -- 接续报告首次上报成功的报文名称
		  ReportSuccessDate
    from Lxistrademain_Temp where DataBatchNo=i_dataBatchNo;

  -- 可疑交易明细信息（去重后，迁移到业务表）
  insert into Lxistradedetail
    select
      DealNo,
      TICD,
      ICNM,
      TSTM,
      TRCD,
      ITTP,
      CRTP,
      CRAT,
      CRDR,
      CSTP,
      CAOI,
      TCAN,
      ROTF,
      DataState,
      DataBatchNo,
      MakeDate,
      MakeTime,
      ModifyDate,
      ModifyTime,
      TRIGGERFLAG
    from Lxistradedetail_Temp tmp,
      (select row_number() over(partition by DealNo, TICD order by serialno asc) as rowno, serialno
         from Lxistradedetail_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;

  -- 可疑交易合同信息（去重后，迁移到业务表）
  insert into Lxistradecont
    select
      DealNo,
      CSNM,
      ALNM,
      AppNo,
      ContType,
      AITP,
      OITP,
      ALID,
      ALTP,
      ISTP,
      ISNM,
      RiskCode,
      Effectivedate,
      Expiredate,
      ITNM,
      ISOG,
      ISAT,
      ISFE,
      ISPT,
      CTES,
      FINC,
      DataBatchNo,
      MakeDate,
      MakeTime,
      ModifyDate,
      ModifyTime
    from Lxistradecont_Temp tmp,
      (select row_number() over(partition by DealNo, CSNM order by serialno asc) as rowno, serialno
         from Lxistradecont_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;

  -- 可疑交易被保人信息（去重后，迁移到业务表）
  insert into Lxistradeinsured
    select
      DEALNO,
      CSNM,
      INSUREDNO,
      ISTN,
      IITP,
      OITP,
      ISID,
      RLTP,
      DataBatchNo,
      MakeDate,
      MakeTime,
      ModifyDate,
      ModifyTime
    from Lxistradeinsured_Temp tmp,
      (select row_number() over(partition by DealNo, CSNM, INSUREDNO order by serialno asc) as rowno, serialno
         from Lxistradeinsured_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;

  -- 可疑交易受益人信息（去重后，迁移到业务表）
  insert into Lxistradebnf
    select
      DealNo,
      CSNM,
      InsuredNo,
      BnfNo,
      BNNM,
      BITP,
      OITP,
      BNID,
      DataBatchNo,
      MakeDate,
      MakeTime,
      ModifyDate,
      ModifyTime
    from Lxistradebnf_Temp tmp,
      (select row_number() over(partition by DealNo, CSNM, InsuredNo, BnfNo order by serialno asc) as rowno, serialno
         from Lxistradebnf_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;

    insert into Lxaddress
    select
      dealno,
      listno,
      csnm,
      nationality,
      linknumber,
      adress,
      cusothcontact,
      databatchno,
      makedate,
      maketime,
      modifydate,
      modifytime
    from Lxaddress_Temp tmp,
      (select row_number() over(partition by DealNo, CSNM, listno order by serialno asc) as rowno, serialno
         from Lxaddress_Temp
         where DataBatchNo = i_dataBatchNo) tmpsub
    where tmp.serialno = tmpsub.serialno and tmpsub.rowno = 1 and tmp.DataBatchNo = i_dataBatchNo;                                           -- 交易主体联系方式

  -- 清空大额/可疑业务临时表
  delete from Lxihtrademain_Temp;   -- 大额交易主表-临时表
  delete from Lxihtradedetail_Temp; -- 大额交易明细表-临时表
  delete from Lxistrademain_Temp;   -- 可疑交易信息主表-临时表
  delete from Lxistradedetail_Temp; -- 可疑交易明细信息-临时表
  delete from Lxistradecont_Temp;   -- 可疑交易合同信息-临时表
  delete from Lxistradeinsured_Temp;-- 可疑交易被保人信息-临时表
  delete from Lxistradebnf_Temp;    -- 可疑交易受益人信息-临时表
  delete from Lxaddress_Temp;       -- 交易主体联系方式-临时表

end proc_aml_data_migration;
/

prompt
prompt Creating procedure PROC_AML_INS_LXOPERATIONTRACE
prompt ================================================
prompt
create or replace procedure proc_aml_ins_lxoperationtrace(

  i_databatchno in number,
  i_dealno in varchar2,
  i_datatype in varchar2) is

  v_traceno lxoperationtrace.traceno%type;

begin
  -- =============================================
  -- Description: 根据规则筛选结果插入lxoperationtrace轨迹表
  -- parameter in: i_traceno     流水号
  --               i_databatchno 批次号
  --               i_dealno      交易编号
  --               i_datatype    数据类型
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/06/13
  -- Changes log:
  --     Author     Date      Description
  --      zhouqk  2019/06/13     初版
  -- =============================================

  v_traceno := nextval2('AML_TRACENO','SN');

  -- 插入大额可疑提数log日志表
  insert into lxoperationtrace(
    TRACENO,	    -- 流水号
    DATABATCHNO,  -- 数据批次号
    DEALNO,       -- 交易编号
    DATATYPE,     -- 数据类型
    OPERATIONTYPE,-- 业务类型/业务节点
    OPERATIONCODE,-- 操作
    AOSP,         -- 疑点分析
    REMARK,       -- 备注
    OPERATOR,     -- 操作者
    MAKEDATE,     -- 入库日期
    MAKETIME,     -- 入库时间
    MODIFYDATE,   -- 在最后更新日期
    MODIFYTIME    -- 最后更新时间
  )
  values(
    LPAD(v_traceno,20,'0'),
    i_databatchno,
    i_dealno,
    i_datatype,
    '00',            -- 业务类型为系统抓取
    null,
    null,
    '系统抓取',
    'system',
    to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd'),
    to_char(sysdate,'hh24:mi:ss'),
    to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd'),
    to_char(sysdate,'hh24:mi:ss')
  );

end proc_aml_ins_lxoperationtrace;
/

prompt
prompt Creating procedure PROC_AML_DEALOPERATORDATA
prompt ============================================
prompt
create or replace procedure proc_aml_dealoperatordata(i_databatchno in varchar2) is
begin
  -- ============================================
  -- Description: 将大额可疑主表中的数据插入到轨迹表中
  -- parameter in: i_databatchno   批次号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/06/13
  -- Changes log:
  --     Author         Date        Description
  --     zhouqk     2019/06/13        初版
  -- =============================================

  declare

      --定义游标:保存大额主表中的交易编号（根据批次号）

      cursor baseInfo_IH_sor is
        select
            tmp_h.dealno
          from
            lxihtrademain_temp tmp_h
        where
            tmp_h.databatchno=i_databatchno;

      --定义游标:保存可疑主表中的交易编号（根据批次号）

      cursor baseInfo_IS_sor is
        select
            tmp_s.dealno
          from
            lxistrademain_temp tmp_s
        where
            tmp_s.databatchno=i_databatchno;

      v_ih_dealno lxihtrademain_temp.dealno%type;
      v_is_dealno lxistrademain_temp.dealno%type;

begin

    open baseInfo_IH_sor;
      loop
        fetch baseInfo_IH_sor into v_ih_dealno;
        exit when baseInfo_IH_sor%notfound;

         proc_aml_ins_lxoperationtrace(i_databatchno,v_ih_dealno,'IH');

      end loop;
    close baseInfo_IH_sor;


    open baseInfo_IS_sor;
      loop
        fetch baseInfo_IS_sor into v_is_dealno;
        exit when baseInfo_IS_sor%notfound;

         proc_aml_ins_lxoperationtrace(i_databatchno,v_is_dealno,'IS');

      end loop;
    close baseInfo_IS_sor;

end;
end proc_aml_dealoperatordata;
/

prompt
prompt Creating procedure PROC_AML_DELETE_LXIHTRADE
prompt ============================================
prompt
create or replace procedure proc_aml_delete_lxihtrade(i_baseLine in date) is
begin
	-- ============================================
  -- Description: 将大额/可疑业务临时表中数据迁移到业务表
  --              用于实现重提功能：判断业务表中是否存储已经提取的数据，删除已经插入的数据，进行重新插入
  -- parameter in: i_baseline  交易日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/04/21
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk   2019/04/21    初版
  -- =============================================

	declare
			--定义游标：将大额主表和主表的中间表的交易编号保存到游标中（根据csnm：客户号  crcd：大额交易特征代码  baseline：日期基准）
			cursor baseInfo_sor is
				select
						temp.dealno
					from
						lxihtrademain main,lxihtrademain_temp temp
				where main.csnm=temp.csnm
				and main.crcd=temp.crcd
        and trunc(main.baseline)=trunc(i_baseline)
				and trunc(temp.baseline)=trunc(i_baseLine);

			--定义变量
			c_dealno lxihtrademain.dealno%type;

begin
			open baseInfo_sor;
			loop
				fetch baseInfo_sor into c_dealno;
				exit when baseInfo_sor%notfound;

          -- 根据游标中保存的交易编号进行删除

					delete from lxihtrademain_temp where dealno=c_dealno;

					delete from lxihtradedetail_temp where dealno=c_dealno;

          delete from lxaddress_temp where dealno=c_dealno;

		end loop;
		close baseInfo_sor;

end;
end proc_aml_delete_lxihtrade;
/

prompt
prompt Creating procedure PROC_AML_DELETE_LXISTRADE
prompt ============================================
prompt
create or replace procedure proc_aml_delete_lxistrade(i_baseLine in date) is
begin
  -- ============================================
  -- Description: 用于实现重提功能：判断业务表中是否存储已经提取的数据，删除已经插入的数据，进行重新插入
  -- parameter in: i_baseline  交易日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/04/21
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk   2019/04/21    初版
  -- =============================================

	declare
			--定义游标：将可疑主表和主表的中间表的交易编号保存到游标中（根据csnm：客户号  stcr：可疑交易特征代码  baseline：日期基准）
			cursor baseInfo_sor is
				select
						temp.dealno
					from
						lxistrademain main,lxistrademain_temp temp
				where
				    main.csnm=temp.csnm
				and main.stcr=temp.stcr
        and main.orxn is null
        and temp.orxn is null
        and trunc(main.baseline)=trunc(i_baseline)
				and trunc(temp.baseline)=trunc(i_baseline);


			--定义变量
			v_dealno lxistrademain.dealno%type;			-- 交易编号

begin

			open baseInfo_sor;
			loop
				fetch baseInfo_sor into v_dealno;
				exit when baseInfo_sor%notfound;

          -- 根据游标中的交易编号进行删除

					delete from lxistrademain_temp where dealno=v_dealno;

          delete from lxistradedetail_temp where dealno=v_dealno;

					delete from lxistradecont_temp where dealno=v_dealno;

					delete from lxistradeinsured_temp where dealno=v_dealno;

					delete from lxistradebnf_temp where dealno=v_dealno;

					delete from lxaddress_temp where dealno=v_dealno;

		end loop;
		close baseInfo_sor;

end;
end proc_aml_delete_lxistrade;
/

prompt
prompt Creating procedure PROC_AML_INS_LDBATCHLOG
prompt ==========================================
prompt
create or replace procedure proc_aml_ins_ldbatchlog(

  i_databatchno in varchar2,i_batchtype in varchar2, i_state in varchar2, i_rundate in date,i_errormsg in varchar2) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新ldbatchlog表
  -- parameter in: i_databatchno  批次号
  --               i_batchtype 		大额可疑标识
  --               i_state  			判断成功失败的标识
  --               i_rundate      运行时间
	--							 i_errormsg			失败信息
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/01
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/04/12  初版
  -- =============================================

  -- 插入大额可疑提取结果表
  insert into ldbatchlog(
    batchno, 			-- 批次号
		batchtype,		-- 大额可疑的标识
		state,				-- 判断成功失败的标识
		rundate,			-- 运行时间
		errormsg,			-- 失败信息
		makedate			-- 创建时间
  )
  values(
    i_databatchno,
		i_batchtype,
		i_state,
		i_rundate,
		i_errormsg,
		to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd')
  );

end proc_aml_ins_ldbatchlog;
/

prompt
prompt Creating procedure PROC_AML_INS_LX_LDBATCHLOG
prompt =============================================
prompt
create or replace procedure proc_aml_ins_lx_ldbatchlog(

	i_databatchno in varchar2,i_state in varchar2,i_rundate in date,i_errormsg in varchar2

) is
begin

  -- =============================================
  -- Description: 主函数结束，插入提取结果表
  -- parameter in: i_databatchno 批次号
  --               i_state       大额可疑标志
  --               i_rundate     运行时间
  --               i_errormsg    错误信息
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/04/21
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/04/21  初版
  -- =============================================

		PROC_AML_INS_LDBATCHLOG(i_databatchno, 'IS', i_state, i_rundate, i_errormsg);


end proc_aml_ins_lx_ldbatchlog;
/

prompt
prompt Creating procedure PROC_AML_INS_LXCALLOG
prompt ========================================
prompt
create or replace procedure proc_aml_ins_lxcallog(
  i_appid in varchar2,i_csnmCount in number, i_operator in varchar2, i_stcr in varchar2,i_databatchno in VARCHAR2) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lxcallog表
  -- parameter in: i_baseLine  交易日期
  --               i_csnmCount 客户数
  --               i_operator  操作人
  --               i_stcr      算法编码
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/03/01
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/01  初版
  -- =============================================

  -- 插入大额可疑提数log日志表
  insert into lxcallog(
    appid,    	-- 应用标识号
    calcode,  	-- 算法编码
		dataBatchNo,-- 批次号
    csnmcount,	-- 提取到的客户数量
    operator, 	-- 操作员
    makedate, 	-- 入库时间
    maketime  	-- 入库日期
  )
  values(
    i_appid,
    i_stcr,
		i_databatchno,
    i_csnmCount,
    i_operator,
    to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd'), -- 入库日期
    to_char(sysdate,'hh24:mi:ss') 											 -- 入库时间
  );

end proc_aml_ins_lxcallog;
/

prompt
prompt Creating procedure PROC_AML_INS_LX_LXCALLOG
prompt ===========================================
prompt
create or replace procedure proc_aml_ins_lx_lxcallog(i_operator in varchar2,i_dataBatchNo in varchar2) is

begin

  -- =============================================
  -- Description: 主函数结束，插入提取日志表
  -- parameter in: i_operator      操作人
  --               i_dataBatchNo   批次号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/04/21
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/04/21  初版
  -- =============================================

declare
		--定义游标，保存已经插入到大额业务表中的（去重之后）交易特征代码（仅限此次批次号中）
		cursor baseInfo_IH_sor is
						select
								distinct hm.crcd
							from
								lxihtrademain hm
							where
								DataBatchNo = i_dataBatchNo;

		--定义游标，保存已经插入到可疑业务表中的（去重之后）交易特征代码（仅限此次批次号中）
		cursor baseInfo_IS_sor is
						select
								distinct im.stcr
							from
								lxistrademain im
							where
								DataBatchNo = i_dataBatchNo;


		--声明大额交易
		v_crcd lxihtrademain.crcd%type;
		v_csnmIHCount lxcallog.CSNMCOUNT%type; 				-- 保存查找到的大额客户数量

		--声明可疑交易
		v_stcr lxistrademain.stcr%type;
		v_csnmISCount lxcallog.CSNMCOUNT%type; 				-- 保存查找到的可疑客户数量

begin

		open baseInfo_IH_sor;																-- 打开保存此次批处理已经筛选出的规则特征代码
			loop
				fetch baseInfo_IH_sor into v_crcd;
				exit when baseInfo_IH_sor%notfound;							-- 当此次批处理没有插入业务表数据，退出循环

				select count(1) into v_csnmIHCount from lxihtrademain where DataBatchNo=i_dataBatchNo and crcd = v_crcd;
																												-- 将每条特征代码插入客户数
				PROC_AML_INS_LXCALLOG('LIH',v_csnmIHCount, i_operator,v_crcd,i_dataBatchNo);

			end loop;
		close baseInfo_IH_sor;

		open baseInfo_IS_sor;																-- 打开保存此次批处理已经筛选出的规则特征代码
			loop
				fetch baseInfo_IS_sor into v_stcr;
				exit when baseInfo_IS_sor%notfound;							-- 当此次批处理没有插入业务表数据，退出循环

				select count(1) into v_csnmISCount from lxistrademain where DataBatchNo=i_dataBatchNo and stcr = v_stcr;
																												-- 将每条特征代码插入客户数
				PROC_AML_INS_LXCALLOG('LIS',v_csnmISCount,i_operator,v_stcr,i_dataBatchNo);

			end loop;
		close baseInfo_IS_sor;

end;
end proc_aml_ins_lx_lxcallog;
/

prompt
prompt Creating procedure PROC_AML_MAPPINGCODE
prompt =======================================
prompt
create or replace procedure proc_aml_mappingcode(

    i_dataBatchNo in varchar2

) is
begin
  -- =============================================
  -- Description:  大额/可疑交易业务表字段转码
  -- parameter in:  i_dataBatchNo  批次号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date:  2019/04/22
  -- Changes log:
  --     Author     Date             Description
  --     zhouqk  2019/04/21             初版
	--     zhouqk  2019/05/23           增加大额业务表中交易方式的转码（默认给000051）
  -- =============================================
  update lxistrademain_temp a set

      --可疑主体身份证件/证明文件类型
      setp = getTargetCodeByMapping('aml_idtype',a.setp),
      --可疑主体法定代表人身份证件类型
      srit = getTargetCodeByMapping('aml_idtype',a.srit),
      --可疑主体控股股东或实际控制人身份证件/证明文件类型
      scit = getTargetCodeByMapping('aml_idtype',a.scit),
      --客户职业或行业
      sevc = getTargetCodeByMapping('aml_sevc',a.sevc),
      --管理机构
      managecom = getTargetCodeByMapping('aml_finc',a.managecom)

      where a.databatchno=i_dataBatchNo;

  update lxistradecont_temp a set
         --缴费方式
         ispt = getTargetCodeByMapping('aml_ispt',a.ispt),
         --投保人身份证件/证明文件类型
         aitp = getTargetCodeByMapping('aml_idtype',a.aitp)
         --金融机构网点代码
         --finc = getTargetCodeByMapping('aml_finc',a.finc)

         where a.databatchno=i_dataBatchNo;

  --被保人证件类型
  update lxistradeinsured_temp a set iitp = getTargetCodeByMapping('aml_idtype',a.iitp) where a.databatchno=i_dataBatchNo;

  --受益人身份证件类型
  update lxistradebnf_temp a set bitp = getTargetCodeByMapping('aml_idtype',a.bitp) where a.databatchno=i_dataBatchNo;

  update lxistradedetail_temp a set
         --可疑交易类型
         ittp = getTargetCodeByMapping('aml_ittp',a.ittp),
         --资金进出方向
         crdr = getTargetCodeByMapping('aml_crdr',a.crdr),
         --资金进出方式
         cstp = getTargetCodeByMapping('aml_cstp',a.cstp),
         --币种
         crtp = getTargetCodeByMapping('aml_crtp',a.crtp)

         where a.databatchno=i_dataBatchNo;

  update lxihtrademain_temp a set
         -- 管理机构
         a.ManageCom = getTargetCodeByMapping('aml_finc',a.managecom),

         a.idtype = getTargetCodeByMapping('aml_idtype',a.idtype)

         where a.databatchno=i_dataBatchNo;

  update lxihtradedetail_temp a set

         finc = getTargetCodeByMapping('aml_finc',a.finc),
				 -- 大额明细表中交易方式推数为空，给默认值   000051
				 tstp = '000051',
         --币种
         crtp = getTargetCodeByMapping('aml_crtp',a.crtp)

         where a.databatchno=i_dataBatchNo;


  update lxaddress_temp a set
         --国籍
         nationality = getTargetCodeByMapping('aml_country',a.nationality) where a.databatchno=i_dataBatchNo;

end proc_aml_mappingcode;
/

prompt
prompt Creating procedure GROUP_PROC_AML_MAIN
prompt ======================================
prompt
create or replace procedure Group_proc_aml_main(i_startDate in varchar, i_endDate in varchar,i_oprater in varchar) is
  v_dataBatchNo varchar2(28);
  v_startDate date := to_date(i_startDate, 'YYYY-MM-DD');
  v_endDate date := to_date(i_endDate, 'YYYY-MM-DD');
  v_baseLine date := v_startDate;

  v_errormsg ldbatchlog.errormsg%type;
  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息

begin
  -- =============================================
  -- Description: 筛选规则抓取满足条件的交易记录
  --              并将抓取的交易记录保存至大额/可疑业务表中
  --              针对于团险
  -- parameter in: i_startDate 交易开始日期
  --               i_endDate 交易结束日期
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/12/25
  -- Changes log:
  --     Author      Date     Description
  --     zhouqk   2019/12/25     初版
  -- ============================================
  
  -- 进行数据迁移，根据批次号将数据从mid表中迁移到gr表中
  
  -- 清空大额/可疑业务临时表
  delete from Lxihtrademain_Temp;   -- 大额交易主表-临时表
  delete from Lxihtradedetail_Temp; -- 大额交易明细表-临时表
  delete from Lxistrademain_Temp;   -- 可疑交易信息主表-临时表
  delete from Lxistradedetail_Temp; -- 可疑交易明细信息-临时表
  delete from Lxistradecont_Temp;   -- 可疑交易合同信息-临时表
  delete from Lxistradeinsured_Temp;-- 可疑交易被保人信息-临时表
  delete from Lxistradebnf_Temp;    -- 可疑交易受益人信息-临时表
  delete from Lxaddress_Temp;       -- 交易主体联系方式-临时表

  -- 使用sequences获取最新的dataBatchNo
  select CONCAT(to_char(sysdate,'yyyymmdd'),LPAD(SEQ_dataBatchNo.nextval,20,'0')) into v_dataBatchNo from dual;

  loop
    begin
      Group_insurance_proc_aml_rule(v_baseLine,i_oprater);
      v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;


  -- 更新大额/可疑业务临时表中的批次号
  update Lxihtrademain_Temp set Databatchno = v_dataBatchNo;   -- 大额交易主表-临时表
  update Lxihtradedetail_Temp set Databatchno = v_dataBatchNo; -- 大额交易明细表-临时表
  update Lxistrademain_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易信息主表-临时表
  update Lxistradedetail_Temp set Databatchno = v_dataBatchNo; -- 可疑交易明细信息-临时表
  update Lxistradecont_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易合同信息-临时表
  update Lxistradeinsured_Temp set Databatchno = v_dataBatchNo;-- 可疑交易被保人信息-临时表
  update Lxistradebnf_Temp set Databatchno = v_dataBatchNo;    -- 可疑交易受益人信息-临时表
  update Lxaddress_Temp set Databatchno = v_dataBatchNo;       -- 交易主体联系方式-临时表

  --将临时表转码(团险规则沿用之前ldcodemapping转码方式)
  proc_aml_mappingcode(v_dataBatchNo);

  --接续报告不需要转码，单独处理
  -- 重置v_baseLine
  /*
  v_baseLine := v_startDate;
  loop
    begin
      proc_aml_D0100(v_baseLine,i_oprater);
      v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;*/

  -- 更新可疑业务临时表中的批次号
  update Lxistrademain_Temp set Databatchno = v_dataBatchNo where Databatchno is null;   -- 可疑交易信息主表-临时表
  update Lxistradedetail_Temp set Databatchno = v_dataBatchNo where Databatchno is null; -- 可疑交易明细信息-临时表
  update Lxistradecont_Temp set Databatchno = v_dataBatchNo where Databatchno is null;   -- 可疑交易合同信息-临时表
  update Lxistradeinsured_Temp set Databatchno = v_dataBatchNo where Databatchno is null;-- 可疑交易被保人信息-临时表
  update Lxistradebnf_Temp set Databatchno = v_dataBatchNo where Databatchno is null;    -- 可疑交易受益人信息-临时表
  update Lxaddress_Temp set Databatchno = v_dataBatchNo where Databatchno is null;       -- 交易主体联系方式-临时表

  -- 实现重提功能：判断业务表中是否存储已经提取的数据，如果业务表存在则删除临时表里面的数据，保留业务表里面的数据
  -- 重置v_baseLine
  --  PS:撰写团险的时候，实现重提功能是否和个险一样(主要是条件)
  v_baseLine := v_startDate;
  loop
    begin
      PROC_AML_DELETE_LXIHTRADE(v_baseLine);                       --删除大额业务表里面的数据
      PROC_AML_DELETE_LXISTRADE(v_baseLine);                       --删除可疑业务表里面的数据
      v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;

  -- 插入轨迹表(从中间表统计数据插入到轨迹表中，此时中间表数据没有去重，但是主表的数据无需去重)
  proc_aml_dealoperatordata(v_dataBatchNo);

  -- 将大额/可疑业务临时表中数据迁移到业务表（去重）
  -- PS:这里的去重方式是否要进行调整
  proc_aml_data_migration(v_dataBatchNo);

  -- 查找业务表中已经插入的数据记录到提取日志表中
  PROC_AML_INS_LX_LXCALLOG(i_oprater,v_dataBatchNo);

  -- 将成功提取的数据记录到提取结果表中
  PROC_AML_INS_LDBATCHLOG(v_dataBatchNo,'IS','01',trunc(sysdate),to_char(v_baseLine-1,'yyyy-mm-dd')||'团险规则提取成功！');

  commit;

--异常处理
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;

  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=to_char((v_baseLine),'yyyy-mm-dd')||errorCode||errorMsg;

  -- 将提取失败的信息记录到提取结果表中
  PROC_AML_INS_LX_LDBATCHLOG(v_dataBatchNo,'00',trunc(sysdate),v_errormsg);
  commit;


end Group_proc_aml_main;
/

prompt
prompt Creating procedure PRC_INHERENCE
prompt ================================
prompt
CREATE OR REPLACE PROCEDURE PRC_INHERENCE (p_item in varchar2,p_reportid in varchar2,p_managecom in varchar2)
AS 
p_date date:=to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd');
p_time varchar2(10):=to_char(sysdate,'hh24:mi:ss');
p_reportno reportmain.reportno%type;
BEGIN

p_reportno:=NEXTVAL2('AML_REPORTNO', 'SN');

insert into reportmain(reportno,reportType,statPara,managecom,reportName,operator,makedate,maketime)
	values(p_reportno,p_reportid,p_item,p_managecom,(select r.reportname from reportinfo r where r.reportid=p_reportid),'aml',p_date,p_time);

insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,1 ,'被评估单位' ,p_date ,p_time );  
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,2 ,'评估实施单位' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,3 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,4 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,5 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,6 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,7 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,8 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,9 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,10 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,11 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,12 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,13 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,14 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,15 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,16 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,17 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,18 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,19 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,20 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,21 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,22 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,23 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,24 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,25 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,26 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,27 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,28 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,29 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,30 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,31 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,32 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,33 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,34 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,35 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,36 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,37 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,38 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,39 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,40 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,41 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,42 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,43 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,44 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,45 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,46 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,47 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,48 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,49 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,50 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,51 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,52 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,53 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,54 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,55 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,56 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,57 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,58 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,59 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,60 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,61 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,62 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,63 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,64 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,65 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,66 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,67 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,68 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,69 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,70 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,71 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,72 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,73 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,74 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,75 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,76 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,77 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,78 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,79 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,80 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,81 ,'0' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,82 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,83 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,84 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,85 ,'' ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,86 ,to_char(sysdate,'yyyy-mm-dd') ,p_date ,p_time );
insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno ,87 ,'' ,p_date ,p_time );
commit;
END PRC_INHERENCE;
/

prompt
prompt Creating procedure PRC_REPORT
prompt =============================
prompt
CREATE OR REPLACE PROCEDURE prc_report(p_item in varchar2,p_reportid in varchar2,p_managecom in varchar2)
AS
p_date date:=to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd');
p_time varchar2(10):=to_char(sysdate,'hh24:mi:ss');
p_startDate date:=to_date(substr(p_item,0,4)||'01'||'01','yyyymmdd');
p_endDate date:=to_date(substr(p_item,0,4)||'04'||'01','yyyymmdd');
p_reportno reportmain.reportno%type;

BEGIN

  -- ============================================
  -- 报表插入
  -- parameter in: p_date       现在的日期
  --               p_time       现在的时间
  --               p_startDate  统计的开始时间
  --               p_endDate    统计的结束时间
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/04/26
  -- Changes log:
  --     Author     Date        Description
  --     胡吉祥   2019/04/26     初版
  --	 蔡自力   2019/09/12	 修改
	-- ============================================

  select case substr(p_item,5)
      when '01' then p_startDate
      when '02' then add_months(p_startDate,3)
      when '03' then add_months(p_startDate,6)
			when '04' then add_months(p_startDate,9)
	   end,
	   case substr(p_item,5)
			when '01' then p_endDate
			when '02' then add_months(p_endDate,3)
			when '03' then add_months(p_endDate,6)
			when '04' then add_months(p_endDate,9)
	   end
	   into p_startDate,p_endDate
	from dual; --通过统计季度判断时间
	
	p_reportno:=NEXTVAL2('AML_REPORTNO', 'SN');
	
	insert into reportmain(reportno,reportType,statPara,managecom,reportName,operator,makedate,maketime)
	values(p_reportno,p_reportid,p_item,p_managecom,(select r.reportname from reportinfo r where r.reportid=p_reportid),'aml',p_date,p_time);

	--请自行创建分支
	insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'1','填报单位',p_date,p_time);



  -- 填报季度
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'2',p_item,p_date,p_time);

  --一、客户身份识别（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'3','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) 
  values(p_reportno,'4',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '3'),p_date,p_time);


  --（一）承保时
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'5','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) 
  values(p_reportno,'6',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '5'),p_date,p_time);

  --其中：达到识别金额以上（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'7','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'8',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '7'),p_date,p_time);

  --通过第三方识别（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'9','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'10',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '9'),p_date,p_time);


  --发现问题（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'11','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'12',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '11'),p_date,p_time);

  --（二）退保时
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'13','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'14',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '13'),p_date,p_time);

  --其中：达到识别金额以上（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'15','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'16',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '15'),p_date,p_time);

  --发现问题（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'17','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'18',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '17'),p_date,p_time);

  --（三）理赔或给付时
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'19','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'20',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '19'),p_date,p_time);

  --其中：达到识别金额以上（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'21','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'22',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '21'),p_date,p_time);

  --发现问题（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'23','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'24',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '23'),p_date,p_time);

  --二、客户身份重新识别（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'25','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'26',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '25'),p_date,p_time);

  --其中：变更重要信息（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'27','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'28',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '27'),p_date,p_time);

  --行为异常（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'29','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'30',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '29'),p_date,p_time);

  --身份信息异常（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'31','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'32',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '31'),p_date,p_time);

  --保单质押贷款（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'33','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'34',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '33'),p_date,p_time);

  --发现问题（件）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'35','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'36',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '35'),p_date,p_time);

  --三、客户身份资料保存（套）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'37','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'38',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '37'),p_date,p_time);

  --四、交易记录保存（套）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'39','0',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'40',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '39'),p_date,p_time);

  --五、大额交易报告（份）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'41',(select count(1) from lxihtrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and managecom=p_managecom),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'42',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '41'),p_date,p_time);

  --涉及金额（万元）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'43',(select nvl(sum(CRAT),0) from lxihtradedetail where dealno in (select dealno from lxihtrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and managecom=p_managecom)),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'44',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '43'),p_date,p_time);

  --六、可疑交易报告（份）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'45',(select count(1) from lxistrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and managecom=p_managecom),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'46',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '45'),p_date,p_time);

  --涉及金额（万元）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'47',(select nvl(sum(CRAT),0) from lxistradedetail where dealno in (select dealno from lxistrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and ManageCom=p_managecom)),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'48',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '47'),p_date,p_time);

  --其中：重大可疑交易报告（份）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'49',(select count(1) from lxistrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and DETR='02' and ManageCom=p_managecom),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'50',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '49'),p_date,p_time);

  --涉及金额（万元）
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'51',(select nvl(sum(CRAT),0) from lxistradedetail where dealno in (select dealno from lxistrademain where ReportSuccessDate>=p_startDate and ReportSuccessDate<p_endDate and DETR='02' and ManageCom=p_managecom)),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'52',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '51'),p_date,p_time);

  --其他累计数
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'54',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '53'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'56',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '55'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'58',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '57'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'60',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '59'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'62',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '61'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'64',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '63'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'66',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '65'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'68',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '67'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'70',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '69'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'72',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '71'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'74',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '73'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'76',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '75'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'78',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '77'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'80',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '79'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'82',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '81'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'84',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '83'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'86',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '85'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'88',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '87'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'90',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '89'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'92',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '91'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'94',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '93'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'96',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '95'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'98',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '97'),p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,statevalue,makedate,maketime) values(p_reportno,'100',(select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01')    and r.ITEMID = '99'),p_date,p_time);

  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'53',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'55',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'57',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'59',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'61',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'63',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'65',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'67',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'69',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'71',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'73',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'75',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'77',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'79',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'81',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'83',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'85',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'87',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'89',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'91',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'93',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'95',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'97',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'99',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'101',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'102',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'103',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'104',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'105',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'106',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'107',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'108',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'109',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'110',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'111',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'112',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'113',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'114',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'115',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'116',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'117',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'118',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'119',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'120',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'121',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'122',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'123',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'124',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'125',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'126',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'127',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'128',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'129',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'130',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'131',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'132',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'133',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'134',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'135',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'136',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'137',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'138',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'139',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'140',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'141',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'142',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'143',p_date,p_time);
  insert into REPORTCOLLDETAIL(reportid,itemid,makedate,maketime) values(p_reportno,'144',p_date,p_time);
  commit;
END;
/

prompt
prompt Creating procedure PRC_UPDATETOTAL
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE prc_updateTotal(p_reportid in varchar2)
AS
p_item reportmain.statpara%type;
p_managecom reportmain.managecom%type;
BEGIN

  -- ============================================
  -- 报表更新
  -- parameter in: p_item       统计维度
  --               p_item       报表id
  --               p_managecom  管理机构
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/04/26
  -- Changes log:
  --     Author     Date        Description
  --     胡吉祥   2019/04/26     初版
  --	 蔡自力   2019/09/12	 修改
	-- ============================================
  select statpara,managecom into p_item,p_managecom from reportmain where reportno=p_reportid;
  
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '3') where  reportid = p_reportid  and itemid = '4';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '5') where  reportid = p_reportid  and itemid = '6';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '7') where  reportid = p_reportid  and itemid = '8';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '9') where  reportid = p_reportid  and itemid = '10';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '11') where  reportid = p_reportid  and itemid = '12';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '13') where  reportid = p_reportid  and itemid = '14';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '15') where  reportid = p_reportid  and itemid = '16';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '17') where  reportid = p_reportid  and itemid = '18';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '19') where  reportid = p_reportid  and itemid = '20';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '21') where  reportid = p_reportid  and itemid = '22';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '23') where  reportid = p_reportid  and itemid = '24';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '25') where  reportid = p_reportid  and itemid = '26';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '27') where  reportid = p_reportid  and itemid = '28';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '29') where  reportid = p_reportid  and itemid = '30';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '31') where  reportid = p_reportid  and itemid = '32';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '33') where  reportid = p_reportid  and itemid = '34';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '35') where  reportid = p_reportid  and itemid = '36';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '37') where  reportid = p_reportid  and itemid = '38';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '39') where  reportid = p_reportid  and itemid = '40';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '41') where  reportid = p_reportid  and itemid = '42';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '43') where  reportid = p_reportid  and itemid = '44';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '45') where  reportid = p_reportid  and itemid = '46';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '47') where  reportid = p_reportid  and itemid = '48';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '49') where  reportid = p_reportid  and itemid = '50';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '51') where  reportid = p_reportid  and itemid = '52';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '53') where  reportid = p_reportid  and itemid = '54';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '55') where  reportid = p_reportid  and itemid = '56';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '57') where  reportid = p_reportid  and itemid = '58';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '59') where  reportid = p_reportid  and itemid = '60';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '61') where  reportid = p_reportid  and itemid = '62';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '63') where  reportid = p_reportid  and itemid = '64';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '65') where  reportid = p_reportid  and itemid = '66';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '67') where  reportid = p_reportid  and itemid = '68';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '69') where  reportid = p_reportid  and itemid = '70';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '71') where  reportid = p_reportid  and itemid = '72';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '73') where  reportid = p_reportid  and itemid = '74';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '75') where  reportid = p_reportid  and itemid = '76';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '77') where  reportid = p_reportid  and itemid = '78';
  --TODO 覆盖率由客户填还是系统计算
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '79') where  reportid = p_reportid  and itemid = '80';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '81') where  reportid = p_reportid  and itemid = '82';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '83') where  reportid = p_reportid  and itemid = '84';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '85') where  reportid = p_reportid  and itemid = '86';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '87') where  reportid = p_reportid  and itemid = '88';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '89') where  reportid = p_reportid  and itemid = '90';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '91') where  reportid = p_reportid  and itemid = '92';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '93') where  reportid = p_reportid  and itemid = '94';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '95') where  reportid = p_reportid  and itemid = '96';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '97') where  reportid = p_reportid  and itemid = '98';
  update REPORTCOLLDETAIL set statevalue = (select (case when SUM(r.statevalue) is null then 0 else SUM(r.statevalue) end) from REPORTCOLLDETAIL r where r.reportid in (select m.reportno from reportmain m where m.managecom=p_managecom and m.STATPARA <= p_item and m.STATPARA>=substr(p_item, 0, 4)||'01') and ITEMID = '99') where  reportid = p_reportid  and itemid = '100';
  commit;
END;
/

prompt
prompt Creating procedure PROC_AML_0000
prompt ================================
prompt
create or replace procedure proc_aml_0000(i_Customno in varchar, i_BGDT in varchar,i_EDDT in varchar,i_informFileName in varchar) is
  v_dataBatchNo varchar2(28);
  v_Customno lxistrademain.csnm%type := i_Customno;
  v_startDate date := to_date(i_BGDT, 'YYYY-MM-DD');
  v_endDate date := to_date(i_EDDT, 'YYYY-MM-DD');
  v_baseLine date := v_startDate;
  v_dealNo lxistrademain.dealno%type;
  v_informFileName lxistrademain.strs%type := i_informFileName;

  v_errormsg ldbatchlog.errormsg%type;
  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息

begin
  -- =============================================
  -- Description:  人工补正信息补充
  -- parameter in: i_startDate 补充开始日期
  --               i_endDate 补充结束日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/06/06
  -- Changes log:
  --     Author     Date     Description
  --     yangjp   2019/06/06  初版
  -- ============================================

  -- 使用sequences获取最新的dataBatchNo
	select CONCAT(to_char(sysdate,'yyyymmdd'),LPAD(SEQ_dataBatchNo.nextval,20,'0')) into v_dataBatchNo from dual;
  v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

    begin
      --人工补正信息补充lxistrademain_temp表
        insert into lxistrademain_temp(
            serialno,
            dealno, -- 交易编号
            rpnc,   -- 上报网点代码
            detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
            torp,   -- 报送次数标志
            dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
            odrp,   -- 其他报送方向
            tptr,   -- 可疑交易报告触发点
            otpr,   -- 其他可疑交易报告触发点
            stcb,   -- 资金交易及客户行为情况
            aosp,   -- 疑点分析
            stcr,   -- 可疑交易特征
            csnm,   -- 客户号
            senm,   -- 可疑主体姓名/名称
            setp,   -- 可疑主体身份证件/证明文件类型
            oitp,   -- 其他身份证件/证明文件类型
            seid,   -- 可疑主体身份证件/证明文件号码
            sevc,   -- 客户职业或行业
            srnm,   -- 可疑主体法定代表人姓名
            srit,   -- 可疑主体法定代表人身份证件类型
            orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
            srid,   -- 可疑主体法定代表人身份证件号码
            scnm,   -- 可疑主体控股股东或实际控制人名称
            scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
            ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
            scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
            strs,   -- 补充交易标识
            datastate, -- 数据状态
            filename,  -- 附件名称
            filepath,  -- 附件路径
            rpnm,      -- 填报人
            operator,  -- 操作员
            managecom, -- 管理机构
            conttype,  -- 保险类型（01-个单, 02-团单）
            notes,     -- 备注
            baseline,       -- 日期基准
            getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入）
            nextfiletype,   -- 下次上报报文类型
            nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
            nextpackagetype,-- 下次上报报文包类型
            databatchno,    -- 数据批次号
            makedate,       -- 入库时间
            maketime,       -- 入库日期
            modifydate,     -- 最后更新日期
            modifytime,			-- 最后更新时间
            judgmentdate,   -- 终审日期
            ORXN,           -- 接续报告首次上报成功的报文名称
            ReportSuccessDate)-- 上报成功日期
        (
            select
               getSerialno(sysdate) as serialno,
               LPAD(v_dealNo,20,'0') AS DealNo,
               '@N' as RPNC,
               '02' as DETR,
               '1' as TORP,
               '01' as DORP,
               '@N' as ODRP,
               '99' as TPTR,
               '信息补充通知应答' as OTPR,
               '信息补充通知应答' as STCB,
               '信息补充通知应答' as AOSP,
               '@N' as STCR,
               a.clientno as CSNM,
               a.name as SENM,
               a.cardtype as SETP,
               nvl(OtherCardType, '@N') as OITP,
               a.cardid as SEID,
               a.occupation as SEVC,
               nvl(a.legalperson, '@N') as SRNM,
               a.legalpersoncardtype as SRIT,
               nvl(OtherLPCardType, '@N') as ORIT,
               nvl(a.legalpersoncardid, '@N') as SRID,
               nvl(a.holdername, '@N') as SCNM,
               a.holdercardtype as SCIT,
               nvl(OtherHolderCardType, '@N') as OCIT,
               nvl(a.holdercardid, '@N') as SCID,
               v_informFileName as STRS,
               'A00' as DataState,
               '' as FileName,
               '' as FilePath,
               '@N' as RPNM,
               'system' as Operator,
               a.comcode as ManageCom,
               '1' as ContType,
               '' as Notes,
               v_endDate as BaseLine,
               '01' as GetDataMethod,
               '' as NextFileType,
               '' as NextReferFileNo,
               '' as NextPackageType,
               v_dataBatchNo as DataBatchNo,
               sysdate as MakeDate,
               to_char(sysdate, 'hh24:mi:ss') as MakeTime,
               '' as ModifyDate,
               '' as ModifyTime,
               '' as JUDGMENTDATE,
               '' as ORXN,
               '' as REPORTSUCCESSDATE
          from cr_client a
         where a.clientno = v_Customno );

     --人工补正信息补充LXADDRESS_TEMP表
     INSERT INTO LXADDRESS_TEMP (
        serialno,
        DealNo,
        ListNo,
        CSNM,
        Nationality,
        LinkNumber,
        Adress,
        CusOthContact,
        DataBatchNo,
        MakeDate,
        MakeTime,
        ModifyDate,
        ModifyTime)
      (
        select
           getSerialno(sysdate) as serialno,
           LPAD(v_dealNo,20,'0') AS DealNo,
           rownum as ListNo,
           a.clientno as CSNM,
           a.nationality as Nationality,
           a.linknumber as LinkNumber,
           a.adress as Adress,
           a.cusothcontact as CusOthContact,
           v_dataBatchNo as DataBatchNo,
           sysdate as MakeDate,
           to_char(sysdate, 'hh24:mi:ss') as MakeTime,
           '' as ModifyDate,
           '' as ModifyTime
      from cr_address a
     where clientno = v_Customno);

     --人工补正信息补充LXISTRADEDETAIL_TEMP表
      insert into LXISTRADEDETAIL_TEMP(
        serialno,
        DealNo,
        TICD,
        ICNM,
        TSTM,
        TRCD,
        ITTP,
        CRTP,
        CRAT,
        CRDR,
        CSTP,
        CAOI,
        TCAN,
        ROTF,
        DataState,
        DataBatchNo,
        MakeDate,
        MakeTime,
        ModifyDate,
        ModifyTime,
        TRIGGERFLAG)
      (
         select
               getSerialno(sysdate) as serialno,
               LPAD(v_dealNo,20,'0') AS DealNo,
               b.TRANSNO || b.CONTNO as TICD,
               b.contno as ICNM,
               to_char(b.transdate, 'YYYY-MM-DD') as TSTM,
               nvl(b.transfromregion, '@N') as TRCD,
               b.transtype as ITTP,
               b.curetype as CRTP,
               b.payamt as CRAT,
               b.payway as CRDR,
               b.paymode as CSTP,
               nvl(b.accbank, '@N') as CAOI,
               nvl(b.accno, '@N') as TCAN,
               nvl(b.remark, '@N') as ROTF,
               'A00' as DataState,
               v_dataBatchNo as DataBatchNo,
               sysdate as MakeDate,
               to_char(sysdate, 'hh24:mi:ss') as MakeTime,
               '' as ModifyDate,
               '' as ModifyTime,
               '' as TRIGGERFLAG
          from cr_rel a, cr_trans b
         where a.contno = b.contno
           and b.transdate between v_startDate and v_endDate
           and a.custype = 'O'
           and a.clientno = v_Customno);


        --人工补正信息补充LXISTRADECONT_TEMP表
           insert into LXISTRADECONT_TEMP(
            serialno,
            DealNo,
            CSNM,
            ALNM,
            AppNo,
            ContType,
            AITP,
            OITP,
            ALID,
            ALTP,
            ISTP,
            ISNM,
            RiskCode,
            Effectivedate,
            Expiredate,
            ITNM,
            ISOG,
            ISAT,
            ISFE,
            ISPT,
            CTES,
            FINC,
            DataBatchNo,
            MakeDate,
            MakeTime,
            ModifyDate,
            ModifyTime)
          (
              select
               getSerialno(sysdate) as serialno,
               LPAD(v_dealNo,20,'0') AS DealNo,
               a.contno as CSNM,
               c.name as ALNM,
               c.clientno as APPNO,
               a.conttype as ContType,
               c.cardtype as AITP,
               nvl(c.OtherCardType, '@N') as OITP,
               c.cardid as ALID,
               c.clienttype as ALTP,
               (select d.risktype
                 from cr_risk d
                where d.contno = a.contno
                  and rownum = 1) as ISTP,
               (select d.riskname
                  from cr_risk d
                 where d.contno = a.contno
                   and rownum = 1) as ISNM,
               (select d.riskcode
                  from cr_risk d
                 where d.contno = a.contno
                   and rownum = 1) as RiskCode,
               a.effectivedate as Effectivedate,
               a.expiredate as Expiredate,
               a.insuredpeoples as ITNM,
               a.inssubject as ISOG,
               a.amnt as ISAT,
               a.prem as ISFE,
               a.paymethod as ISPT,
               nvl(a.othercontinfo, '@N') as CTES,
               a.locid as FINC,
               v_dataBatchNo as DataBatchNo,
               sysdate as MakeDate,
               to_char(sysdate, 'hh24:mi:ss') as MakeTime,
               '' as ModifyDate,
               '' as ModifyTime
          from cr_policy a, cr_rel b, cr_client c
         where a.contno = b.contno
           and b.clientno = c.clientno
           and b.custype = 'O'
           and b.clientno = v_Customno);


           --人工补正信息补充LXISTRADEINSURED_TEMP表
             insert into LXISTRADEINSURED_TEMP(
                serialno,
                DEALNO,
                CSNM,
                INSUREDNO,
                ISTN,
                IITP,
                OITP,
                ISID,
                RLTP,
                DataBatchNo,
                MakeDate,
                MakeTime,
                ModifyDate,
                ModifyTime)
            (
                select getSerialno(sysdate) as serialno,
               LPAD(v_dealNo,20,'0') AS DealNo,
           b.contno as CSNM,
           a.clientno as INSUREDNO,
           a.name as ISTN,
           a.cardtype as IITP,
           nvl(a.OtherCardType, '@N') as OITP,
           a.cardid as ISID,
           b.relaappnt as RLTP,
           v_dataBatchNo as DataBatchNo,
           sysdate as MakeDate,
           to_char(sysdate, 'hh24:mi:ss') as MakeTime,
           '' as ModifyDate,
           '' as ModifyTime
      from cr_client a, cr_rel b, cr_risk c
     where a.clientno = b.clientno
       and b.contno = c.contno
       and b.custype = 'I'
       and b.contno in
           (select d.contno from cr_rel d where d.clientno = v_Customno));

           --人工补正信息补充LXISTRADEINSURED_TEMP表
           insert into LXISTRADEBNF_TEMP(
              serialno,
              DealNo,
              CSNM,
              InsuredNo,
              BnfNo,
              BNNM,
              BITP,
              OITP,
              BNID,
              DataBatchNo,
              MakeDate,
              MakeTime,
              ModifyDate,
              ModifyTime)
          (
             select getSerialno(sysdate) as serialno,
               LPAD(v_dealNo,20,'0') AS DealNo,
         b.contno as CSNM,
         (select t. clientno
            from cr_rel t
           where t.custype = 'I'
             and t.contno = b.contno) as InsuredNo,
         a.clientno as BnfNo,
         a.name as BNNM,
         a.cardtype as BITP,
         nvl(a.OtherCardType, '@N') as OITP,
         a.cardid as BNID,
         v_dataBatchNo as DataBatchNo,
         sysdate as MakeDate,
         to_char(sysdate, 'hh24:mi:ss') as MakeTime,
         '' as ModifyDate,
         '' as ModifyTime
    from cr_client a, cr_rel b, cr_risk c
   where a.clientno = b.contno
     and b.contno = c.contno
     and b.custype = 'B'
     and b.contno in
         (select d.contno from cr_rel d where d.clientno = v_Customno));
    end;

 -- 更新大额/可疑业务临时表中的批次号
  update Lxihtrademain_Temp set Databatchno = v_dataBatchNo;   -- 大额交易主表-临时表
  update Lxihtradedetail_Temp set Databatchno = v_dataBatchNo; -- 大额交易明细表-临时表
  update Lxistrademain_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易信息主表-临时表
  update Lxistradedetail_Temp set Databatchno = v_dataBatchNo; -- 可疑交易明细信息-临时表
  update Lxistradecont_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易合同信息-临时表
  update Lxistradeinsured_Temp set Databatchno = v_dataBatchNo;-- 可疑交易被保人信息-临时表
  update Lxistradebnf_Temp set Databatchno = v_dataBatchNo;    -- 可疑交易受益人信息-临时表
  update Lxaddress_Temp set Databatchno = v_dataBatchNo;       -- 交易主体联系方式-临时表

	--将临时表转码
	proc_aml_mappingcode(v_dataBatchNo);

  -- 将大额/可疑业务临时表中数据迁移到业务表（去重）
  proc_aml_data_migration(v_dataBatchNo);

  	-- 查找业务表中已经插入的数据记录到提取日志表中
  PROC_AML_INS_LX_LXCALLOG('system',v_dataBatchNo);

	-- 将成功提取的数据记录到提取结果表中
	PROC_AML_INS_LX_LDBATCHLOG(v_dataBatchNo,'01',trunc(sysdate),'提取成功！');

  commit;

  --异常处理
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;

  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=to_char((v_baseLine-2),'yyyy-mm-dd')||errorCode||errorMsg;

	-- 将提取失败的信息记录到提取结果表中
	PROC_AML_INS_LX_LDBATCHLOG(v_dataBatchNo,'00',trunc(sysdate),v_errormsg);
  commit;

end proc_aml_0000;
/

prompt
prompt Creating procedure PROC_AML_026
prompt ===============================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_026 (p_item in varchar2,p_reportid in varchar2,p_managecom in varchar2,p_date in date ,p_time in varchar2)
iS 
    p_startDate date:=to_date(p_item||'01'||'01','yyyymmdd');
    p_endDate date:=to_date(p_item||'12'||'31','yyyymmdd');
    
BEGIN
  NULL;
  
  
  
  
  
  
  
  
  
  
  
  
  
  
END PROC_AML_026;
/

prompt
prompt Creating procedure PROC_AML_INS_LXADDRESS
prompt =========================================
prompt
create or replace procedure proc_aml_ins_lxaddress(
	i_dealno in lxaddress_temp.dealno%type,
	i_clientno in cr_address.clientno%type
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXADDRESS_TEMP表
  -- parameter in: i_dealno    交易编号(业务表)
  --               i_clientno  客户号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/18
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/03/18  初版
  -- =============================================

  INSERT INTO LXADDRESS_TEMP (
    serialno,
		DealNo,
		ListNo,
		CSNM,
		Nationality,
		LinkNumber,
		Adress,
		CusOthContact,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
  (
		select
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			ROW_NUMBER () OVER (ORDER BY clientno) AS ListNo,
			A.clientno AS CSNM,
			A.nationality AS Nationality,
			A.linknumber AS LinkNumber,
			A.adress AS Adress,
			A.cusothcontact AS CusOthContact,
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'hh24:mi:ss') AS MakeTime,
			'' AS ModifyDate,
			'' AS ModifyTime
		from
			CR_ADDRESS A
		where
			A.clientno = i_clientno
  );

end proc_aml_ins_lxaddress;
/

prompt
prompt Creating procedure PROC_AML_INS_LXIHTRADEDETAIL
prompt ===============================================
prompt
create or replace procedure proc_aml_ins_lxihtradedetail(

	i_dealno in varchar2,
  i_contno in varchar2,
	i_transno in VARCHAR2,
	i_baseLine in DATE,
	i_triggerflag in VARCHAR2

)is
begin
  -- ============================================
  -- Description: 根据规则筛选结果更新LXIHTradeMain_Temp表
  -- parameter in: i_clientno 客户号
  --               i_dealno   交易编号
	--               i_operator 操作人
  --               i_stcr     大额交易特征代码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/04/08
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/01  初版
  -- =============================================

  insert into LXIHTRADEDETAIL_TEMP(
    serialno,
		DealNo,			--交易编号
		PolicyNo,		--保单号
		TICD,				--业务标示号
		ContType,		--保险类型
		FINC,				--金融机构网点代码
		RLFC,				--金融机构与客户的关系
		CATP,				--账户类型
		CTAC,				--账号
		OATM,				--客户账户开立时间
		CBCT, 			--客户银行卡类型
		OCBT,				--客户银行卡其他类型
		CBCN,				--客户银行卡号码
		TBNM,				--交易代办人姓名
		TBIT,				--交易代办人身份证件/证明文件类型
		OITP,				--其他身份证件/证明文件类型
		TBID,				--交易代办人身份证件/证明文件号码
		TBNT,				--交易代办人国籍
		TSTM,				--交易时间
		RPMT,				--收付款方匹配号类型
		RPMN,				--收付款方匹配号
		TSTP,				--交易方式
		OCTT,				--非柜台交易方式
		OOCT,				--其他非柜台交易方式
		OCEC,				--非柜台交易方式的设备代码
		BPTC,				--银行与支付机构之间的业务交易编码
		TSCT,				--涉外收支交易分类与代码
		TSDR,				--资金收付标识
		TRCD,				--交易发生地
		CRPP,				--资金用途
		CRTP,				--币种
		CRAT,				--交易金额
		CFIN,				--对方金融机构网点名称
		CFCT,				--对方金融机构代码类型
		CFIC,				--对方金融交易网点代码
		CFRC,				--对方金融机构网点行政区划代码
		TCNM,				--交易对手名称
		TCIT,				--交易对手证件类型
		OTTP,				--其他身份证件/证明文件类型
		TCID,				--交易对手证件号码
		TCAT,				--交易对手账号类型
		TCAC,				--交易对手账号
		CRMB,				--交易金额（折人民币）
		CUSD,				--交易金额（折美元）
		ROTF,				--交易信息备注
		DataState,	--数据状态
		DataBatchNo,--数据批次号
		MakeDate,		--入库日期
		MakeTime,		--入库时间
		ModifyDate,	--最后更新日期
		ModifyTime,	--最后更新时间
		triggerflag)--指标统计标识
(
    select
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') as dealno,
			t.CONTNO AS PolicyNo,
			t.transno AS TICD,
			t.conttype AS ContType,
			nvl(p.locid, '@N') AS FINC,
			nvl(t.RelationWithRegion, '@N') AS RLFC,
			nvl(t.AccType, '@N') AS CATP,
			nvl(t.accno, '@N') AS CTAC,
			nvl(to_char(t.AccOpenTime,'yyyymmddHH24mmss'),'@N') AS OATM,
			nvl(t.bankcardtype,'@N') AS CBCT,
			nvl(t.BankCardOtherType,'@N') AS OCBT,
			nvl(t.bankcardnumber,'@N')AS CBCN,
			nvl(t.AgentName, '@N') AS TBNM,
			nvl(t.AgentCardType, '@N') AS TBIT,
			nvl(t.agentothercardtype, '@N') AS OITP,
			nvl(t.agentcardid, '@N') AS TBID,
			nvl(t.agentnationality, '@N') AS TBNT,
			to_char(i_baseLine,'YYYYMMDDHH24MISS') AS TSTM,
			nvl(t.RPMatchNoType, '@N')AS RPMT,
			nvl(t.RPMatchNumber, '@N')AS RPMN,
			'000051' AS TSTP,
			nvl(t.NonCounterTranType, '@N') AS OCTT,
			nvl(t.NonCounterOthTranType,'@N')AS OOCT,
			nvl(t.NonCounterTranDevice,'@N')AS OCEC,
			nvl(t.BankPaymentTranCode, '@N') AS BPTC,
			nvl(t.ForeignTransCode,'000000') AS TSCT,
			nvl(t.PayWay, '@N') AS TSDR,
			t.TransFromRegion AS TRCD,
			'@N' AS CRPP,
			nvl(t.CureType, 'CNY') AS CRTP,
			t.payamt AS CRAT,
			nvl(t.OpposideFinaName, '@N') AS CFIN,
			'@N' AS CFCT,
			nvl(t.OpposideFinaCode, '@N') AS CFIC,
			nvl(t.OpposideZipCode, '@N') AS CFRC,
			nvl(t.TradeCusName, '@N') AS TCNM,
			nvl(t.TradeCusCardType, '@N') AS TCIT,
			nvl(t.tradecusothercardtype,'@N') AS OTTP,
			nvl(t.TradeCusCardID, '@N') AS TCID,
			nvl(t.TradeCusAccType, '@N') AS TCAT,
			nvl(t.TradeCusAccNo, '@N') AS TCAC,
			nvl(t.CRMB, '@N') AS CRMB,
			nvl(t.CUSD, '@N') AS CUSD,
			t.remark AS ROTF,
			'' AS DataState,
			'' AS DataBatchNo,
			to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
      to_char(sysdate,'hh24:mi:ss') as maketime,
			'' AS ModifyDate,
			'' AS ModifyTime,
			i_triggerflag AS triggerflag
		FROM
			cr_rel r,
			cr_trans t,
			cr_policy p
		WHERE
				r.contno = t.contno
		and t.contno = p.contno
		and t.transno = i_transno
    and t.contno=i_contno
  );

end proc_aml_ins_lxihtradedetail;
/

prompt
prompt Creating procedure PROC_AML_INS_LXIHTRADEMAIN
prompt =============================================
prompt
create or replace procedure proc_aml_ins_lxihtrademain(

	i_dealno in number,
	i_transno in varchar2,
  i_contno in varchar2,
	i_operator in varchar2,
	i_crcd in varchar2,
	i_baseLine in DATE

) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXIHTradeMain_Temp表
  -- parameter in: i_dealno   交易编号
	--							 i_clientno 客户号
	--               i_operator 操作人
  --               i_crcd     大额交易特征代码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/04/08
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/01  初版
  -- =============================================

  insert into LXIHTRADEMAIN_TEMP(
      serialno,
			DealNo,
			CSNM,
			CRCD,
			CTVC,
			CustomerName,
			IDType,
			OITP,
			IDNo,
			HTDT,
			DataState,
			Operator,
			ManageCom,
			Typeflag,
			Notes,
			CustomerType,
			BaseLine,
			GetDataMethod,
			NextFileType,
			NextReferFileNo,
			NextPackageType,
			DataBatchNo,
			MakeDate,
			MakeTime,
			ModifyDate,
			ModifyTime,
			JudgmentDate		)
(
			select
        getSerialno(sysdate) as serialno,
				LPAD(i_dealno,20,'0') AS DealNo,
				c.clientno AS CSNM,
				i_crcd AS CRCD,
				nvl(c.businesstype, '@N') AS CTVC,
				c.NAME AS CustomerName,
				nvl(c.CardType, '@N') AS IDType,
				nvl(c.OtherCardType, '@N') AS OITP,
				c.CardID AS IDNo,
				t.transdate AS HTDT,
				'A01' AS DataState,
				i_operator AS OPERATOR,
				(select LocId from cr_policy where contno=i_contno) AS ManageCom,
				t.conttype AS Typeflag,
				'' AS Notes,
				c.ClientType AS CustomerType,
				i_baseLine AS BaseLine,
				'01' AS GetDataMethod,
				'' AS NextFileType,
				'' AS NextReferFileNo,
				'' AS NextPackageType,
				'' AS DataBatchNo,
				to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
				to_char(sysdate,'hh24:mi:ss') as maketime,
				'' AS ModifyDate,
				'' AS ModifyTime,
				'' AS JudgmentDate
			FROM
				cr_client c,
				cr_rel r,
				cr_trans t
			WHERE
         	c.clientno = r.clientno
			AND r.contno = t.contno
      and r.custype='O'
      and t.transno = i_transno
      and r.contno=i_contno
  );

end proc_aml_ins_lxihtrademain;
/

prompt
prompt Creating procedure PROC_AML_0501
prompt ================================
prompt
create or replace procedure proc_aml_0501(i_baseLine in date,i_oprater in VARCHAR2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('0501', 'M1'); -- 阀值

begin
  -- ============================================
  -- Rule:
  -- 当日单笔交易人民币5万元以上（含5万元）的现金缴存、现金支取及其他形式的现金收支。
  -- 现金缴存：指进入PMCL的所有交易记录（除'6'以外)
  -- 报送数据格式同现有可疑交易格式
  -- 1)保费类收入的所有交易记录（除'6'以外)，以匹配日为基准日汇总。
  --       注：此项中，基准日期相同、保单编号相同的收入交易总额为一笔交易
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/04/09
  -- Changes log:
  --     Author     Date        Description
  --     胡吉祥   2019/05/14    修改为通过保单号进行分组计算阀值
  -- ============================================

  declare
    cursor baseInfo_sor is
      select
          r.clientno,
          t.transno,
          t.contno
      from
          cr_trans t, cr_rel r
      where
          t.contno = r.contno
      and exists (
          select 1
          from
              cr_trans tmp_t
          where
              r.contno = tmp_t.contno
          and tmp_t.transtype not in (select code from ldcode where codetype = 'transtype_thirdparty')
          and tmp_t.paymode = '01'
          and tmp_t.payway in ('01','02')
          and tmp_t.conttype = '1'
          and trunc(tmp_t.transdate) = trunc(i_baseLine)
          group by
              tmp_t.contno
          having
              sum(abs(tmp_t.payamt))>=v_threshold_money
          )
      and t.paymode='01'          -- 资金进出方式为现金
      and t.payway in ('01','02') -- 所有收付费
      and r.custype = 'O'         -- 客户类型：O-投保人
      and t.conttype = '1'        -- 保单类型：1-个单
      and trunc(t.transdate) = trunc(i_baseLine)
      order by
          r.clientno ,t.transdate desc;

    -- 定义变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易编号
    c_contno cr_trans.contno%type;      -- 保单号

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;--针对所有符合规则数据进行循环
      exit when baseInfo_sor%notfound;                      --游标循环出口(没有发生触发规则的交易)

        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo :=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号
            v_clientno := c_clientno; -- 更新客户号

            -- 插入大额交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXIHTRADEMAIN(v_dealNo, c_transno, c_contno, i_oprater, '0501', i_baseLine);
            -- 插入大额交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXIHTRADEDETAIL(v_dealNo, c_contno,c_transno,i_baseLine, '1');
        else
            -- 插入大额交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXIHTRADEDETAIL(v_dealNo, c_contno,c_transno,i_baseLine, '');
      end if;

      -- 插入客户联系方式表_临时表 LXADDRESS_TEMP
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_0501;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADEBNF
prompt ============================================
prompt
create or replace procedure proc_aml_ins_lxistradebnf(

  i_dealno in NUMBER,
  i_contno in VARCHAR2
  
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lLXISTRADEBNF_TEMP表
  -- parameter in: i_dealno 交易编号(业务表)
  --               i_contno 保单号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/15
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/03/15  初版
  -- =============================================

  insert into LXISTRADEBNF_TEMP(
    serialno,
    DealNo,
    CSNM,
    InsuredNo,
    BnfNo,
    BNNM,
    BITP,
    OITP,
    BNID,
    DataBatchNo,
    MakeDate,
    MakeTime,
    ModifyDate,
    ModifyTime)
(
      SELECT
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') AS DealNo,
      i_contno AS CSNM,
      i.InsuredNo AS InsuredNo,
      c.clientno AS BnfNo,
      c.NAME AS BNNM,
      nvl(c.cardtype,'@N') AS BITP,
      nvl((select ld.basicremark from ldcodemapping ld where ld.basiccode=c.cardtype and ld.targetcode='119999' and ld.codetype='aml_idtype'),'@N') AS OITP,
      c.cardid AS BNID,
      NULL AS DataBatchNo,
      sysdate AS MakeDate,
      to_char(sysdate,'HH:mm:ss') AS MakeTime,
      NULL AS ModifyDate,
      NULL AS ModifyTime
      FROM
          lxistradeinsured_temp i,
          cr_client c,
          cr_rel r
      WHERE
          c.clientno = r.clientno
      AND r.custype = 'B' 
      and i.csnm=i_contno
      and i.dealno=LPAD(i_dealno,20,'0') 
      and r.contno=i_contno     
  );
end proc_aml_ins_lxistradebnf;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADECONT
prompt =============================================
prompt
create or replace procedure proc_aml_ins_lxistradecont(
	i_dealno in varchar2,
	i_clientno in varchar2,
	i_contno in varchar2
) is
begin
  -- ============================================
  -- Description: 根据规则筛选结果更新LXISTRADECONT_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_clientno 客户号
  --               i_contno   保单号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/15
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/03/15  初版
  -- ============================================

  insert into LXISTRADECONT_TEMP(
    serialno,
    DealNo,
		CSNM,
		ALNM,
		AppNo,
		ContType,
		AITP,
		OITP,
		ALID,
		ALTP,
		ISTP,
		ISNM,
		RiskCode,
		Effectivedate,
		Expiredate,
		ITNM,
		ISOG,
		ISAT,
		ISFE,
		ISPT,
		CTES,
		FINC,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
  (
    SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_contno AS CSNM,
			(select c.name from cr_client ct,cr_rel rl where rl.clientno=ct.clientno and rl.custype='O' and rl.contno=r.contno) AS ALNM,
			(select c.clientno from cr_client ct,cr_rel rl where rl.clientno=ct.clientno and rl.custype='O' and rl.contno=r.contno) AS APPNO,
			p.conttype AS ContType,
			c.cardtype AS AITP,
			nvl(c.OtherCardType,'@N') AS OITP,
			nvl(c.cardid,'@N') AS ALID,
			c.clienttype AS ALTP,
			(select risktype from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from cr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS ISTP,
			(select riskname from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from cr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS ISNM,
			(select riskcode from (select rk.RISKTYPE,rk.RISKNAME,rk.RISKCODE,row_number() over(partition by rk.RISKTYPE order by rk.RISKCODE asc) rn from cr_risk rk where rk.contno=i_contno and rk.mainflag='00')  where rn = 1) AS RiskCode,
			p.effectivedate AS Effectivedate,
			p.expiredate AS Expiredate,
			p.insuredpeoples AS ITNM,
			p.inssubject AS ISOG,
			p.amnt AS ISAT,
			p.prem AS ISFE,
			p.paymethod AS ISPT,
			nvl(p.othercontinfo, '@N') AS CTES,
			p.locid AS FINC,
			NULL AS DataBatchNo,
			to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') AS MakeDate,
			to_char(sysdate,'HH:mm:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime
			from
				CR_POLICY p,
				CR_CLIENT c,
				CR_REL r
			where
					p.contno=r.contno
      and c.clientno=r.clientno
			and r.custype='O'
			and r.contno=i_contno
  );

end proc_aml_ins_lxistradecont;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADEDETAIL
prompt ===============================================
prompt
create or replace procedure proc_aml_ins_lxistradedetail(
	i_dealno in NUMBER,
	i_contno in VARCHAR2,
	i_transno in VARCHAR2,
	i_triggerflag in VARCHAR2
	) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXISTRADEDETAIL_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_ocontno  保单号
  --               i_transno  交易编号(平台表)
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/15
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/03/15  初版
  -- =============================================


  insert into LXISTRADEDETAIL_TEMP(
    serialno,
    DealNo,
		TICD,
		ICNM,
		TSTM,
		TRCD,
		ITTP,
		CRTP,
		CRAT,
		CRDR,
		CSTP,
		CAOI,
		TCAN,
		ROTF,
		DataState,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime,
		TRIGGERFLAG)
  (
    SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_transno AS TICD,
			i_contno AS ICNM,
			to_char(t.transdate,'yyyymmddHHmmss') AS TSTM,
			t.transfromregion AS TRCD,
			t.transtype AS ITTP,
			t.curetype AS CRTP,
			t.payamt AS CRAT,
			T.PAYWAY AS CRDR,
			T.PAYMODE AS CSTP,
			nvl(t.accbank,'@N') AS CAOI,
			nvl(t.accno,'@N') AS TCAN,
			nvl(t.remark, '@N') AS ROTF,
      'A01' as DataState,
			NULL  AS DataBatchNo,
		  to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') AS MakeDate,
			to_char(sysdate,'HH24:mi:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime,
			i_triggerflag AS TRIGGERFLAG
		from
			cr_trans t
		where
				t.contno = i_contno
		and t.transno = i_transno
  );

end proc_aml_ins_lxistradedetail;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADEINSURED
prompt ================================================
prompt
create or replace procedure proc_aml_ins_lxistradeinsured(
	i_dealno in NUMBER,
	i_contno in VARCHAR2
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXISTRADEINSURED_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_contno   保单号
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/15
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/03/15  初版
  -- =============================================

  insert into LXISTRADEINSURED_TEMP(
    serialno,
		DEALNO,
		CSNM,
		INSUREDNO,
		ISTN,
		IITP,
		OITP,
		ISID,
		RLTP,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
(
    SELECT
      getSerialno(sysdate) as serialno,
 			LPAD(i_dealno,20,'0') AS DealNo,
			i_contno AS CSNM,
			c.clientno AS INSUREDNO,
			c.NAME AS ISTN,
			nvl(c.cardtype, '@N') AS IITP,
			nvl(c.OtherCardType, '@N') AS OITP,
			c.cardid AS ISID,
			nvl(r.relaappnt, '@N') AS RLTP,
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'HH:mm:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime
			FROM
					cr_client c,
					cr_rel r
			WHERE
					c.clientno = r.clientno
			AND r.custype = 'I'
			AND r.contno = i_contno
  );

end proc_aml_ins_lxistradeinsured;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADEMAIN
prompt =============================================
prompt
create or replace procedure proc_aml_ins_lxistrademain(

	i_dealno in NUMBER,
  i_clientno in varchar2,
  i_contno in varchar2,
  i_operator in varchar2,
  i_stcr in varchar2 ,
  i_baseLine in DATE) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lxistrademain_temp表
  -- parameter in: i_clientno 客户号
  --               i_dealno   交易编号
	--               i_operator 操作人
  --               i_stcr     可疑交易特征编码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/03/01
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/01  初版
  -- =============================================

  insert into lxistrademain_temp(
    serialno,
    dealno, -- 交易编号
    rpnc,   -- 上报网点代码
    detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
    torp,   -- 报送次数标志
    dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
    odrp,   -- 其他报送方向
    tptr,   -- 可疑交易报告触发点
    otpr,   -- 其他可疑交易报告触发点
    stcb,   -- 资金交易及客户行为情况
    aosp,   -- 疑点分析
    stcr,   -- 可疑交易特征
    csnm,   -- 客户号
    senm,   -- 可疑主体姓名/名称
    setp,   -- 可疑主体身份证件/证明文件类型
    oitp,   -- 其他身份证件/证明文件类型
    seid,   -- 可疑主体身份证件/证明文件号码
    sevc,   -- 客户职业或行业
    srnm,   -- 可疑主体法定代表人姓名
    srit,   -- 可疑主体法定代表人身份证件类型
    orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
    srid,   -- 可疑主体法定代表人身份证件号码
    scnm,   -- 可疑主体控股股东或实际控制人名称
    scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
    ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
    scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
    strs,   -- 补充交易标识
    datastate, -- 数据状态
    filename,  -- 附件名称
    filepath,  -- 附件路径
    rpnm,      -- 填报人
    operator,  -- 操作员
    managecom, -- 管理机构
    conttype,  -- 保险类型（01-个单, 02-团单）
    notes,     -- 备注
		baseline,       -- 日期基准
    getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入）
    nextfiletype,   -- 下次上报报文类型
    nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
    nextpackagetype,-- 下次上报报文包类型
    databatchno,    -- 数据批次号
    makedate,       -- 入库时间
    maketime,       -- 入库日期
    modifydate,     -- 最后更新日期
    modifytime,			-- 最后更新时间
		judgmentdate,   -- 终审日期
    ORXN,           -- 接续报告首次上报成功的报文名称
		ReportSuccessDate)-- 上报成功日期
(
    select
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') as dealno,
      '@N' as rpnc,
      '01' as detr,  -- 报告紧急程度（01-非特别紧急）
      '1' as torp,
      '01' as dorp,  -- 报送方向（01-报告中国反洗钱监测分析中心）
      '@N' as odrp,
      '01' as tptr,  -- 可疑交易报告触发点（01-模型筛选）
      '@N' as otpr,
      '' as stcb,
      '' as aosp,
      i_stcr as stcr,
      c.clientno as csnm,
      c.name as senm,
      nvl(c.cardtype,'@N') as setp,
      nvl(c.othercardtype,'@N') as oitp,
      nvl(c.cardid,'@N') as seid,
      nvl(c.occupation,'@N') as sevc,
      nvl(c.legalperson,'@N') as srnm,
      nvl(c.legalpersoncardtype,'@N') as srit,
      nvl(c.otherlpcardtype,'@N') as orit,
      nvl(c.legalpersoncardid,'@N') as srid,
      nvl(c.holdername,'@N') as scnm,
      nvl(c.holdercardtype,'@N') as scit,
      nvl(c.otherholdercardtype,'@N') as ocit,
      nvl(c.holdercardid,'@N') as scid,
      '@N' as strs,
      'A01' as datastate,
      '' as filename,
      '' as filepath,
      (select username from lduser where usercode = i_operator) as rpnm,
      i_operator as operator,
      (select locid from cr_policy where contno=i_contno) as managecom,
      c.conttype as conttype,
      '' as notes,
      i_baseLine as baseline,
      '01' as getdatamethod,  -- 数据获取方式（01-系统抓取）
      '' as nextfiletype,
      '' as nextreferfileno,
      '' as nextpackagetype,
      null as databatchno,
      to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
      to_char(sysdate,'hh24:mi:ss') as maketime,
      null as modifydate,  -- 最后更新时间
      null as modifytime,
			null as judgmentdate,--终审日期
      null as ORXN,        -- 接续报告首次上报成功的报文名称
			null as ReportSuccessDate--上报成功日期
    from
      cr_client c
    where
     c.clientno = i_clientno
  );

end proc_aml_ins_lxistrademain;
/

prompt
prompt Creating procedure PROC_AML_A0101
prompt =================================
prompt
create or replace procedure proc_aml_A0101(i_baseLine in date,
                                           i_oprater  in varchar2) is
  v_dealNo   lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno cr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --      投保人、被保人或受益人属于制裁名单内（层级匹配）,即被系统抓取生成可疑交易
  --      抽取条件：
  --        1) 抽取保单维度
  --          保单渠道：OLAS、IGM；
  --          抽取前一天有收/付费交易的保单；
  --        2) 若抽取保单的投保人、被保人、受益人的在制裁名单中存在，即被抓取。
  --      抽取结果：
  --        1）抽取命中制裁名单的该保单客户作为投保人或被保人或受益人名下所有保单的收/付费的交易行为；
  --        2）报送数据格式同现有可疑交易格式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date        Description
  --     胡吉祥   2019/05/14    修改为以客户为中心的展示信息（改变插入方式，添加if条件）
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;

  -- 获取作日发生交易的客户清单(投保人、被保人、受益人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0101_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and r.custype in ('O', 'I', 'B') -- 客户类型：O-投保人/I-被保人/B-受益人
       and t.payway in ('01', '02')
       and t.transtype not in
           (select code from ldcode where codetype = 'transtype_thirdparty')
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);

  --筛选证件号或姓名在制裁名单内的客户号
  insert into LXAssistA
    (CustomerNo, policyno, args1, args5)
    select lx.CustomerNo, lx.policyno, lx.args1, 'A0101_2'
      from lxassista lx
     where (exists (select 1
                      from lxblacklist b
                     where lx.args1 = b.idnumber
                       and description2 = '1'
                       and description1 = '3'
                       and type = '1') or exists
            (select 1
               from lxblacklist b
              where (lx.args2 = b.name or lx.args2 = b.ename)
                and description2 = '1'
                and description1 = '3'
                and type = '1'))
       and lx.args5 = 'A0101_1';
       
    --抓取制裁名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0101_3'
        from lxassista lx
       where isblacklist('1', lx.CustomerNo, lx.policyno, '') = 'yes'
         and lx.args5 = 'A0101_2';
  
  delete from lxassista where args5='A0101_1';

  -- 制裁名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
  insert into lxassista
    (customerno, args1, args5)
    select max(lx.customerno), lx.args1, 'A0101_4'
      from lxassista lx
     where lx.args5= 'A0101_3'
     group by lx.args1;

  --抓取客户名下所有有效保单，根据证件号匹配保单号
  insert into LXAssistA
    (PolicyNo, args1, args5)
    select distinct p.contno, lx.args1, 'A0101_5'
      from cr_policy p
      join cr_rel r
        on p.contno = r.contno
       and isvalidcont(p.contno) = 'yes' --有效保单
      join lxassista lx
        on lx.args1 = r.usecardid
       and lx.args5 = 'A0101_4';

  --匹配客户和客户对应的保单
  insert into LXAssistA
    (customerno,PolicyNo,args5)
    select lx.customerno,la.PolicyNo,'A0101_6'
      from LXAssistA lx
      join LXAssistA la
        on lx.args1=la.args1
       and lx.args5= 'A0101_4'
       and la.args5= 'A0101_5';

  declare
    -- 定义游标：保存投保人、被保人或受益人属于制裁名单的信息
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate
        from cr_trans t
        join LXAssistA lx
          on t.contno=lx.policyno
         and lx.args5= 'A0101_6'
       where t.payway in ('01', '02')
         and t.transtype not in
             (select code
                from ldcode
               where codetype = 'transtype_thirdparty')
         and t.conttype = '1'
       order by lx.CustomerNo, t.transdate desc;

    -- 定义游标变量
    c_clientno  lxassista.CustomerNo%type; -- 客户号
    c_transno   cr_trans.transno%type; -- 交易号
    c_contno    cr_trans.contno%type; -- 保单号
    c_transdate cr_trans.transdate%type; -- 交易日期

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor
        into c_clientno, c_transno, c_contno, c_transdate;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表
      if v_clientno is null or c_clientno <> v_clientno then

        v_dealNo   := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        v_clientno := c_clientno; -- 更新可疑主体的客户号

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SA0101',
                                   i_baseLine);

        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
  delete from LXAssistA;
end proc_aml_A0101;
/

prompt
prompt Creating procedure PROC_AML_INS_LXISTRADEMAIN2
prompt ==============================================
prompt
create or replace procedure proc_aml_ins_lxistrademain2(

	i_dealno in NUMBER,
  i_clientno in varchar2, 
  i_contno in varchar2,
  i_operator in varchar2,
  i_stcr in varchar2 ,
  i_baseLine in DATE,
  i_aosp in   varchar2) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lxistrademain_temp表
  -- parameter in: i_clientno 客户号
  --               i_dealno   交易编号
	--               i_operator 操作人
  --               i_stcr     可疑交易特征编码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/03/01
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/01  初版
  -- =============================================

  insert into lxistrademain_temp(
    serialno,
    dealno, -- 交易编号
    rpnc,   -- 上报网点代码
    detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
    torp,   -- 报送次数标志
    dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
    odrp,   -- 其他报送方向
    tptr,   -- 可疑交易报告触发点
    otpr,   -- 其他可疑交易报告触发点
    stcb,   -- 资金交易及客户行为情况
    aosp,   -- 疑点分析
    stcr,   -- 可疑交易特征
    csnm,   -- 客户号
    senm,   -- 可疑主体姓名/名称
    setp,   -- 可疑主体身份证件/证明文件类型
    oitp,   -- 其他身份证件/证明文件类型
    seid,   -- 可疑主体身份证件/证明文件号码
    sevc,   -- 客户职业或行业
    srnm,   -- 可疑主体法定代表人姓名
    srit,   -- 可疑主体法定代表人身份证件类型
    orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
    srid,   -- 可疑主体法定代表人身份证件号码
    scnm,   -- 可疑主体控股股东或实际控制人名称
    scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
    ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
    scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
    strs,   -- 补充交易标识
    datastate, -- 数据状态
    filename,  -- 附件名称
    filepath,  -- 附件路径
    rpnm,      -- 填报人
    operator,  -- 操作员
    managecom, -- 管理机构
    conttype,  -- 保险类型（01-个单, 02-团单） 
    notes,     -- 备注
		baseline,       -- 日期基准
    getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入） 
    nextfiletype,   -- 下次上报报文类型
    nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
    nextpackagetype,-- 下次上报报文包类型
    databatchno,    -- 数据批次号
    makedate,       -- 入库时间
    maketime,       -- 入库日期
    modifydate,     -- 最后更新日期
    modifytime,			-- 最后更新时间
		judgmentdate,   -- 终审日期
    ORXN,           -- 接续报告首次上报成功的报文名称
		ReportSuccessDate)-- 上报成功日期
(
    select
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') as dealno,
      '@N' as rpnc,
      '01' as detr,  -- 报告紧急程度（01-非特别紧急）
      '1' as torp,
      '01' as dorp,  -- 报送方向（01-报告中国反洗钱监测分析中心）
      '@N' as odrp,
      '01' as tptr,  -- 可疑交易报告触发点（01-模型筛选）
      '@N' as otpr,
      '' as stcb,
      (select codename from ldcode where code=i_aosp and codetype='aml_rulereason' ) as aosp,
      i_stcr as stcr,
      c.clientno as csnm,
      c.name as senm,
      nvl(c.cardtype,'@N') as setp,
      nvl(c.othercardtype,'@N') as oitp,
      nvl(c.cardid,'@N') as seid,
      nvl(c.occupation,'@N') as sevc,
      nvl(c.legalperson,'@N') as srnm,
      nvl(c.legalpersoncardtype,'@N') as srit,
      nvl(c.otherlpcardtype,'@N') as orit,
      nvl(c.legalpersoncardid,'@N') as srid,
      nvl(c.holdername,'@N') as scnm,
      nvl(c.holdercardtype,'@N') as scit,
      nvl(c.otherholdercardtype,'@N') as ocit,
      nvl(c.holdercardid,'@N') as scid,
      '@N' as strs,
      'A01' as datastate,
      '' as filename,
      '' as filepath,
      (select username from lduser where usercode = i_operator) as rpnm,
      i_operator as operator,
      (select locid from cr_policy where contno=i_contno) as managecom,
      c.conttype as conttype,
      '' as notes,
      i_baseLine as baseline,
      '01' as getdatamethod,  -- 数据获取方式（01-系统抓取）
      '' as nextfiletype,
      '' as nextreferfileno,
      '' as nextpackagetype,
      null as databatchno,
      to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
      to_char(sysdate,'hh24:mi:ss') as maketime,
      null as modifydate,  -- 最后更新时间
      null as modifytime,
			null as judgmentdate,--终审日期
      null as ORXN,        -- 接续报告首次上报成功的报文名称
			null as ReportSuccessDate--上报成功日期
    from
      cr_client c
    where
     c.clientno = i_clientno
  );

end proc_aml_ins_lxistrademain2;
/

prompt
prompt Creating procedure PROC_AML_A0101_TEST
prompt ======================================
prompt
create or replace procedure proc_aml_A0101_test(i_baseLine in date,
                                           i_oprater  in varchar2) is
  v_dealNo   lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno cr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --      投保人、被保人或受益人属于制裁名单内（层级匹配）,即被系统抓取生成可疑交易
  --      抽取条件：
  --        1) 抽取保单维度
  --          保单渠道：OLAS、IGM；
  --          抽取前一天有收/付费交易的保单；
  --        2) 若抽取保单的投保人、被保人、受益人的在制裁名单中存在，即被抓取。
  --      抽取结果：
  --        1）抽取命中制裁名单的该保单客户作为投保人或被保人或受益人名下所有保单的收/付费的交易行为；
  --        2）报送数据格式同现有可疑交易格式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date        Description
  --     胡吉祥   2019/05/14    修改为以客户为中心的展示信息（改变插入方式，添加if条件）
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;

  -- 获取作日发生交易的客户清单(投保人、被保人、受益人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0101_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and r.custype in ('O', 'I', 'B') -- 客户类型：O-投保人/I-被保人/B-受益人
       and t.payway in ('01', '02')
       and t.transtype not in
           (select code from ldcode where codetype = 'transtype_thirdparty')
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);

  --筛选证件号或姓名在制裁名单内的客户号
  insert into LXAssistA
    (CustomerNo, policyno, args1, args5)
    select lx.CustomerNo, lx.policyno, lx.args1, 'A0101_2'
      from lxassista lx
     where (exists (select 1
                      from lxblacklist b
                     where lx.args1 = b.idnumber
                       and description2 = '1'
                       and description1 = '3'
                       and type = '1') or exists
            (select 1
               from lxblacklist b
              where (lx.args2 = b.name or lx.args2 = b.ename)
                and description2 = '1'
                and description1 = '3'
                and type = '1'))
       and lx.args5 = 'A0101_1';

  --抓取制裁名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1,args2, args5)
      select lx.CustomerNo, lx.policyno, lx.args1,
        isblacklist2('1', lx.CustomerNo, lx.policyno, '') as aosp,
       'A0101_3'
        from lxassista lx
       where lx.args5 = 'A0101_2';
               
  delete from lxassista where args5='A0101_1';

  -- 制裁名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
  insert into lxassista
    (customerno, args1,args2, args5)
    select max(lx.customerno), lx.args1,min(substr(lx.args2,4)),'A0101_4'
      from lxassista lx
     where substr(lx.args2,0,3)='yes'
     and lx.args5= 'A0101_3'
     group by lx.args1;

  --抓取客户名下所有有效保单，根据证件号匹配保单号
  insert into LXAssistA
    (PolicyNo, args1, args5)
    select distinct p.contno, lx.args1, 'A0101_5'
      from cr_policy p
      join cr_rel r
        on p.contno = r.contno
       and isvalidcont(p.contno) = 'yes' --有效保单
      join lxassista lx
        on lx.args1 = r.usecardid
       and lx.args5 = 'A0101_4';
  
  --匹配客户和客户对应的保单     
  insert into LXAssistA
    (customerno,PolicyNo,args1,args5)
    select lx.customerno,la.PolicyNo,lx.args2,'A0101_6'
      from LXAssistA lx
      join LXAssistA la
        on lx.args1=la.args1
       and lx.args5= 'A0101_4'
       and la.args5= 'A0101_5';

  declare
    -- 定义游标：保存投保人、被保人或受益人属于制裁名单的信息
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate,lx.args1
        from cr_trans t
        join LXAssistA lx
          on t.contno=lx.policyno
         and lx.args5= 'A0101_6'
       where t.payway in ('01', '02')
         and t.transtype not in
             (select code
                from ldcode
               where codetype = 'transtype_thirdparty')
         and t.conttype = '1'
       order by lx.CustomerNo, t.transdate desc;
  
    -- 定义游标变量
    c_clientno  lxassista.CustomerNo%type; -- 客户号
    c_transno   cr_trans.transno%type; -- 交易号
    c_contno    cr_trans.contno%type; -- 保单号
    c_transdate cr_trans.transdate%type; -- 交易日期
    c_aosp lxassista.args1%type; --疑点分析编码
    
  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor
        into c_clientno, c_transno, c_contno, c_transdate, c_aosp;
      exit when baseInfo_sor%notfound;
    
      -- 当天发生的触发规则交易，插入到主表
      if v_clientno is null or c_clientno <> v_clientno then
      
        v_dealNo   := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)
        v_clientno := c_clientno; -- 更新可疑主体的客户号
      
        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN2(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SA0101',
                                   i_baseLine,c_aosp);
      
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');
      end if;
    
      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);
    
      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);
    
      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);
    
      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    
    end loop;
    close baseInfo_sor;
  end;
  delete from LXAssistA;
end proc_aml_A0101_test;
/

prompt
prompt Creating procedure PROC_AML_A0102
prompt =================================
prompt
create or replace procedure proc_aml_A0102(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0102', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule:
  --   投保人“道琼斯名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，
  --   即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --   ?   保单渠道：OLAS、IGM；
  --   ?   抽取前一天生效的保单；
  --     2) 若抽取保单的投保人在“道琼斯名单和其他名单”中存在，且此人作为投保人或被保人
  --        受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --   ?  累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date        Description
  --     zhouqk   2019/05/11        初版
  --     zhouqk   2019/05/27     将证件号在道琼斯名单中改为层级匹配
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;

  -- 获取作日发生交易的客户清单(投保人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno,
                    r.contno,
                    r.USECARDID,
                    c.name,
                    'A0102_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and r.custype = 'O' -- 客户类型：O-投保人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);

    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0102_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0102_1';

    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0102_3'
        from lxassista lx
       where isblacklist('2', lx.CustomerNo, lx.policyno, '1') = 'yes'
         and lx.args5 = 'A0102_2';

    delete from lxassista where args5='A0102_1';

    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1, args5)
      select max(lx.customerno), lx.args1, 'A0102_4'
        from lxassista lx
       where lx.args5 = 'A0102_3'
       group by lx.args1;

    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0102_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0102_4';

    --匹配客户和客户对应的保单
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney, 'A0102_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0102_4'
         and la.args5 = 'A0102_5';


  declare
    -- 定义游标,保存投保人的证件号在道琼斯名单内，且当前累计已交保费大于等于阀值的信息
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0102_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0102_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc;

    -- 定义游标变量
    c_clientno cr_rel.clientno%type; -- 客户号
    c_transno cr_trans.transno%type; -- 交易编号
    c_contno cr_trans.contno%type;   -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno, c_transno, c_contno,c_transdate;
      exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0102', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
end;
  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0102;
/

prompt
prompt Creating procedure PROC_AML_A0102_TEST
prompt ======================================
prompt
create or replace procedure proc_aml_A0102_test(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0102', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule: 
  --   投保人“道琼斯名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，
  --   即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --   ?   保单渠道：OLAS、IGM；
  --   ?   抽取前一天生效的保单；
  --     2) 若抽取保单的投保人在“道琼斯名单和其他名单”中存在，且此人作为投保人或被保人
  --        受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --   ?  累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date        Description
  --     zhouqk   2019/05/11        初版
  --     zhouqk   2019/05/27     将证件号在道琼斯名单中改为层级匹配
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;
  
  -- 获取作日发生交易的客户清单(投保人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno,
                    r.contno,
                    r.USECARDID,
                    c.name,
                    'A0102_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and r.custype = 'O' -- 客户类型：O-投保人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);
  
    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0102_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0102_1';
    
    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1, args2,args5)
      select lx.CustomerNo, lx.policyno, lx.args1,
       isblacklist2('2', lx.CustomerNo, lx.policyno, '1'),
       'A0102_3'
        from lxassista lx
       where lx.args5 = 'A0102_2';
         
    delete from lxassista where args5='A0102_1';
    
    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1,args2, args5)
      select max(lx.customerno), lx.args1,min(substr(lx.args2,4)), 'A0102_4'
        from lxassista lx
       where substr(lx.args2,0,3)='yes'
       and lx.args5 = 'A0102_3'
       group by lx.args1;
       
    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0102_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0102_4';
    
    --匹配客户和客户对应的保单     
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney,args1, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney,lx.args2, 'A0102_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0102_4'
         and la.args5 = 'A0102_5';
         

    

  declare
    -- 定义游标,保存投保人的证件号在道琼斯名单内，且当前累计已交保费大于等于阀值的信息
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate,lx.args1
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0102_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0102_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc; 
                     
    -- 定义游标变量
    c_clientno cr_rel.clientno%type; -- 客户号
    c_transno cr_trans.transno%type; -- 交易编号
    c_contno cr_trans.contno%type;   -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期
    c_aosp lxassista.args1%type; --疑点分析编码
    
  begin
    open baseInfo_sor;                
    loop
      fetch baseInfo_sor into c_clientno, c_transno, c_contno,c_transdate,c_aosp;
      exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            
          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN2(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0102', i_baseLine,c_aosp);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else      
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
              
    end loop;
    close baseInfo_sor;
end;
  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0102_test;
/

prompt
prompt Creating procedure PROC_AML_A0103
prompt =================================
prompt
create or replace procedure proc_aml_A0103(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0103', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule:
  --   被保人在“政要名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --   ?   保单渠道：OLAS、IGM；
  --   ?   抽取前一天生效的保单；
  --     2) 若抽取保单的被保人在“政要名单和其他名单”中存在，且此人作为投保人或被保人或
  --        受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --   ?   累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --     2）如果新单的被保人和投保人是同一人，则将此人归在投保人（A0102）中报送
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date     Description
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;

  -- 获取作日发生交易的客户清单(被保人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0103_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and not exists
     (select 1
              from cr_rel tmp_r, cr_trans tmp_t
             where r.clientno = tmp_r.clientno
               and r.contno = tmp_r.contno
               and tmp_r.contno = tmp_t.contno
               and tmp_r.custype = 'O' -- 客户类型：O-投保人
               and tmp_t.transtype = 'AA001' --投保
               and tmp_t.conttype = '1' -- 保单类型：1-个单
               and trunc(tmp_t.transdate) = trunc(i_baseLine))
       and r.custype = 'I' -- 客户类型：I-被保人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);

    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0103_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0103_1';

    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0103_3'
        from lxassista lx
       where isblacklist('2', lx.CustomerNo, lx.policyno, '2') = 'yes'
         and lx.args5 = 'A0103_2';

    delete from lxassista where args5='A0103_1';

    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1, args5)
      select max(lx.customerno), lx.args1, 'A0103_4'
        from lxassista lx
       where lx.args5 = 'A0103_3'
       group by lx.args1;

    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0103_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0103_4';

    --匹配客户和客户对应的保单
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney, 'A0103_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0103_4'
         and la.args5 = 'A0103_5';


  declare
    -- 定义游标,保存之前所有进行投保的交易信息，并且累计已交保费金额大于阀值
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0103_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0103_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc;

    -- 定义游标变量
    c_clientno cr_rel.clientno%type; -- 客户号
    c_transno cr_trans.transno%type; -- 交易编号
    c_contno cr_trans.contno%type;   -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno, c_transno, c_contno,c_transdate;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0103', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
      else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor ;
  end;
  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0103;
/

prompt
prompt Creating procedure PROC_AML_A0103_TEST
prompt ======================================
prompt
create or replace procedure proc_aml_A0103_test(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0103', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule: 
  --   被保人在“政要名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --   ?   保单渠道：OLAS、IGM；
  --   ?   抽取前一天生效的保单；
  --     2) 若抽取保单的被保人在“政要名单和其他名单”中存在，且此人作为投保人或被保人或
  --        受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --   ?   累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --     2）如果新单的被保人和投保人是同一人，则将此人归在投保人（A0102）中报送
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date     Description
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;
  
  -- 获取作日发生交易的客户清单(被保人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0103_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and not exists
     (select 1
              from cr_rel tmp_r, cr_trans tmp_t
             where r.clientno = tmp_r.clientno
               and r.contno = tmp_r.contno
               and tmp_r.contno = tmp_t.contno
               and tmp_r.custype = 'O' -- 客户类型：O-投保人
               and tmp_t.transtype = 'AA001' --投保
               and tmp_t.conttype = '1' -- 保单类型：1-个单
               and trunc(tmp_t.transdate) = trunc(i_baseLine))
       and r.custype = 'I' -- 客户类型：I-被保人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);
  
    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0103_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0103_1';
    
    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1,args2, args5)
      select lx.CustomerNo, lx.policyno, lx.args1,
        isblacklist2('2', lx.CustomerNo, lx.policyno, '2'),
       'A0103_3'
        from lxassista lx
       where lx.args5 = 'A0103_2';
         
    delete from lxassista where args5='A0103_1';
    
    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1,args2, args5)
      select max(lx.customerno), lx.args1,min(substr(lx.args2,4)),'A0103_4'
        from lxassista lx
       where substr(lx.args2,0,3)='yes'
       and lx.args5 = 'A0103_3'
       group by lx.args1;
       
    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0103_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0103_4';
    
    --匹配客户和客户对应的保单     
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney,args1, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney,lx.args2, 'A0103_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0103_4'
         and la.args5 = 'A0103_5'; 

  declare
    -- 定义游标,保存之前所有进行投保的交易信息，并且累计已交保费金额大于阀值
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate,lx.args1
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0103_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0103_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc;
                     
    -- 定义游标变量
    c_clientno cr_rel.clientno%type; -- 客户号
    c_transno cr_trans.transno%type; -- 交易编号
    c_contno cr_trans.contno%type;   -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期
    c_aosp lxassista.args1%type; --疑点分析编码
    
  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno, c_transno, c_contno,c_transdate,c_aosp;
      exit when baseInfo_sor%notfound;

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            
          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN2(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0103', i_baseLine,c_aosp);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
      else      
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno); 

    end loop;
    close baseInfo_sor ;
  end;
  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0103_test;
/

prompt
prompt Creating procedure PROC_AML_A0104
prompt =================================
prompt
create or replace procedure proc_aml_A0104(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0104', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule:
  --   受益人在“政要名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --     ? 保单渠道：OLAS、IGM；
  --     ? 抽取前一天生效的保单；
  --     2) 若抽取保单的被保人在“政要名单和其他名单”中存在，且此人作为投保人或被保人
  --        或受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --        累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --     2）如果新单的受益人和被保人或投保人是同一人，则将此人归在投保人（A0102）或被保人（A0103)中报送
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date     Description
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;

  -- 获取作日发生交易的客户清单(受益人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0104_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and not exists
     (select 1
              from cr_rel tmp_r, cr_trans tmp_t
             where r.clientno = tmp_r.clientno
               and r.contno = tmp_r.contno
               and tmp_r.contno = tmp_t.contno
               and tmp_r.custype in ('O','I') -- 客户类型：O-投保人/I-被保人
               and tmp_t.transtype = 'AA001' --投保
               and tmp_t.conttype = '1' -- 保单类型：1-个单
               and trunc(tmp_t.transdate) = trunc(i_baseLine))
       and r.custype = 'B' -- 客户类型：B-受益人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);

    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0104_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0104_1';

    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0104_3'
        from lxassista lx
       where isblacklist('2', lx.CustomerNo, lx.policyno, '3') = 'yes'
         and lx.args5 = 'A0104_2';

    delete from lxassista where args5='A0104_1';

    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1, args5)
      select max(lx.customerno), lx.args1, 'A0104_4'
        from lxassista lx
       where lx.args5 = 'A0104_3'
       group by lx.args1;

    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0104_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0104_4';

    --匹配客户和客户对应的保单
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney, 'A0104_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0104_4'
         and la.args5 = 'A0104_5';


  -- 定义游标,保存之前所有进行投保的交易信息，并且累计已交保费金额大于阀值
  declare
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0104_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0104_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易编号
    c_contno cr_trans.contno%type;      -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno,c_transno,c_contno,c_transdate;
      exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0104', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor ;
end;

  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0104;
/

prompt
prompt Creating procedure PROC_AML_A0104_TEST
prompt ======================================
prompt
create or replace procedure proc_aml_A0104_TEST(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0104', 'M1'); -- 阀值 累计已交保费

begin
  -- =============================================
  -- Rule: 
  --   受益人在“政要名单和其他名单”（层级匹配）内，且当前累计已交保费大于等于阀值，即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --     ? 保单渠道：OLAS、IGM；
  --     ? 抽取前一天生效的保单；
  --     2) 若抽取保单的被保人在“政要名单和其他名单”中存在，且此人作为投保人或被保人
  --        或受益人名下所有有效保单的已交保费累计达到阀值，即被抓取。
  --        累计已交保费指：AA001,AA003,AA004,AB001,AB002, FC***,WT001,WT005,NP370中的
  --        收费部分（即：除HK001以外的收入交易）的总金额，若达到阀值，则抓取；
  --     3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --     1) 报送数据格式同现有可疑交易格式
  --     2）如果新单的受益人和被保人或投保人是同一人，则将此人归在投保人（A0102）或被保人（A0103)中报送
  --   注：若受益人的识别信息(ID/Sex/birth)不全，则不做比对
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/11
  -- Changes log:
  --     Author     Date     Description
  -- ============================================
  -- 先清空临时表
  delete from LXAssistA;
  
  -- 获取作日发生交易的客户清单(受益人)
  insert into LXAssistA
    (CustomerNo, policyno, args1, args2, args5)
    select distinct r.clientno, r.contno, r.USECARDID, c.name, 'A0104_1'
      from cr_client c, cr_rel r, cr_trans t
     where c.clientno = r.clientno
       and r.contno = t.contno
       and not exists
     (select 1
              from cr_rel tmp_r, cr_trans tmp_t
             where r.clientno = tmp_r.clientno
               and r.contno = tmp_r.contno
               and tmp_r.contno = tmp_t.contno
               and tmp_r.custype in ('O','I') -- 客户类型：O-投保人/I-被保人
               and tmp_t.transtype = 'AA001' --投保
               and tmp_t.conttype = '1' -- 保单类型：1-个单
               and trunc(tmp_t.transdate) = trunc(i_baseLine))
       and r.custype = 'B' -- 客户类型：B-受益人
       and t.transtype = 'AA001' --投保
       and t.conttype = '1' -- 保单类型：1-个单
       and trunc(t.transdate) = trunc(i_baseLine);
  
    --筛选证件号或姓名在PEP名单和其它名单内的客户号
    insert into LXAssistA
      (CustomerNo, policyno, args1, args5)
      select lx.CustomerNo, lx.policyno, lx.args1, 'A0104_2'
        from lxassista lx
       where (exists (select 1
                        from lxblacklist b
                       where lx.args1 = b.idnumber
                         and ((description1 = '1' and type = '1') or
                             type = '2')) or exists
              (select 1
                 from lxblacklist b
                where (lx.args2 = b.name or lx.args2 = b.ename)
                  and ((description1 = '1' and type = '1') or type = '2')))
         and lx.args5 = 'A0104_1';
    
    --抓取PEP名单和其它名单客户
    insert into LXAssistA
      (CustomerNo, policyno, args1,args2 ,args5)
      select lx.CustomerNo, lx.policyno, lx.args1,
      isblacklist2('2', lx.CustomerNo, lx.policyno, '3'),
       'A0104_3'
        from lxassista lx
       where lx.args5 = 'A0104_2';
         
    delete from lxassista where args5='A0104_1';
    
    -- PEP名单和其它名单客户去重（一个证件号对应多个客户号或者证件号、姓名均匹配到黑名单）
    insert into lxassista
      (customerno, args1,args2, args5)
      select max(lx.customerno), lx.args1,min(substr(lx.args2,4)), 'A0104_4'
        from lxassista lx
       where substr(lx.args2,0,3)='yes'
       and lx.args5 = 'A0104_3'
       group by lx.args1;
       
    --抓取客户名下所有有效保单，根据证件号匹配保单号
    insert into LXAssistA
      (PolicyNo, tranmoney, args1, args5)
      select distinct p.contno, p.sumprem, lx.args1, 'A0104_5'
        from cr_policy p
        join cr_rel r
          on p.contno = r.contno
         and isvalidcont(p.contno) = 'yes' --有效保单
        join lxassista lx
          on lx.args1 = r.usecardid
         and lx.args5 = 'A0104_4';
    
    --匹配客户和客户对应的保单     
    insert into LXAssistA
      (customerno, PolicyNo, tranmoney,args1, args5)
      select lx.customerno, la.PolicyNo, la.tranmoney,lx.args2 ,'A0104_6'
        from LXAssistA lx
        join LXAssistA la
          on lx.args1 = la.args1
         and lx.args5 = 'A0104_4'
         and la.args5 = 'A0104_5';

  -- 定义游标,保存之前所有进行投保的交易信息，并且累计已交保费金额大于阀值
  declare
    cursor baseInfo_sor is
      select lx.CustomerNo, t.transno, lx.policyno, t.transdate,lx.args1
        from cr_trans t
        join LXAssistA lx
          on t.contno = lx.policyno
         and lx.args5 = 'A0104_6'
         and exists (select 1
                from LXAssistA la
               where lx.customerno = la.customerno
                 and la.args5 = 'A0104_6'
               group by la.customerno
              having sum(la.tranmoney) >= v_threshold_money -- 累计已交保费大于等于阀值
              )
       where t.transtype = 'AA001' -- 交易类型为投保
         and t.conttype = '1' -- 保单类型：1-个单
       order by lx.CustomerNo, t.transdate desc;                                

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易编号
    c_contno cr_trans.contno%type;      -- 保单号
    c_transdate cr_trans.transdate%type;-- 交易日期
    c_aosp lxassista.args1%type; --疑点分析编码
    
  begin
    open baseInfo_sor;              
    loop
      fetch baseInfo_sor into c_clientno,c_transno,c_contno,c_transdate,c_aosp;
      exit when baseInfo_sor%notfound;  
       
        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
                
          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN2(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0104', i_baseLine,c_aosp);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else      
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno); 
          
    end loop;
    close baseInfo_sor ;
end;

  -- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_A0104_TEST;
/

prompt
prompt Creating procedure PROC_AML_A0200
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_A0200(i_baseLine in date, i_oprater  in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0200', 'M1'); -- 阀值

BEGIN
  -- =============================================
  -- Rule:
  --   若投保人的国籍属于高风险国家或地区（分值>=80)，
  --   且累计已交保费金额大于等于阀值，即被系统抓取，生成可疑交易；
  --   抽取条件：
  --     1) 抽取保单维度
  --     ? 保单渠道：OLAS、IGM；
  --     ? 抽取前一天生效的保单；
  --     2) 若抽取保单的投保人的国籍在高风险国家名单中存在，
  --        且此人名下(作为投保人、被保人、受益人)所有有效保单的已交保费累计达到阀值，即被抓取。
  --     ? 高风险国籍清单如下附件（具体可参照高风险国家映射关系表）：
  --     3) 此条规则阀值为10万，实现为可配置形式
  --         累计已交保费=除HK001以外的收入交易的总金额
  --   抽取结果：
  --     1) 抽取国籍命中高风险国家或地区名单的投保人作为投保人或被保人或受益人名下所有有效保单；
  --     2）报送数据格式同现有可疑交易格式
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/19
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

  -- 获取国籍属于高风险国家或地区的投保人名下所有有效保单信息
  INSERT INTO LXAssistA(
    Customerno,
    Policyno,
    Numargs1,
    Args1)
      SELECT DISTINCT
          r.clientno,
          r.contno,
          (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
          'A0200'
      FROM
          cr_trans t,
          cr_rel r
      WHERE
          t.contno = r.contno
      AND EXISTS(
          SELECT 1
          FROM
              cr_client c,
              lxriskinfo rinfo
          WHERE
              c.clientno = r.clientno
          AND c.nationality = rinfo.code
          AND rinfo.recordtype = '02'-- 风险类型：2-国家或地区
          AND rinfo.risklevel = '3'  -- 风险等级：3-高风险
          )
      AND EXISTS(
          SELECT 1
          FROM
              cr_trans tmp_t,
              cr_rel tmp_r
          WHERE
              tmp_r.clientno = r.clientno
          AND tmp_r.contno = tmp_t.contno
          AND tmp_r.custype = 'O'       -- 客户类型：O-投保人
          AND tmp_t.transtype = 'AA001' -- 交易类型为投保
          AND tmp_t.conttype = '1'      -- 保单类型：1-个单
          AND TRUNC(tmp_t.transdate) = TRUNC(i_baseLine)
          )
      AND r.custype IN ('O', 'I', 'B')  -- 客户类型：O-投保人/I-被保人/B-受益人
      AND isValidCont(t.contno) = 'yes'-- 有效保单
      AND t.conttype = '1'  ;            -- 保单类型：1-个单

  DECLARE
    CURSOR baseInfo_sor IS
      SELECT
          r.clientno,
          t.transno,
          t.contno
      FROM
          cr_trans t,
          cr_rel r
      WHERE
          t.contno  = r.contno
      AND r.clientno IN(
          SELECT
              a.customerno
          FROM
              LXAssistA a
          WHERE
              a.args1 = 'A0200'
          GROUP BY
              a.customerno
          HAVING
              SUM(a.numargs1) >= v_threshold_money
          )
      AND r.custype IN ('O','B','I')-- 客户类型：O-投保人/I-被保人/B-受益人
      AND t.transtype = 'AA001'     -- 交易类型：投保
      AND t.conttype= '1'           -- 保单类型：1-个单
      ORDER BY
          r.clientno  ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易编号
    c_contno cr_trans.contno%type;      -- 保单号

  BEGIN
    OPEN baseInfo_sor;
    LOOP
      FETCH baseInfo_sor INTO c_clientno,c_transno,c_contno;
      EXIT WHEN baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0200', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    END LOOP;
    CLOSE baseInfo_sor;
  END;
  -- 删除辅助表的辅助数据
  DELETE FROM LXAssistA WHERE Args1 = 'A0200';
END proc_aml_A0200;
/

prompt
prompt Creating procedure PROC_AML_A0300
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE proc_aml_A0300 ( i_baseLine IN DATE, i_oprater IN VARCHAR2 )
IS
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money NUMBER := getparavalue ('SA0300', 'M1') ; -- 阀值 累计已交保费

BEGIN
	-- =============================================
	-- Rule:
  --   若投保人职业存在在高风险职业代码表（分值>=10)中，
  --   且此人名下所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --   1) 抽取保单维度
  --   ? 保单渠道：OLAS、IGM；
  --   ? 抽取前一天生效的保单；
  --   2) 若抽取保单的投保人的职业存在于高风险职业代码表中，
  --      且此人名下所有有效保单的已交保费累计达到阀值，即被抓取
  --   ? 高风险职业代码表（附件中标黄部分）
  --   3) 此条规则阀值为10万，实现为可配置形式
  --   抽取结果：
  --   1) 抽取职业代码命中高风险职业名单的投保人作为投保人或被保人或受益人名下所有有效保单；
  --   2）报送数据格式同现有可疑交易格式
	--
	-- parameter in: i_baseLine 交易日期
	--         i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/19
	-- Changes log:
	--     Author     Date     Description
	-- =============================================

  -- 获取国籍属于高风险国家或地区的投保人名下所有有效保单信息
  delete from LXAssistA;
  
  INSERT INTO LXAssistA(
    Customerno,
    Policyno,
    Numargs1,
    Args1)
      SELECT DISTINCT
          r.clientno,
          r.contno,
          (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
          'A0300'
      FROM
          cr_trans t,
          cr_rel r
      WHERE
          t.contno = r.contno
      AND EXISTS(
          SELECT 1
          FROM
              cr_client c,
              lxriskinfo rinfo
          WHERE
              c.clientno = r.clientno
          AND c.occupation = rinfo.code
          AND rinfo.recordtype = '03'-- 风险类型：3-职业
          AND rinfo.risklevel = '3'  -- 风险等级：3-高风险
          )
      AND EXISTS(
          SELECT 1
          FROM
              cr_trans tmp_t,
              cr_rel tmp_r
          WHERE
              tmp_r.clientno = r.clientno
          AND tmp_r.contno = tmp_t.contno
          AND tmp_r.custype = 'O'       -- 客户类型：O-投保人
          AND tmp_t.transtype = 'AA001' -- 交易类型为投保
          AND tmp_t.conttype = '1'      -- 保单类型：1-个单
          AND TRUNC(tmp_t.transdate) = TRUNC(i_baseLine)
          )
      AND r.custype IN ('O', 'I', 'B')  -- 客户类型：O-投保人/I-被保人/B-受益人
      AND isValidCont(t.contno) = 'yes'-- 有效保单
      AND t.conttype = '1';              -- 保单类型：1-个单

  DECLARE
    CURSOR baseInfo_sor IS
      SELECT
          r.clientno,
          t.transno,
          t.contno
      FROM
          cr_trans t,
          cr_rel r
      WHERE
          t.contno  = r.contno
      AND r.clientno IN(
          SELECT
              a.customerno
          FROM
              LXAssistA a
          WHERE
              a.args1 = 'A0300'
          GROUP BY
              a.customerno
          HAVING
              SUM(a.numargs1) >= v_threshold_money
          )
      AND r.custype IN ('O','B','I')-- 客户类型：O-投保人/I-被保人/B-受益人
      AND t.transtype = 'AA001'     -- 交易类型：投保
      AND t.conttype= '1'           -- 保单类型：1-个单
      ORDER BY
          r.clientno ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易编号
    c_contno cr_trans.contno%type;      -- 保单号

  BEGIN
    OPEN baseInfo_sor;
    LOOP
      FETCH baseInfo_sor INTO c_clientno,c_transno,c_contno;
      EXIT WHEN baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0300', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    END LOOP;
    CLOSE baseInfo_sor;
	END ;
  -- 删除辅助表的辅助数据
	DELETE FROM LXAssistA WHERE Args1 = 'A0300' ;
END proc_aml_A0300 ;
/

prompt
prompt Creating procedure PROC_AML_A0400
prompt =================================
prompt
create or replace procedure proc_aml_A0400(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0400', 'M1'); -- 阀值 当期保费

begin
-- =============================================
  -- Rule:
  -- 新契约回访不成功件，且不成功原因为联系不上客户，且当期保费大于等于阀值，即被系统抓取，生成可疑交易；
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     抽取前一天回访不成功（回访完成时间为前一天），且回访原因为联系不上客户的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为20万，实现为可配置形式
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/18
  -- Changes log:
  -- =============================================
  declare
    cursor baseInfo_sor is
      select
          r.clientno,
          t.transno,
          t.contno
      from
          cr_trans t,
          cr_rel r,
          cr_policy p
      where
          t.contno = r.contno
      and p.contno = r.contno
      and r.custype = 'O'               -- 客户类型：O-投保人
      and t.visitreason = '1'           -- 回访不成功
      and p.sumprem >= v_threshold_money-- 当期保费大于阀值
      and t.transtype = 'AA002'         -- 交易类型为投保
      and t.conttype = '1'              -- 保单类型：1-个单
      and trunc(t.transdate) = trunc(i_baseLine)
      order by
          r.clientno ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易号
    c_contno cr_trans.contno%type;      -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0400', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0400;
/

prompt
prompt Creating procedure PROC_AML_A0500
prompt =================================
prompt
create or replace procedure proc_aml_A0500(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;     -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --      投保人年收入少于趸交保费的三分之一或期交保费的二分之一即被系统抓取，生成可疑交易；
  --      抽取条件：
  --        1) 抽取保单维度
  --           保单渠道：OLAS、IGM；
  --          抽取前一天生效的保单
  --        2）投保人年收入与此新单的保费进行比较，如果是期缴保费则需转成ANP后进行比较
  --           当期保费：（AA001,AA002,AA003)
  --           趸交：全额趸交保费
  --           期缴：AA001转化成ANP，AA002和AA003按趸交计算
  --        4) 此条规则无需配置阀值
  --      抽取结果：
  --        1) 报送数据格式同现有可疑交易格式投保人年收入
  --      注：投保人年收入
  --        1）与单张新保单比较
  --        2）如期缴/趸交都有，则分别计算，任一符合条件则被抓取
  --
  -- parameter in: i_baseLine 交易日期
  --                              i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/19
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

  declare
    cursor baseInfo_sor is
      select
          c.clientno,
          t.transno,
          t.contno
      from
          cr_trans t,
          cr_rel r,
          cr_client c
      where
          t.contno = r.contno
      and r.clientno = c.clientno
      and exists(
          select 1
          from
              cr_policy p
          where
              t.contno = p.contno
          and c.income <
              (case p.paymethod
               when '01' then 1/2 * (p.sumprem - p.prem + p.yearprem)--期交保费的二分之一
               when '02' then 1/3 * p.sumprem --趸交保费的三分之一
               end)
          )
      and c.income!=0                  --年收入不为0
      and r.custype = 'O'              -- 客户类型：O-投保人
      and t.transtype = 'AA001'        -- 交易类型投保
      and isValidCont(t.contno)='yes'  -- 有效保单
      and t.conttype = '1'             -- 保单类型：1-个单
      and trunc(t.transdate) = trunc(i_baseLine)
      order by
          c.clientno ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;   -- 客户号
    c_transno cr_trans.transno%type;      -- 交易号
    c_contno cr_trans.contno%type;        -- 保单号

  begin
    open baseInfo_sor;
    loop
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0500', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0500;
/

prompt
prompt Creating procedure PROC_AML_A0601
prompt =================================
prompt
create or replace procedure proc_aml_A0601(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0601', 'M2'); -- 阀值 保费
  v_income number := getparavalue('SA0601', 'M1');          -- 阀值 年收入

begin
  -- =============================================
  -- Rule: 投保人职业为公务员、军人、学生，且年收入大于30万，
  --       且当期保费大于等于阀值，即被系统抓取，生成可疑交易；
  --       抽取条件：
  --         1) 抽取保单维度
  --           保单渠道：OLAS、IGM；
  --           抽取前一天生效的保单
  --         2) 投保人职位为公务员、军人、学生，且年收入大于30万，且当期保费大于等于阀值，即被系统抓取
  --            当期保费：（AA001,AA002,AA003)
  --            趸交：全额趸交保费
  --            期缴：AA001转化成ANP，AA002和AA003按趸交计算
  --         3) 此条规则阀值为30万，实现为可配置形式
  --       抽取结果：
  --         1) 报送数据格式同现有可疑交易格式
  --         2）如期缴/趸交都有，则分别计算，任一符合条件则被抓取
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/19
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

  declare
    cursor baseInfo_sor is
      select
          c.clientno,
          t.transno,
          t.contno
      from
          cr_trans t,
          cr_rel r,
          cr_client c
      where
          t.contno = r.contno
      and r.clientno = c.clientno  -- 投保人收入大于阀值
      and exists(
          select 1
          from
              cr_policy p
          where
              t.contno = p.contno
          and (case p.paymethod
               when '01' then p.sumprem - p.prem + p.yearprem   --期缴
               when '02' then p.sumprem                         --趸交
               end
              ) >= v_threshold_money)
          and c.occupation in (select code from ldcode where codetype = 'occ_SA0601')
          and c.income > to_number(v_income)
      and r.custype = 'O'               -- 客户类型：O-投保人
      and t.transtype = 'AA001'         -- 交易类型为投保
      and isValidCont(t.contno) = 'yes' -- 有效保单
      and t.conttype = '1'              -- 保单类型：01-个单
      and trunc(t.transdate) = trunc(i_baseLine)
       order by
          c.clientno ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;   -- 客户号
    c_transno cr_trans.transno%type;      -- 交易号
    c_contno cr_trans.contno%type;        -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0601', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0601;
/

prompt
prompt Creating procedure PROC_AML_A0602
prompt =================================
prompt
create or replace procedure proc_aml_A0602(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;	 -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_money number := getparavalue('SA0602', 'M2'); -- 阀值 当期保费
  v_income number:=getparavalue('SA0602', 'M1'); -- 阀值 年收入

begin
  -- =============================================
  -- Rule: 投保人职业为家庭主妇、离退休人员，且年收入大于100万，
  --       且当期保费大于等于阀值，即被系统抓取，生成可疑交易；
  --       抽取条件：
  --         1) 抽取保单维度
  --            保单渠道：OLAS、IGM；
  --            抽取前一天生效的保单
  --         2) 投保人职业为家庭主妇、离退休人员，且年收入大于100万，且当期保费大于等于阀值，即被系统抓取
  --            当期保费：（AA001+AA003+AA004)
  --            趸交：全额趸交保费
  --            期缴：转化成ANP，AA002和AA003按趸交计算
  --         3) 此条规则阀值为100万，实现为可配置形式
  --       抽取结果：
  --         1) 报送数据格式同现有可疑交易格式
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/20
  -- Changes log:
  --     Author     Date     Description
  -- =============================================
  declare
    cursor baseInfo_sor is
      select
            c.clientno,
            t.transno,
            t.contno
        from
            cr_trans t,
            cr_rel r,
            cr_client c
        where
            t.contno = r.contno
        and r.clientno = c.clientno  -- 投保人收入大于阀值
        and exists(
            select 1
            from
                cr_policy p
            where
                t.contno = p.contno
            and (case p.paymethod
                 when '01' then p.sumprem - p.prem + p.yearprem   --期缴
                 when '02' then p.sumprem                         --趸交
                 end
                ) >= v_threshold_money
            )
        and c.occupation in (select code from ldcode where codetype = 'occ_SA0602')
        and c.income > to_number(v_income)
        and r.custype = 'O'               -- 客户类型：O-投保人
        and t.transtype = 'AA001'         -- 交易类型为投保
        and isValidCont(t.contno) = 'yes' -- 有效保单
        and t.conttype = '1'              -- 保单类型：01-个单
        and trunc(t.transdate) = trunc(i_baseLine)
        order by c.clientno ,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno cr_trans.transno%type;    -- 交易号
    c_contno cr_trans.contno%type;      -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0602', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0602;
/

prompt
prompt Creating procedure PROC_AML_A0700
prompt =================================
prompt
create or replace procedure proc_aml_A0700(i_baseLine in date, i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type; -- 交易编号
  v_phone cr_rel.policyphone%type;    -- 联系电话
  v_iscount varchar2(2);       -- 是否计入明细评估指标

  v_threshold_money number := getparavalue('SA0700', 'M1'); -- 阀值 当期保费

begin
  -- =============================================
  -- Rule:
  --      投保人的联系电话与系统中其他客户联系电话相同，
  --      且当期保费大于等于阀值，即被系统抓取，生成可疑交易；
  --      抽取条件：
  --        1) 抽取保单维度
  --          保单渠道：OLAS、IGM；
  --          抽取前一天生效的保单
  --        2) 将抽取保单的投保人手机号与系统中其他用户手机号进行匹配，
  --           将手机号相同的客户抽取出来，与投保人进行比对，
  --           i）对于有alpha ID的客户，则比对alpha ID
  --           ii)对于无alpha ID的客户（受益人），则比对name+ID，
  --              若比对不一致，则认为是投保人的手机号与系统中其他客户手机号相同。
  --        3) 报送数据格式同现有可疑交易格式
  --        4) 此条规则阀值为20万，实现为可配置形式
  --        5) 当期保费：（AA001+AA003+AA004)
  --           趸交：全额趸交保费
  --           期缴：转化成ANP，AA002和AA003按趸交计算
  --
  -- parameter in: i_baseLine 交易日期
  --                i_oprater  操作人
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/03/20
  -- Changes log:
  --     Author     Date        Description
  --     xuexc    2019/05/10       初版
  --     zhouqk   2019/05/27    添加名字作为查询条件
  -- =============================================

  -- 获取系统中当日投保，且当期保费大于等于阀值的投保人和保单信息
  insert into LXAssistA(
    Args1, -- 规则标识
    Customerno,
    Policyno,
    Args2, -- 联系电话
    Args3, -- 证件号码
    Args4) -- 客户名
      select distinct
          'A0700_1',
          r.clientno,
          t.contno,
          r.policyphone,
          r.usecardid,
          (select c.name from cr_client c where c.clientno = r.clientno) as clientname
      from
          cr_trans t,
          cr_rel r,
          cr_policy p
      where
          t.contno = r.contno
      and t.contno = p.contno
      and (case when r.custype = 'O' and nvl(r.policyphone, 'n') = 'n' then 'n' else 'y' end ) = 'y'
      and r.custype = 'O'
      and p.sumprem >= v_threshold_money -- 当期保费大于阀值
      and t.transtype = 'AA001'          -- 交易类型：新契约
      and trunc(t.transdate) = trunc(i_baseLine);

  -- 获取系统中其他投保人/被保人/受益人信息（联系电话与当日投保的投保人联系电话相同）
  insert into LXAssistA(
    Args1, -- 规则标识
    Customerno,
    Policyno,
    Args2, -- 联系电话
    Args3, -- 证件号码
    Args4) -- 客户名
      select distinct
          'A0700_2',
          temp.clientno,
          temp.contno,
          temp.telephone,
          temp.cardid,
          temp.name
      from
      (
          select    -- 系统中其他投保人/被保人信息（联系电话与今日发生投保的投保人联系电话相同）
              r.clientno,
              r.contno,
              r.policyphone as telephone,
              r.usecardid as cardid,
              (select c.name from cr_client c where r.clientno = c.clientno) as name
          from
              cr_rel r
          where not exists(  -- 过滤手机号码相同且客户号相同的客户信息
              select 1
              from
                  LXAssistA a
              where
                  r.clientno = a.customerno
              and a.args1 = 'A0700_1'
              )
          and exists(     -- 手机号码相同的客户信息
              select 1
              from
                  LXAssistA a
              where
                  r.policyphone = a.args2
              and a.args1 = 'A0700_1'
              )
          and r.custype in ('O', 'I') -- 客户类型：O-投保人/I-被保人
          union
          select    -- 系统中受益人信息（联系电话与投保人联系电话相同）
              c.clientno,
              r.contno,
              c.telephone,
              c.cardid,
              c.name
          from
              cr_rel r,
              cr_client c
          where
              r.clientno = c.clientno
          and not exists(  -- 过滤手机号码相同且证件号码和名字相同的客户信息
              select 1
              from
                  LXAssistA a
              where
                  c.name = a.args4
              and c.cardid = a.args3
              and a.args1 = 'A0700_1'
              )
          and exists(
              select 1
              from
                  LXAssistA a
              where
                  c.telephone = a.args2
              and a.args1 = 'A0700_1'
              )
          and r.custype in ('B') -- 客户类型：B-受益人
        ) temp;

  -- 获取系统中当日投保的符合规则的投保人和保单信息
  insert into LXAssistA(
    Args1, -- 规则标识
    Customerno,
    Policyno,
    Args2, -- 联系电话
    Args3, -- 证件号码
    Args4) -- 客户名
      select distinct
          'A0700_3',
          la.customerno,
          la.policyno,
          la.args2,
          la.args3,
          la.args4
      from
          LXAssistA la
      where
          la.args2 in (
          select
              a.args2
          from
              LXAssistA a
          where
              a.args1 in ('A0700_1','A0700_2')
          group by
              a.args2
          having
              count(distinct a.customerno) >= 2)
      and la.args1 in ('A0700_1','A0700_2');

  -- 投保人的联系电话与系统中其他客户联系电话相同，且当期保费大于等于阀值的所有保单信息
  declare
    cursor baseInfo_sor is
      select
          r.clientno,
          t.transno,
          t.contno,
          r.policyphone
      from
          cr_trans t,
          cr_rel r
      where
          t.contno = r.contno
      and exists(
          select 1
          from
              LXAssistA a
          where
              r.clientno = a.customerno
          and r.policyphone=a.args2
          and r.contno = a.policyno
          and a.args1 = 'A0700_3'
          )
      and r.custype in ('O', 'I', 'B') -- 客户类型：O-投保人/I-被保人/B-受益人
      and t.transtype = 'AA001' -- 交易类型：新契约
      and t.conttype = '1'      -- 保单类型：1-个单
      and r.policyphone is not null
      order by
          r.policyphone,
          t.transdate desc,
          t.contno desc;

    -- 定义游标变量
    c_clientno cr_rel.clientno%type; -- 客户号
    c_phone cr_rel.policyphone%type; -- 联系方式
    c_transno cr_trans.transno%type; -- 交易编号
    c_contno cr_trans.contno%type;   -- 保单号

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno, c_phone;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

		    if v_phone is null or c_phone <> v_phone then

            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)
			      v_phone := c_phone; -- 更新可疑主体的联系方式

			      -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
			      PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0700', i_baseLine);
			      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
			      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

            -- 插入交易主体联系方式-临时表 Lxaddress_Temp
  			    PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

            v_iscount := 'n'; -- 标记以下处理中不再对可疑交易明细信息插入
        else
            v_iscount := 'y'; -- 标记以下处理中需要对可疑交易明细信息插入
  			end if;

        -- 根据是否计入明细评估指标判断明细表的插入
		    if v_iscount = 'y' then
			      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
			      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
  			end if;

  			-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
  			PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

  			-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
  			PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

  			-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
  			PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

    end loop;
    close baseInfo_sor;
  end;

  -- 删除辅助表A0700的辅助数据
  delete from LXAssistA where Args1 like 'A0700%';
end proc_aml_A0700;
/

prompt
prompt Creating procedure PROC_AML_A0801
prompt =================================
prompt
create or replace procedure proc_aml_A0801(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --   保单投保人为超高风险客户
  --   1) 抽取保单维度
  --   ? 保单渠道：OLAS、IGM；
  --   ? 抽取日前一日生效的保单；
  --   2) 投保人为超高风险客户
  --   3) 此条规则无需配置阀值
  --   4）报送数据格式同现有可疑交易格式
  --
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/20
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

  declare
    cursor baseInfo_sor is
      select
          r.clientno,
          t.transno,
          t.contno
      from
          cr_client c,
          cr_rel r,
          cr_trans t
      where c.clientno=r.clientno
      and t.contno = r.contno
      and exists(
          select 1
          from
              lxriskinfo rinfo
          where
            (r.clientno = rinfo.code or c.ORIGINALCLIENTNO = rinfo.code)
          and rinfo.recordtype='01'       -- 风险类型：01-自然人
          and rinfo.risklevel='4'         -- 风险等级：4-超高风险等级
          )
      and r.custype = 'O'              -- 客户类型：O-投保人
      and t.transtype = 'AA001'         -- 交易类型为投保
      and isValidCont(t.contno)='yes'  -- 有效保单
      and t.conttype = '1'             -- 保单类型：1-个单
      and trunc(t.transdate) = trunc(i_baseLine)
      order by
          r.clientno,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;  -- 客户号
    c_transno cr_trans.transno%type;     -- 交易号
    c_contno cr_trans.contno%type;       -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0801', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0801;
/

prompt
prompt Creating procedure PROC_AML_A0802
prompt =================================
prompt
create or replace procedure proc_aml_A0802(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --   保单投保人为超高风险客户，且在保单有效期间内存在资金进出
  --   1) 抽取保单维度
  --   ? 保单渠道：OLAS、IGM；
  --      超高风险的客户；
  --   2）抽取日前一日有资金进出的保单；
  --   3) 报送数据格式同现有可疑交易格式
  --   4) 此条规则无需配置阀值
  --   1）资金进入类型：所有收入交易（AB001,AB002,FC***,WT001,WT005,NP370,HK001中的收费部分），
  --      以实际匹配日期、结案日为基准
  --   2）资金流出类型：
  --      退保、提取账户价值、贷款、FPDF、Coupon、maturity、dividend、减少保额的保费退费、
  --      major理赔、minor理赔。以上传payment日期为基准
  --   报送结果：当天发生的所有进出，涉及多笔，放入明细中
  --
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/20
  -- Changes log:
  --     Author     Date     Description
  --     baishuai  2020/1/6  排除正常给付和缴纳保费
  -- =============================================

  declare
    cursor baseInfo_sor is
      select
          r.clientno,
          t.transno,
          t.contno
      from
          cr_trans t,
          cr_rel r,
          cr_policy p
      where
          t.contno = r.contno
      and t.contno = p.contno
      and exists(
          select 1
          from
              lxriskinfo rinfo,
              cr_client c
          where (c.clientno = rinfo.code or c.originalclientno=rinfo.code)
          and c.clientno = r.clientno
          and rinfo.recordtype='01'       -- 风险类型：01-自然人
          and rinfo.risklevel='4'         -- 风险等级：4-超高风险等级
          )
      and exists(
          select 1
          from
              cr_trans tmp_t
          where
              t.contno = tmp_t.contno
          and t.payway in ('01','02')
          and t.transtype  in(select code from ldcode where codetype='aml_monitor_A0802')
          and trunc(t.transdate) = trunc(i_baseLine)
          )
      and t.payway in ('01','02')      -- 存在支付方式为收和付
      and r.custype = 'O'              -- 客户类型：O-投保人
      and t.conttype = '1'             -- 保单类型：1-个单
      and t.transtype  in(select code from ldcode where codetype='aml_monitor_A0802')
      and trunc(t.transdate) >= trunc(p.effectivedate) -- 交易日期>=保单生效日
      and trunc(t.transdate) < trunc(p.expiredate)     -- 交易日期<保单终止日
      order by
          r.clientno,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;  -- 客户号
    c_transno cr_trans.transno%type;     -- 交易号
    c_contno cr_trans.contno%type;       -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0802', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_A0802;
/

prompt
prompt Creating procedure PROC_AML_A0900
prompt =================================
prompt
create or replace procedure proc_aml_A0900(i_baseLine in date,i_oprater in varchar2)
is
  v_dealNo lxistrademain.dealno%type;	-- 交易编号(业务表)
  v_clientno cr_client.clientno%type;	-- 客户号

	v_threshold_money number := getparavalue('SA0900', 'M1'); -- 阀值 有效期间内资金进出合计

begin
  -- =============================================
	-- Rule:
  --      保单投保人为高风险客户，且在保单有效期间内存在资金进出，
  --      且金额大于等于阀值（资金进出以绝对值形式合并累加统计，并与阀值进行比对）
  --      1) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        抽取日前一日有资金进出的保单（同上）；
  --      2) 报送数据格式同现有可疑交易格式
  --      3) 此条规则阀值为20万，实现为可配置形式
  --      注：资金进出以绝对值形式合并累加统计，并与阀值进行比对
  --
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/20
	-- Changes log:
	--     Author     Date     Description
  --      baishuai  2019/1/19   累计金额排除正常给付和缴纳保费
	-- =============================================

  -- 获取保单投保人为高风险客户，且在保单有效期间内存在资金进出，且金额大于等于阀值的客户和保单
  insert into LXAssistA(
    Args1,     -- 规则标识
    Customerno,-- 客户名
    Policyno)  -- 保单号
      select distinct
          'A0900' as args1,
          r.clientno,
          t.contno
      from
          cr_trans t,
          cr_rel r,
          cr_policy p
      where
          t.contno = r.contno
      and t.contno = p.contno
      and exists(
          select 1
          from
              LXRISKINFO rinfo,
              cr_client c
          where (c.clientno = rinfo.code or c.originalclientno=rinfo.code)
          and c.clientno = r.clientno
          and rinfo.risklevel = '3'   -- 风险等级：3-高风险
          and rinfo.recordtype = '01' -- 01-自然人
          )
      and exists (
          select 1
          from
              cr_trans tmp_t
          where
              t.contno = tmp_t.contno
          and tmp_t.payway in ('01','02') -- 存在资金进出
          and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype = 'O'         -- 客户类型：O-投保人
      and t.payway in ('01','02') -- 存在资金进出
      and t.transtype in (select code from ldcode where codetype='aml_monitor_A0900')
      and trunc(t.transdate) >= trunc(p.effectivedate) -- 交易日期>=保单生效日
      and trunc(t.transdate) < trunc(p.expiredate)     -- 交易日期<保单终止日
      and t.conttype = '1' -- 保单类型：1-个单
			group by
          r.clientno,
          t.contno
			having
					sum(abs(t.payamt)) >= v_threshold_money;

  -- 获取保单有效期间内存在资金进出的交易信息
  declare
    cursor baseInfo_sor is
			select
          r.clientno,
          t.transno,
          t.contno
      from
				  cr_trans t,
          cr_rel r,
          cr_policy p
      where
          t.contno = r.contno
      and t.contno = p.contno
			and exists(
					select 1
					from
							LXAssistA a
					where
              r.clientno = a.customerno
          and t.contno = a.policyno
          and a.args1 = 'A0900'
          )
      and r.custype = 'O'         -- 客户类型：O-投保人
      and t.payway in ('01','02') -- 存在资金进出
      and t.transtype  in (select code from ldcode where codetype='aml_monitor_A0900')
      and t.conttype = '1'        -- 保单类型：1-个单
      and trunc(t.transdate) >= trunc(p.effectivedate) -- 交易日期>=保单生效日
      and trunc(t.transdate) < trunc(p.expiredate)     -- 交易日期<保单终止日
      order by
          r.clientno,t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;	-- 客户号
    c_transno cr_trans.transno%type;		-- 客户身份证件号码
    c_contno cr_trans.contno%type;			-- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表
        if v_clientno is null or c_clientno <> v_clientno then

            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SA0900', i_baseLine);

            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为1）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp（明细评估指标为空）
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;
  end;
  -- 删除辅助表A0900的辅助数据
  delete from LXAssistA where Args1 like 'A0900%';
end proc_aml_A0900;
/

prompt
prompt Creating procedure PROC_AML_B0101
prompt =================================
prompt
create or replace procedure proc_aml_B0101(i_baseLine in date, i_oprater in varchar2)
is
    v_dealNo lxistrademain.dealno%type; -- 交易编号(业务表)
    v_clientno cr_client.clientno%type; -- 客户号
    i_ddd cr_client%rowtype;

    v_threshold_money number := getparavalue('SB0101', 'M1'); -- 阀值 累计保费金额
    v_threshold_month number := getparavalue('SB0101', 'D1'); -- 阀值 自然月
    v_threshold_count number := getparavalue('SB0101', 'N1'); -- 阀值 变更次数

begin
  -- ============================================
  -- Rule:
  --     投保人3个月内变更超过三次（不包括三次）联系电话，且该投保人作为投保人的
  --     所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --     1) 变更联系电话仅统计通信地址的变更次数，且同一投保人变更多个保单联系电话
  --        变更后联系电话相同的，将变更次数进行合并记为一次变更；
  --     2) 累计已交保费逻辑同7.1.1
  --     3) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        前一天变更联系电话生效保全的保单；
  --     4) 报送数据格式同现有可疑交易格式
  --     5) 此条规则阀值为20万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

  -- 找出当天发生变更联系电话的投保人下三个月内（前后）所有变更联系电话的记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
    args1,
    args2,
    args3,
    args4,
    args5)
      select
          r.clientno,
          t.transno,
          t.contno,
          (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
          t.requestdate,
          t.transdate,
          t.transtype,
          td.remark,
          td.ext1,
          td.ext2,
          'B0101_1'
      from
          cr_trans t,
          cr_rel r,
          cr_transdetail td
      where
          t.contno = r.contno
      and t.contno = td.contno
      and t.transno = td.transno
      and exists(
          select 1
          from
              cr_trans tmp_t,
              cr_rel tmp_r,
              cr_transdetail tmp_td
          where
              r.clientno = tmp_r.clientno
          and trunc(t.requestdate) > trunc(add_months(tmp_t.requestdate,v_threshold_month*(-1)))  --申请日3个月前
          and trunc(t.requestdate) < trunc(add_months(tmp_t.requestdate,v_threshold_month))   --申请日3个月后
          and tmp_t.contno = tmp_r.contno
          and tmp_t.contno = tmp_td.contno
          and tmp_t.transno = tmp_td.transno
          and tmp_r.custype='O'          -- 投保人
          and tmp_td.remark in ('mobile','ownerMobile')
          and tmp_t.transtype in ('COMM','BG001','BG002')
          and tmp_t.conttype='1'         -- 个单
          and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and td.remark in('mobile','ownerMobile')
      and t.transtype in ('COMM','BG001','BG002')
      and t.conttype='1'
      and isValidCont(t.contno)='yes';

  --同一投保人3个月内（前后）3次（不包括3）以上变更联系电话，累计已交保费大于阀值
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TimeArgs1,
    TranMoney,
    args5,
    args4)
      select
          CustomerNo,
          TranId,
          PolicyNo,
          TimeArgs1,
          TranMoney,
          'B0101_2',
          args4
      from
          LXAssistA a
      where exists(
            select 1
            from
                LXAssistA tmp
            where
                tmp.customerno = a.customerno
            group by
                tmp.customerno
            having  -- 保证变更为同一联系电话不算入次数
                count(distinct tmp.args4) > v_threshold_count
            )
      and (       -- 计算名下所有有效保单累计已交保费总额
           select
               sum(nvl(p.sumprem,0))
           from
               cr_rel r,
               cr_policy p
           where
               r.clientno = a.customerno
           and r.contno = p.contno
           and isValidCont(r.contno) = 'yes'
           and r.custype='O') >= v_threshold_money
      order by
          a.customerno,
          a.timeargs1;

  -- 找出以每一条记录往后推三个月满足次数的交易作为记录头
  declare
    cursor baseInfo_sor is
      select
          CustomerNo,
          PolicyNo,
          TimeArgs1
      from
          LXAssistA a
      where exists (          -- 以每条为基础计算3个月内是否有三次
            select 1
            from
                LXAssistA tmp
            where
                tmp.customerno = a.customerno
            and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
            and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
            and tmp.args5 = 'B0101_2'
            group by
                tmp.customerno
            having
                count(distinct tmp.args4) > v_threshold_count
            )
        and a.args5 = 'B0101_2'
        order by
            a.CustomerNo,
            a.TimeArgs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_contno cr_trans.contno%type;      -- 保单号
    c_requestdate cr_trans.requestdate%type;

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_contno, c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 以记录头查找三个月内的记录
      declare
        cursor baseInfo_sor_date is
          select *
          from
              lxassista
          where
              trunc(TimeArgs1) >= trunc(c_requestdate)
          and trunc(TimeArgs1) < trunc(add_months(c_requestdate, v_threshold_month))
          and args5 = 'B0101_2'
          and customerno = c_clientno;

        c_row baseInfo_sor_date%rowtype;

      begin
      for c_row in baseInfo_sor_date loop
        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
        if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0101', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号
        else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');
        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
      end loop;
      end;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('B0101_1','B0101_2');
end proc_aml_B0101;
/

prompt
prompt Creating procedure PROC_AML_B0102
prompt =================================
prompt
create or replace procedure proc_aml_B0102(i_baseLine in date, i_oprater in varchar2) is

    v_threshold_money number := getparavalue('SB0102', 'M1'); -- 阀值 累计保费金额
		v_threshold_month number := getparavalue('SB0102', 'D1'); -- 阀值 自然月
		v_threshold_count number := getparavalue('SB0102', 'N1'); -- 阀值 变更次数
		v_dealNo lxistrademain.dealno%type;												-- 交易编号(业务表)
		v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --     投保人3个月内变更超过三次（不包括三次）通信地址，且该投保人作为投保人的
  --     所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --     1) 变更通信地址仅统计通信地址的变更次数，且同一投保人变更多个保单通信地址
  --        变更后通信地址相同的，将变更次数进行合并记为一次变更；
  --     2) 累计已交保费逻辑同7.1.1
  --     3) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        前一天变更通信地址生效保全的保单；
  --     4) 报送数据格式同现有可疑交易格式
  --     5) 此条规则阀值为20万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- ============================================

  -- 找出当天发生变更通信地址的投保人下三个月内（前后）所有变更通信地址的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
    args1,
    args3,
    args4,
		args5)
      select distinct
        r.clientno,
        t.transno,
        t.contno,
        (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
        t.requestdate,
        t.transdate,
        t.transtype,
        (select distinct tr.ext1 from cr_transdetail tr where tr.remark in ('regiona','commAddress1') and tr.transno=t.transno)
        ||(select distinct tr.ext1 from cr_transdetail tr where tr.remark in ('regionb','commAddress2') and tr.transno=t.transno)
        ||(select distinct tr.ext1 from cr_transdetail tr where tr.remark in ('regionc','commAddress3') and tr.transno=t.transno)
        ||(select distinct tr.ext1 from cr_transdetail tr where tr.remark in ('regiond','commAddress4') and tr.transno=t.transno)
        as ext1,
        (select distinct tr.ext2 from cr_transdetail tr where tr.remark in ('regiona','commAddress1') and tr.transno=t.transno)
        ||(select distinct tr.ext2 from cr_transdetail tr where tr.remark in ('regionb','commAddress2') and tr.transno=t.transno)
        ||(select distinct tr.ext2 from cr_transdetail tr where tr.remark in ('regionc','commAddress3') and tr.transno=t.transno)
        ||(select distinct tr.ext2 from cr_transdetail tr where tr.remark in ('regiond','commAddress4') and tr.transno=t.transno)
        as ext2,
				'B0102_1'
      from
        cr_trans t,cr_rel r,cr_transdetail td
      where
          t.contno=r.contno
      and t.contno=td.contno
      and t.transno=td.transno
      and exists(
          select 1
          from
              cr_trans tmp_t, cr_rel tmp_r, cr_transdetail tmp_td
          where
              r.clientno = tmp_r.clientno
          and tmp_t.contno = tmp_r.contno
          and tmp_t.contno=tmp_td.contno
          and tmp_t.transno=tmp_td.transno
          and tmp_r.custype='O'          -- 投保人
          and tmp_t.conttype='1'         -- 个单
          and trunc(t.requestdate) > trunc(add_months(tmp_t.requestdate,v_threshold_month*(-1)))  --申请日3个月前
          and trunc(t.requestdate) < trunc(add_months(tmp_t.requestdate,v_threshold_month))   --申请日3个月后
          and tmp_td.remark in('regiona','regionb','regionc','regiond','commAddress1','commAddress2','commAddress3','commAddress4')
          and tmp_t.transtype in ('COMM','BG001','BG002')-- 如果是变更投保人，则不关心remark备注信息
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and td.remark in('regiona','regionb','regionc','regiond','commAddress1','commAddress2','commAddress3','commAddress4')
      and t.transtype in('COMM','BG001','BG002')     -- 变更通信地址
      and isValidCont(t.contno)='yes'
      and t.conttype='1';


    --同一投保人3个月内（前后）3次（不包括3）以上变更通信地址，累计已交保费大于阀值
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
		TimeArgs1,
		TranMoney,
    args5,
		args4)
      select
        CustomerNo,
        TranId,
        PolicyNo,
				TimeArgs1,
				TranMoney,
				'B0102_2',
				args4
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having  -- 保证变更为同一联系电话不算入次数  by zhouqk
            count(distinct tmp.args4)>v_threshold_count
        )
    and (			-- 计算名下所有有效保单累计已交保费总额
				select
					sum(nvl(policy.sumprem,0))
					from cr_rel rel,cr_policy policy
					where rel.contno=policy.contno
					and rel.clientno = a.customerno
					and isValidCont(rel.contno)='yes'
					and rel.custype='O')
				>=v_threshold_money

      order by a.customerno, a.timeargs1;

-- 找出以每一条记录往后推三个月满足次数的交易作为记录头
declare
       cursor baseInfo_sor is
          select
            CustomerNo,
            PolicyNo,
						TimeArgs1
          from
            LXAssistA a
          where
						exists (					-- 以每条为基础计算3个月内是否有三次
							select 1
							from LXAssistA tmp
							where tmp.customerno = a.customerno
							and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
							and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
							and tmp.args5 = 'B0102_2'
							group by
								tmp.customerno
							having
								count(distinct tmp.args4)>v_threshold_count
						)
						and a.args5 = 'B0102_2'
						order by CustomerNo,TimeArgs1 desc;


    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头查找三个月内的记录
			declare
				cursor baseInfo_sor_date is
					select *
					from lxassista
					where trunc(TimeArgs1) >= trunc(c_requestdate)
					and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
					and args5 = 'B0102_2' and customerno = c_clientno;

			c_row baseInfo_sor_date%rowtype;

		begin
		for c_row in baseInfo_sor_date loop
			-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
      v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

      -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
      PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0102', i_baseLine);
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
      v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

      end if;

			-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
			PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

			-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
			PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

			-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
			PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

			-- 插入交易主体联系方式-临时表 Lxaddress_Temp
			PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
		end loop;

		end;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('B0102_1','B0102_2');
end proc_aml_B0102;
/

prompt
prompt Creating procedure PROC_AML_B0103
prompt =================================
prompt
create or replace procedure proc_aml_B0103(i_baseLine in date, i_oprater in varchar2) is

    v_threshold_money number := getparavalue('SB0103', 'M1'); -- 阀值 累计保费金额
		v_threshold_month number := getparavalue('SB0103', 'D1'); -- 阀值 自然月
		v_threshold_count number := getparavalue('SB0103', 'N1'); -- 阀值 变更次数
		v_dealNo lxistrademain.dealno%type;												-- 交易编号(业务表)
		v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --     投保人3个月内变更超过三次（不包括三次）职业、签名、受益人或代理人，且该投保人作为投保人的
  --     所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --     1) 变更通信地址仅统计职业、签名、受益人或代理人的变更次数，且同一投保人变更多个保单职业、签名、受益人或代理人，
  --        变更后职业、签名、受益人或代理人相同的，将变更次数进行合并记为一次变更
  --     2) 累计已交保费逻辑同7.1.1
  --     3) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        前一天变更职业、签名、受益人或代理人生效保全的保单
  --     4) 报送数据格式同现有可疑交易格式
  --     5) 此条规则阀值为20万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天发生变更投保人下三个月内（前后）所有变更记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
    args1,
    args2,
    args3,
    args4,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
        t.requestdate,
        t.transdate,
        t.transtype,
        td.remark,
        td.ext1,
        td.ext2,
        'B0103_1'
      from
        cr_trans t,cr_rel r,cr_transdetail td
      where
          t.contno=r.contno
      and t.contno=td.contno
      and t.transno=td.transno
      and exists(
          select 1
          from
              cr_trans tmp_t, cr_rel tmp_r, cr_transdetail tmp_td
          where
              tmp_r.clientno = r.clientno
          and tmp_t.contno = tmp_r.contno
          and tmp_t.contno = tmp_td.contno
          and tmp_t.transno = tmp_td.transno
          and trunc(t.requestdate) > trunc(add_months(tmp_t.requestdate,v_threshold_month*(-1)))  --申请日3个月前
          and trunc(t.requestdate) < trunc(add_months(tmp_t.requestdate,v_threshold_month))   --申请日3个月后
          and tmp_r.custype = 'O'
          and tmp_t.conttype='1'
          and (tmp_td.remark in ('OwnOccupation','editSignStyle','变更代理人') or tmp_td.remark like 'operateType%')
          and tmp_t.transtype in ('COMM','BG002','BG005','FC0OO','FC0OD','FC0II','AGT01')
          and trunc(tmp_t.transdate)=trunc(i_baseline)
          )
      and r.custype = 'O'
      and (td.remark in ('OwnOccupation','editSignStyle','变更代理人') or td.remark like 'operateType%')
      and t.transtype in ('COMM','BG002','BG005','FC0OO','FC0OD','FC0II','AGT01')
      and isValidCont(t.contno) = 'yes'
      and t.conttype = '1';

	 insert into LXAssistA(
			CustomerNo,
			TranId,
			PolicyNo,
			TimeArgs1,
			TranMoney,
			args2,
			args5,
			args4)
      select
        CustomerNo,
        TranId,
        PolicyNo,
				TimeArgs1,
				TranMoney,
				args2,
				'B0103_2',
				args4
      from
        LXAssistA a
      where (									-- 变更为同一职业受益人代理人只算一次，变更签名不去重
        nvl((
          select count(distinct tmp.args4)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and (tmp.args2 in('OwnOccupation','AGT01'))
          group by
            tmp.customerno
				),0)
				+
				nvl((
          select count(1)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and tmp.args2='editSignStyle'
          group by
            tmp.customerno
				),0)
        +
        nvl((
          select count(distinct tranid)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and tmp.args2 like 'operateType%'
          group by
            tmp.customerno
				),0)>=v_threshold_count
     )
    and (				-- 计算名下所有有效保单累计已交保费总额
				select
					sum(nvl(policy.sumprem,0))
					from cr_rel rel,cr_policy policy
					where rel.contno=policy.contno
					and rel.clientno = a.customerno
					and isValidCont(rel.contno)='yes'
					and rel.custype='O')
				>=v_threshold_money
			order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推三个月满足次数的交易作为记录头
	declare
       cursor baseInfo_sor is
          select
            CustomerNo,
            PolicyNo,
						TimeArgs1
          from
            LXAssistA a
          where
						(									-- 变更为同一职业受益人代理人只算一次，变更签名不去重
							nvl((
								select count(distinct tmp.args4)
								from
									LXAssistA tmp
								where tmp.customerno = a.customerno
								and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
								and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
								and (tmp.args2 in('OwnOccupation','变更代理人')or tmp.args2 like 'operateType%')
								and tmp.args5='B0103_2'
								group by
									tmp.customerno
							),0)
							+
							nvl((
								select count(tmp.args4)
								from
									LXAssistA tmp
								where tmp.customerno = a.customerno
								and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
								and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
								and tmp.args2 ='editSignStyle'
								and tmp.args5='B0103_2'
								group by
									tmp.customerno
							),0)
              +
              nvl((
                  select count(distinct tranid)
                  from
                    LXAssistA tmp
                  where tmp.customerno = a.customerno
					        and tmp.args2 like 'operateType%'
                  group by
                    tmp.customerno
				      ),0)>=v_threshold_count
					 )
				and a.args5 = 'B0103_2'
				order by CustomerNo,TimeArgs1 desc;

     -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头查找三个月内的记录
			declare
				cursor baseInfo_sor_date is
					select *
					from lxassista
					where trunc(TimeArgs1) >= trunc(c_requestdate)
					and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
					and args5 = 'B0103_2' and customerno = c_clientno;

			c_row baseInfo_sor_date%rowtype;

		begin
		for c_row in baseInfo_sor_date loop
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
      v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

      -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
      PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0103', i_baseLine);
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
      v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

      end if;

			-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
			PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

			-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
			PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

			-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
			PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

			-- 插入交易主体联系方式-临时表 Lxaddress_Temp
			PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
		end loop;

		end;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('B0103_1','B0103_2');
end proc_aml_B0103;
/

prompt
prompt Creating procedure PROC_AML_B0200
prompt =================================
prompt
create or replace procedure proc_aml_B0200(i_baseLine in date,i_oprater in VARCHAR2) is
	v_dealNo lxistrademain.dealno%type;                       -- 交易编号
	v_clientno cr_client.clientno%type;  -- 客户号
begin
	-- =============================================
	-- Rule: 抽取前一天生效的保单；
	-- 未提供FATCA和CRS申明文件的保单
  -- 抽取日前一日生效的保单
	-- 报送数据格式同现有可疑交易格式
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/22
	-- Changes log:
	--     Author     Date          Description
  --     zhouqk  2019/04/21         初版
	-- =============================================
	declare
			cursor baseInfo_sor is
				select
					c.clientno,
					t.transno,
					t.contno
					from
						cr_trans t, cr_rel r, cr_client c
					where
								t.contno = r.contno
						and r.clientno = c.clientno
						and c.IsFATCAandCRS='0'									  -- 无FATCA和CRS申明文件
						and t.transtype = 'AA001'									-- 交易类型为投保
            and isValidCont(t.contno)='yes'
						and r.custype = 'O'             	 		    -- 客户类型：O-投保人
            and t.conttype = '1'            			    -- 保单类型：1-个单
						and trunc(t.transdate) = trunc(i_baseLine)
					order by c.clientno,t.transdate desc;    	                  --交易时间

    -- 定义游标变量
		c_clientno cr_client.clientno%type;        -- 客户号
    c_transno cr_trans.transno%type;    			 -- 客户身份证件号码
    c_contno cr_trans.contno%type;     				 -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;  -- 游标循环出口

				-- 同一可疑主体的情况下
				if v_clientno is null or c_clientno <> v_clientno then

					v_dealNo :=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号

					-- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
					PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0200', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
   				PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

					v_clientno := c_clientno; -- 更新可疑主体的客户号
        else

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
				  PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

				end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
				PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
				PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
				PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
				PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;
  end;
  

end proc_aml_B0200;
/

prompt
prompt Creating procedure PROC_AML_B0300
prompt =================================
prompt
create or replace procedure proc_aml_B0300(i_baseLine in date,i_oprater in VARCHAR2) is
	v_dealNo lxistrademain.dealno%type;                       -- 交易编号
	v_clientno cr_client.clientno%type;  -- 客户号
begin
	-- =============================================
	-- 抽取保单生效日+90天落在本月16号到下个月15号之间；并且
  -- 投保人在线身份验证未通过( [身份校验表](表结构见FR002)中[验证状态]=’N’)
  -- 抽取日前一日生效的保单
	-- 报送数据格式同现有可疑交易格式
	-- parameter in: i_baseLine 交易日期
	-- parameter in: i_dataBatchNo 批次号
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/05/27
	-- Changes log:
	--     Author       Date       Description
  --     zhouqk    2019/05/27       初版
	-- =============================================
  insert into LXAssistA(
    PolicyNo,
		args5)
      select
        p.contno,
				'B0300'
      from
        cr_policy p
      where
          (p.effectivedate+90) >= to_date(concat(to_char(i_baseline,'yyyy-mm'),'-16'),'yyyy-mm-dd')                --保单生效日+90天大于本月16号
			and (p.effectivedate+90) <= to_date(concat(to_char(add_months(i_baseline,1),'yyyy-mm'),'-15'),'yyyy-mm-dd')  --保单生效日+90天小于下一个月15号
      and p.conttype = '1';		-- 保单类型：1-个单

  declare
			cursor baseInfo_sor is
				select
						c.clientno,
						t.transno,
						t.contno
					from
						cr_trans t, cr_rel r, cr_client c
					where
								t.contno = r.contno
						and r.clientno = c.clientno
						and c.IDverifystatus='0'   								-- 身份验证未通过
            and r.custype = 'O'             	 		    -- 客户类型：O-投保人
            and t.transtype='AA001'                   -- 取投保的交易做交易明细
            and exists(
                select 1
                from lxassista lx
                where lx.policyno=r.contno
            )
					  order by c.clientno,t.transdate desc;

					-- 定义游标变量
					c_clientno cr_client.clientno%type;        -- 客户号
					c_transno cr_trans.transno%type;    			 -- 客户身份证件号码
					c_contno cr_trans.contno%type;     				 -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;  -- 游标循环出口

				-- 同一可疑主体的情况下
        if v_clientno is null or c_clientno <> v_clientno then

          v_dealNo :=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0300', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
				PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
				PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
				PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
				PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;
  end;
  delete from LXAssistA where args5 in ('B0300');
end proc_aml_B0300;
/

prompt
prompt Creating procedure PROC_AML_B0400
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_B0400(i_baseLine in date,i_oprater in VARCHAR2) is
	v_dealNo lxistrademain.dealno%type;                       -- 交易编号
  v_threshold_year number := getparavalue('SB0101', 'D1'); 	-- 年限阀值
	v_threshold_count number := getparavalue('SB0101', 'N1'); -- 保单张数阀值
  v_clientno cr_rel.clientno%type;  -- 客户号
begin
	-- =============================================
	-- Rule: 抽取前一天生效的保单；
	-- 一年内，有3张以上保单投保人变更为同一人，且原投保人不同
	-- 报送数据格式同现有可疑交易格式
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater 	操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/22
	-- Changes log:
	--     Author     Date     Description
	-- =============================================

  -- 获取前一天发生投保人变更的客户，其名下一年内发生投保人变更的所有有效保单。
  insert into LXAssistA(
    Customerno,
    Policyno,
    Args2,
    Args3,
    Args4,
    Args1)
      select
          r.clientno,
          t.contno,
          (select c.cardid from cr_client c where c.clientno = r.clientno) as cardid,
          (select distinct td.ext1 from cr_transdetail td where td.contno = t.contno and td.transno = t.transno and td.remark='OwnCertNumber') as ext1,
          (select distinct td.ext2 from cr_transdetail td where td.contno = t.contno and td.transno = t.transno and td.remark='OwnCertNumber') as ext2,
          'B0400'
      from
          cr_rel r,
          cr_trans t
      where
          r.contno = t.contno
      and exists (
          select 1
          from
              cr_trans tmp_t,
              cr_rel tmp_r
          where
              r.clientno = tmp_r.clientno
          and tmp_r.contno = tmp_t.contno
          and isValidCont(tmp_r.contno) = 'yes' -- 有效保单
          and tmp_t.transtype = 'BG003'         -- 交易类型为投保人变更
          and tmp_t.conttype = '1'              -- 保单类型：1-个单
          and trunc(tmp_t.transdate) = trunc(i_baseLine)
          )
      and r.custype = 'O'               -- 客户类型：O-投保人
      and isValidCont(r.contno) = 'yes' -- 有效保单
      and t.transtype = 'BG003'         -- 交易类型为“投保人变更”
      and t.conttype = '1'              -- 保单类型：1-个单
      and trunc(t.transdate) > trunc(add_months(i_baseLine, -12 * v_threshold_year))
      and trunc(t.transdate) <= trunc(i_baseLine);

  declare
	  cursor baseInfo is
      select
				  r.clientno,
				  t.transno,
				  t.contno
			from
				  cr_trans t,
          cr_rel r
			where
					t.contno = r.contno
		  and exists (
					select 1
					from
              LXAssistA a
					where
              r.clientno = a.customerno
          and a.args2 = a.args4
          group by
              a.customerno
          having
              count(distinct a.args3) >= v_threshold_count
				  )
			and r.custype = 'O'							-- 客户类型：O-投保人
			and isValidCont(t.contno)='yes' -- 有效保单
			and t.transtype='BG003'					-- 交易类型为投保人变更
			and t.conttype = '1'						-- 保单类型：1-个单
      and trunc(t.transdate) > trunc(add_months(i_baseLine, -12 * v_threshold_year))
      and trunc(t.transdate) <= trunc(i_baseLine)
			order by
          r.clientno,
          t.transdate desc;

	  -- 定义游标变量
	  c_clientno cr_rel.clientno%type;	-- 客户号
	  c_transno cr_trans.transno%type;	-- 交易编号
	  c_contno cr_trans.contno%type;		-- 保单号


begin
  open baseInfo;
	loop
	  fetch baseInfo into c_clientno, c_transno, c_contno;
	  exit when baseInfo%notfound;

			-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
			if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

				-- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
				PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0400', i_baseLine);
				-- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
				PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

				v_clientno := c_clientno; -- 更新可疑主体的客户号
			else
				-- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
				PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');
			end if;

				-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
				PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

				-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
				PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

				-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
				PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

				-- 插入交易主体联系方式-临时表 Lxaddress_Temp
				PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

  end loop;
  close baseInfo;

end;
-- 删除辅助表的辅助数据
  delete from LXAssistA;
end proc_aml_B0400;
/

prompt
prompt Creating procedure PROC_AML_C0101
prompt =================================
prompt
create or replace procedure proc_aml_C0101(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0101', 'M1');    -- 阀值 累计保费金额
  v_threshold_day number := getparavalue('SC0101', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0101', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;  -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 同一投保人7日内3次（包括3）以上万能追加投资、新单保费、定投达到30万，即被系统抓取，生成可疑交易
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     操作万能追加投资（T）、新单保费（I、7）、定投（Q）的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为30万，实现为可配置形式
  -- parameter in:  i_baseLine 交易日期
  --                i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- ============================================

  -- 找出当天触发万能追加投资、新单保费、定投的投保人七天内（前后）所有触发的记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
        t.transtype,
				'C0101_1'
      from
        cr_trans t,cr_rel r
      where
          t.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate) > trunc(tmp_t.requestdate) - v_threshold_day  --申请日7天前
          and trunc(t.requestdate) < trunc(tmp_t.requestdate) + v_threshold_day  --申请日7天后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='01'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (t.transtype like 'FC%' and t.payway='01'));


    --同一投保人七天内（前后）3次（包括3）触发，累计已交保费大于阀值
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
        CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0101_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%' ) tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money --阀值计算包含AA003\AA004
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推七天满足次数的交易作为记录头
	declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  (args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%')
								and args5='C0101_2') tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(a.TimeArgs1)+v_threshold_day
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
		and a.args5='C0101_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;


begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后七天是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
				 and args5 = 'C0101_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头七天内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
							and args5 = 'C0101_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					  -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0101', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;


            -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
            PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

            -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
            PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

            -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
            PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

            -- 插入交易主体联系方式-临时表 Lxaddress_Temp
            PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0101_1','C0101_2');
end proc_aml_C0101;
/

prompt
prompt Creating procedure PROC_AML_C0102
prompt =================================
prompt
create or replace procedure proc_aml_C0102(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0102', 'M1');    -- 阀值 累计保费金额
  v_threshold_day number := getparavalue('SC0102', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0102', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;               -- 交易编号(业务表)
	v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 同一投保人30日内5次（包括5）以上万能追加投资、新单保费、定投达到50万，即被系统抓取，生成可疑交易
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     操作万能追加投资（T）、新单保费（I、7）、定投（Q）的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为50万，实现为可配置形式
  -- parameter in:  i_baseLine 交易日期
  --                i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- ============================================

-- 找出当天触发万能追加投资、新单保费、定投的投保人三十天内（前后）所有触发的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0102_1'
      from
        cr_trans t,cr_rel r
      where
          t.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate) > trunc(tmp_t.requestdate) - v_threshold_day  --申请日30天前
          and trunc(t.requestdate) < trunc(tmp_t.requestdate) + v_threshold_day  --申请日30天后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='01'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (t.transtype like 'FC%' and t.payway='01'));

--同一投保人三十天内（前后）5次（包括5）触发，累计已交保费大于阀值
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0102_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%' ) tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money --阀值计算包含AA003\AA004
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推七天满足次数的交易作为记录头
declare
    --定义游标：
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  (args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%')
								and args5='C0102_2') tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(a.TimeArgs1)+v_threshold_day
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
		and a.args5='C0102_2'
    order by a.customerno, a.timeargs1 desc;

   -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推三十天是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
				 and args5 = 'C0102_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头三十天内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
							and args5 = 'C0102_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					  -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
              v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

              -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
              PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0102', i_baseLine);
              -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
              PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
              v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
              -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
              PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0102_1','C0102_2');
end proc_aml_C0102;
/

prompt
prompt Creating procedure PROC_AML_C0103
prompt =================================
prompt
create or replace procedure proc_aml_C0103(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0103', 'M1');    -- 阀值 累计保费金额
  v_threshold_month number := getparavalue('SC0103', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0103', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;               -- 交易编号(业务表)
	v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 同一投保人6个月内8次（包括8）以上万能追加投资、新单保费、定投达到100万，即被系统抓取，生成可疑交易
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     操作万能追加投资（T）、新单保费（I、7）、定投（Q）的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为100万，实现为可配置形式
  -- parameter in:  i_baseLine 交易日期
  --                i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- ============================================

-- 找出当天触发万能追加投资、新单保费、定投的投保人六个月内（前后）所有触发的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0103_1'
      from
        cr_trans t,cr_rel r
      where
          t.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate)>trunc(add_months(tmp_t.requestdate,-abs(v_threshold_month))) --申请日6个月前
          and trunc(t.requestdate)<trunc(add_months(tmp_t.requestdate,abs(v_threshold_month)))        --申请日6个月后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='01'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('AA001','AA003','AA004','WT001','AB002','WT005')) or (t.transtype like 'FC%' and t.payway='01'));

    --同一投保人6个月内8次（包括8）以上万能追加投资、新单保费、定投达到100万
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0103_2'
      from
        LXAssistA a
      where
       exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%' ) tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money --阀值计算包含AA003\AA004
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推六个月满足次数的交易作为记录头
declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            (select
                distinct
                  CustomerNo,TimeArgs1,PolicyNo
               from
                  LXAssistA
               where
                  (args1 in ('AA001','WT001','AB002','WT005')
                 or args1 like 'FC%')
								and args5='C0103_2') tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count --次数计算不包含AA003\AA004
        )
		and a.args5='C0103_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推六个月是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
				 and args5 = 'C0103_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头六个月内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
							and args5 = 'C0103_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0103', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0103_1','C0103_2');
end proc_aml_C0103;
/

prompt
prompt Creating procedure PROC_AML_C0201
prompt =================================
prompt
create or replace procedure proc_aml_C0201(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0201', 'M1');    -- 阀值 累计保费金额
  v_threshold_day number := getparavalue('SC0201', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0201', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;               -- 交易编号(业务表)
     	v_clientno cr_client.clientno%type;  -- 客户号

begin
 -- =============================================
  -- Rule:
  -- 同一投保人在7日内退保3次（包括3）以上主合同达到50万（只取应付金额，类型是退保所有相关费用）即被系统抓取，生成可疑交易；
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM；
  --    抽取前一天操作退保保全项的保单；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为50万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  -- 							 i_oprater 操作人
  -- parameter out: none
  -- Author: xiesf
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- ============================================

-- 找出当天触发退保的投保人七天内（前后）所有触发的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0201_1'
      from
        cr_trans t,cr_rel r
      where
          t.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate) > trunc(tmp_t.requestdate) - v_threshold_day  --申请日7天前
          and trunc(t.requestdate) < trunc(tmp_t.requestdate) + v_threshold_day  --申请日7天后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('TB001','LQ002')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='02'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('TB001','LQ002')) or (t.transtype like 'FC%' and t.payway='02'));


    --定义游标：同一投保人7日内3次（包括3）以上退保达到50万
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0201_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推七天满足次数的交易作为记录头
declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(a.TimeArgs1)+v_threshold_day
						and tmp.args5='C0201_2'
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count
        )
		and a.args5='C0201_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推七天是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
				 and args5 = 'C0201_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头七天内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
							and args5 = 'C0201_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0201', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0201_1','C0201_2');
end proc_aml_C0201;
/

prompt
prompt Creating procedure PROC_AML_C0202
prompt =================================
prompt
create or replace procedure proc_aml_C0202(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0202', 'M1');    -- 阀值 累计保费金额
  v_threshold_day number := getparavalue('SC0202', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0202', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;               -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 同一投保人在30日内退保5次（包括5）以上达到100万。（只取应付金额，类型是退保所有相关费用）即被系统抓取，生成可疑交易；
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM
  --    抽取前一天操作退保保全项的保单；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为100万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  -- 							 i_oprater 操作人
  -- parameter out: none
  -- Author: xiesf
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天触发万能追加投资、新单保费、定投的投保人三十天内（前后）所有触发的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0202_1'
      from
        cr_trans t,cr_rel r,cr_policy p
      where
          t.contno=r.contno
      and p.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate) > trunc(tmp_t.requestdate) - v_threshold_day  --申请日30天前
          and trunc(t.requestdate) < trunc(tmp_t.requestdate) + v_threshold_day  --申请日30天后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('TB001','LQ002')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='02'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('TB001','LQ002')) or (t.transtype like 'FC%' and t.payway='02'));


    --定义游标：同一投保人30日内5次（包括5）以上退保达到100万
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0202_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推七天满足次数的交易作为记录头
declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(a.TimeArgs1)+v_threshold_day
						and tmp.args5='C0202_2'
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count
        )
		and a.args5='C0202_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;



begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推三十天是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
				 and args5 = 'C0202_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头三十天内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(c_requestdate)+v_threshold_day
							and args5 = 'C0202_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0202', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0202_1','C0202_2');
end proc_aml_C0202;
/

prompt
prompt Creating procedure PROC_AML_C0203
prompt =================================
prompt
create or replace procedure proc_aml_C0203(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0203', 'M1');    -- 阀值 累计保费金额
  v_threshold_year number := getparavalue('SC0203', 'D1');     -- 阀值 自然年
  v_threshold_count number := getparavalue('SC0203', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;                          -- 交易编号(业务表)
	v_clientno cr_client.clientno%type;                          -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 同一投保人在一年内退保8次（包括8）以上达到300万。（只取应付金额，类型是退保所有相关费用）即被系统抓取，生成可疑交易；
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM
  --    抽取前一天操作退保保全项的保单；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为300万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  -- 							 i_oprater 操作人
  -- parameter out: none
  -- Author: xiesf
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天触发万能追加投资、新单保费、定投的投保人一年内（前后）所有触发的记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0203_1'
      from
        cr_trans t,cr_rel r,cr_policy p
      where
          t.contno=r.contno
      and p.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate) > trunc(add_months(tmp_t.requestdate,v_threshold_year*(-12)))  --申请日一年前
          and trunc(t.requestdate) < trunc(add_months(tmp_t.requestdate,v_threshold_year*(12)))   --申请日一年后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and ((tmp_t.transtype in ('TB001','LQ002')) or (tmp_t.transtype like 'FC%' and tmp_t.payway='02'))
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and ((t.transtype in ('TB001','LQ002')) or (t.transtype like 'FC%' and t.payway='02'));


    --定义游标：同一投保人一年日内8次（包括8）以上退保达到300万
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0203_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推七天满足次数的交易作为记录头
declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_year*(12)))
						and tmp.args5='C0203_2'
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count
        )
		and a.args5='C0203_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推一年是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_year*(12)))
				 and args5 = 'C0203_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头一年内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_year*(12)))
							and args5 = 'C0203_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0203', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0203_1','C0203_2');
end proc_aml_C0203;
/

prompt
prompt Creating procedure PROC_AML_C0300
prompt =================================
prompt
create or replace procedure proc_aml_C0300(i_baseLine in date,i_oprater in varchar2) is

  v_threshold_money number := getparavalue('SC0300', 'M1');    -- 阀值 累计保费金额
  v_threshold_month number := getparavalue('SC0300', 'D1');      -- 阀值 自然日
  v_threshold_count number := getparavalue('SC0300', 'N1');    -- 阀值 追加保费次数
  v_dealNo lxistrademain.dealno%type;               -- 交易编号(业务表)
	v_clientno cr_client.clientno%type;  -- 客户号

begin
-- =============================================
  -- Rule:
  -- 同一投保人3个月内，贷款次数3次（包括3）以上，且贷款金额之和200万及以上
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM
  --     抽取前一天操作贷款保全项的保单；
  --  4) 报送数据格式同现有可疑交易格式
  --  5) 此条规则阀值为200万，实现为可配置形式
  -- parameter in:	i_baseLine 交易日期
  -- 								i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天触发贷款的投保人三个月内（前后）所有触发的记录
insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
		args1,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        t.payamt,
        t.requestdate,
        t.transdate,
				t.transtype,
				'C0300_1'
      from
        cr_trans t,cr_rel r
      where
          t.contno=r.contno
      and exists(
          select 1
          from
              cr_trans tmp_t,cr_rel tmp_r
          where
              tmp_t.contno=tmp_r.contno
          and tmp_r.clientno=r.clientno
          and trunc(t.requestdate)>trunc(add_months(tmp_t.requestdate,-abs(v_threshold_month))) --申请日3个月前
          and trunc(t.requestdate)<trunc(add_months(tmp_t.requestdate,abs(v_threshold_month)))  --申请日3个月后
          and tmp_t.conttype='1'         -- 个单
          and tmp_r.custype='O'
          and tmp_t.transtype = 'JK001'
					and trunc(tmp_t.transdate) = trunc(i_baseline)
          )
      and r.custype='O'  --同一投保人
      and t.conttype='1'
      and (t.transtype = 'JK001');

--同一投保人三个月内（前后）3次（包括3）触发，累计已交保费大于阀值
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
		args1,
		args5)
      select
				CustomerNo,
        TranId,
        PolicyNo,
				TranMoney,
				TimeArgs1,
				args1,
				'C0300_2'
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
          group by
            tmp.customerno
          having
              count(tmp.customerno) >= v_threshold_count
        )
    and exists(
      select 1
      from
        LXAssistA tmp
      where
        tmp.customerno = a.customerno
      group by
        tmp.customerno
      having sum(tmp.tranmoney) >= v_threshold_money
    )
      order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推三个月满足次数的交易作为记录头
	declare
    cursor baseInfo_sor is
      select
         CustomerNo,
         TranId,
         TimeArgs1
      from
        LXAssistA a
      where
        exists(
          select 1
          from
            LXAssistA tmp
          where
            tmp.customerno = a.customerno
						and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
						and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
						and tmp.args5='C0300_2'
          group by
            tmp.customerno
          having
            count(tmp.customerno) >= v_threshold_count
        )
		and a.args5='C0300_2'
    order by a.customerno, a.timeargs1 desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;
		v_money cr_trans.payamt%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头每条记录查看往后推三个月是否满足阈值
			select sum(temp.tranmoney) into v_money from
				(select tranmoney from lxassista where
				 trunc(TimeArgs1) >= trunc(c_requestdate)
				 and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
				 and args5 = 'C0300_2' and customerno = c_clientno) temp;

			-- 将满足阈值的记录头三个月内的记录为最终记录
			if v_money>=v_threshold_money THEN
					declare
						cursor baseInfo_sor_date is
							select *
							from lxassista
							where trunc(TimeArgs1) >= trunc(c_requestdate)
							and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
							and args5 = 'C0300_2' and customerno = c_clientno;

					c_row baseInfo_sor_date%rowtype;

				begin
				for c_row in baseInfo_sor_date loop
					-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
            if v_clientno is null or c_clientno <> v_clientno then
            v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

            -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
            PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_row.customerno,c_row.policyno, i_oprater, 'SC0300', i_baseLine);
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
            v_clientno := c_clientno; -- 更新可疑主体的客户号

            else
            -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
            PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

            end if;

					-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
					PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

					-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
					PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

					-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
					PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

					-- 插入交易主体联系方式-临时表 Lxaddress_Temp
					PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
				end loop;

				end;
			end if;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('C0300_1','C0300_2');
end proc_aml_C0300;
/

prompt
prompt Creating procedure PROC_AML_C0400
prompt =================================
prompt
create or replace procedure proc_aml_C0400(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC0400', 'M1'); -- 阀值 累计保费金额
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号
  v_clientno cr_client.clientno%type;                       -- 客户号

begin
  -- =============================================
  -- Rule:
  -- 投保人、被保人以外的第三方账户交纳保费（含追加保费），且金额达到阀值
  --  1)抽取保单维度
  --    保单渠道：OLAS、IGM
  --    抽取前一天投保人、被保人以外的第三方账户交纳保费的保单；（Autopay中的交费记录）
  --  2)此条规则阀值为20万，实现为可配置形式
  -- 报送数据格式同现有可疑交易格式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/18
  -- Changes log:
  --     Author     Date        Description
  --     周庆凯   2019/05/20    计算阀值修改为通过保单号进行分组统计
  --     baishuai 2019/1/6      上调阀值为 金额大于或等于20万;去除已授权、已签约的第三方

  -- =============================================
 declare
         cursor baseInfo_sor is
               select
                r.clientno,
                t.transno,
                t.contno
              from
                cr_trans t, cr_rel r
              where
                    t.contno = r.contno
               -- 计算保单下交易总额与阈值比较
               and exists (
                      select 1
                      from
                        cr_trans temp_t,cr_rel temp_r
                      where r.contno = temp_t.contno
                        and r.clientno=temp_r.clientno
                        and temp_r.contno=temp_t.contno
                        and temp_r.custype='O'
                        and isthirdaccount(temp_t.contno,temp_t.accname,'1')='yes'--第三方
                        and temp_t.payway='01'
                        and temp_t.conttype='1'
                        and temp_t.transtype not in( 'HK001','PAY01','PAY02','PAY03','PAY04') -- 还贷(HK001)以外的所有资金进入交易
                      group by temp_t.contno
                        having sum(abs(temp_t.payamt))>=v_threshold_money
                  )
                and exists(
                    select
                          1
                      from cr_trans tr, cr_rel re
                       where
                            tr.contno = re.contno
                        and r.contno=re.contno
                        and isthirdaccount(tr.contno,tr.accname,'1')='yes'
                        and re.custype='O'
                        and tr.conttype='1'
                        and tr.payway='01'
                        and tr.transtype not in( 'HK001','PAY01','PAY02','PAY03','PAY04')    -- 还贷(HK001)以外的所有资金进入交易
                        and trunc(tr.transdate) = trunc(i_baseLine)
                )
                and isthirdaccount(t.contno,t.accname,'1')='yes'          -- 使用第三方账户
                and t.transtype not in( 'HK001','PAY01','PAY02','PAY03')
                and t.payway='01'
                and r.custype = 'O'                -- 客户类型：O-投保人
                and t.conttype = '1'              -- 保单类型：1-个单
                order by r.clientno,t.transdate desc;




        -- 定义游标变量
        c_clientno cr_client.clientno%type;   -- 客户号
        c_transno cr_trans.transno%type;      -- 交易编号
        c_contno cr_trans.contno%type;        -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 同一可疑主体的情况下
        if v_clientno is null or c_clientno <> v_clientno then

          v_dealNo :=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0400', i_baseLine);

          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');

          v_clientno := c_clientno; -- 更新可疑主体的客户号
        else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

        end if;

        -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
        PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

        -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
        PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

        -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
        PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

        -- 插入交易主体联系方式-临时表 Lxaddress_Temp
        PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;
  end;
end proc_aml_C0400;
/

prompt
prompt Creating procedure PROC_AML_C0500
prompt =================================
prompt
create or replace procedure proc_aml_C0500(i_baseLine in date,i_oprater in VARCHAR2) is

	v_threshold_money number := getparavalue('SC0500', 'M1'); -- 阀值 累计保费金额
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号
	v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
	-- Rule:
	-- 保全产生的给付金额支付至投保人以外的第三方账户，且金额达到阀值
	--  1)抽取保单维度
	--		保单渠道：OLAS、IGM
	--		抽取前一天操作给付类保全项的保单；
  --  2)此条规则阀值为5万，实现为可配置形式
	-- 报送数据格式同现有可疑交易格式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
  --     Author     Date        Description
  --     baishuai   2019/01/06      上调阀值为 金额大于或等于20万;去除已授权、已签约的第三方

	-- =============================================
 declare

        cursor baseInfo_sor is
               select
                r.clientno,
                t.transno,
                t.contno
              from
                cr_trans t, cr_rel r
              where
                    t.contno = r.contno
               -- 计算保单下交易总额与阈值比较
               and exists (
                      select 1
                      from
                        cr_trans temp_t, cr_rel temp_r
                      where r.contno = temp_r.contno
                        and r.clientno = temp_r.clientno
                        and temp_r.contno = temp_t.contno
                        and temp_r.custype='O'
                        and isthirdaccount(temp_t.contno,temp_t.accname,'2')='yes'
                        and temp_t.payway='02'
                        and temp_t.conttype='1'
                        and temp_t.transtype not in('CLM01','CLM02','CLM03','PAY01','PAY02','PAY03','PAY04')-- 理赔以外的所有资金流出交易
                      group by temp_r.clientno,temp_r.contno
                        having sum(abs(temp_t.payamt))>=v_threshold_money
                  )
                and exists(
                    select
                          1
                      from cr_trans tr, cr_rel re
                       where
                            tr.contno = r.contno
                        and r.clientno=re.clientno
                        and r.contno=re.contno
                        and isthirdaccount(tr.contno,tr.accname,'2')='yes'
                        and re.custype='O'
                        and tr.payway='02'
                        and tr.conttype='1'
                        and tr.transtype not in('CLM01','CLM02','CLM03','PAY01','PAY02','PAY03','PAY04')   -- 理赔以外的所有资金流出交易
                        and trunc(tr.transdate) = trunc(i_baseLine)
                )
                and isthirdaccount(t.contno,t.accname,'2')='yes'				-- 使用第三方账户
                and t.transtype not in('CLM01','CLM02','CLM03','PAY01','PAY02','PAY03','PAY04') -- 理赔以外的所有资金流出交易
                and t.payway='02'
                and r.custype = 'O'                -- 客户类型：O-投保人
                and t.conttype = '1'              -- 保单类型：1-个单
                order by r.clientno,t.transdate desc;

        -- 定义游标变量
        c_clientno cr_client.clientno%type;   -- 客户号
        c_transno cr_trans.transno%type;      -- 客户身份证件号码
        c_contno cr_trans.contno%type;        -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0500', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;
  end;
end proc_aml_C0500;
/

prompt
prompt Creating procedure PROC_AML_C0600
prompt =================================
prompt
create or replace procedure proc_aml_C0600(i_baseLine in date,i_oprater in VARCHAR2) is

  v_dealNo lxistrademain.dealno%type;                       -- 交易编号
  v_threshold_money number := getparavalue('SC0600', 'M1'); -- 阀值

begin
-- =============================================
	-- Rule:
	-- 领款信息上payment后，进行的领款人变更；
	--  1)抽取保单维度
	--		保单渠道：OLAS、IGM
	--		抽取前一天在payment上操作“领款人变更”的保单；
  --  2)此条规则无需配置阀值
	-- 报送数据格式同现有可疑交易格式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
  --     Author     Date        Description
	-- =============================================
 declare
    cursor baseInfo_sor is
       select
        r.clientno,
        t.transno,
        t.contno
      from cr_trans t, cr_rel r
      where
						t.contno = r.contno
        and exists(
          select
               1
            from
              cr_rel re,cr_trans tr
            where
              r.clientno=re.clientno
            and
              r.contno=re.contno
            and
              re.contno=tr.contno
            and
              re.custype='O'
            and
              tr.payway='02'
            and
              tr.transtype in ('PAY01','PAY02','PAY03','PAY04')
            and
              tr.IsThirdAccount= '1'					       -- 使用第三方账户
            and
              tr.conttype='1'
            group by
              re.clientno,tr.contno
            having
              sum(abs(tr.payamt))>=v_threshold_money -- 阀值待补充
          )
        and exists(
            select
                  1
              from cr_trans tr, cr_rel re
               where
                    tr.contno = r.contno
                and r.clientno=re.clientno
                and tr.transtype in( 'PAY01','PAY02','PAY03','PAY04')
                and tr.IsThirdAccount= '1'					-- 使用第三方账户
                and tr.conttype='1'
                and re.custype='O'
                and tr.payway='02'
                and trunc(tr.transdate) = trunc(i_baseLine)
        )
				and t.transtype in( 'PAY01','PAY02','PAY03','PAY04')
        and r.custype='O'
				and t.IsThirdAccount= '1'					-- 使用第三方账户
        and t.payway='02'
        and t.conttype = '1'							-- 保单类型：1-个单
        order by r.clientno,t.transdate desc;



				 -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

				-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0600', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;

  end;
end proc_aml_C0600;
/

prompt
prompt Creating procedure PROC_AML_C0700
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_C0700 (i_baseLine in date,i_oprater in varchar2) is
	v_dealNo lxistrademain.dealno%type;													-- 交易编号(业务表)
	v_threshold_money number := getparavalue('SC0700', 'M1');		-- 阀值 累计保费金额
	v_clientno cr_client.clientno%type;  -- 客户号
BEGIN
	-- =============================================
	-- Rule:
	-- 由投保人以外的第三方账户还贷，且金额达到阀值
	-- 1) 抽取保单维度
	--    单渠道：OLAS、IGM
	--    抽取前一天还贷的保单；（Autopay中还贷的费用记录）
	-- 2)  第三方账户判断规则：PRELA NOT IN (’O1’)
	-- 3) 报送数据格式同现有可疑交易格式
	-- 4) 此条规则阀值为5万，实现为可配置形式
  -- 5）该投保人的当天还贷如果是第三方，则累计该投保人作为投保人名下的所有有效保单的第三方还贷
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater 操作人
	-- parameter out: none
	-- Author: xiesf
	-- Create date: 2019/04/02
	-- Changes log:
	--     Author     Date         Description
  --    zhouqk  2019/05/20    计算阀值更改为通过保单号进行分组统计阀值进行判断
  --    zhouqk  2019/05/23    计算阀值使用客户名下所有有效保单的交易金额跟阀值进行比较
	-- =============================================
	DECLARE
		    --定义游标 查询投保人以外的第三方账户还贷，且金额达到阀值的信息
        cursor baseInfo_sor is
               select
                r.clientno,
                t.transno,
                t.contno
              from
                cr_trans t, cr_rel r
              where
                    t.contno = r.contno
                 -- 计算保单下交易总额与阈值比较
                 and exists (
                      select 1
                      from
                        cr_trans temp_t, cr_rel temp_r
                      where r.clientno = temp_r.clientno
                        and temp_r.contno = temp_t.contno
                        and temp_t.transtype ='HK001'       -- 交易类型为还贷
                        and (temp_t.isthirdaccount='1' or isthirdaccount(temp_t.contno,temp_t.accname,'2')='yes')
                        and isvalidcont(temp_t.contno)='yes'-- 有效保单
                        and temp_r.custype='O'
                        and temp_t.conttype='1'
                      group by temp_r.clientno
                        having sum(abs(temp_t.payamt))>=v_threshold_money
                  )
                and exists(
                    select
                          1
                      from cr_trans tr, cr_rel re
                       where
                            tr.contno = re.contno
                        and r.clientno=re.clientno
                        and re.custype='O'
                        and tr.conttype='1'
                        and tr.transtype ='HK001'           -- 交易类型为还贷
                        and (tr.isthirdaccount='1' or isthirdaccount(tr.contno,tr.accname,'2')='yes')
                        and trunc(tr.transdate) = trunc(i_baseLine)
                )
                and t.transtype = 'HK001'
                and r.custype='O'
                and (t.IsThirdAccount= '1'or isthirdaccount(t.contno,t.accname,'2')='yes')					-- 使用第三方账户
                and t.conttype = '1'							          -- 保单类型：1-个单
                order by r.clientno,t.transdate desc;

			-- 定义游标变量
			c_clientno cr_client.clientno%type;	-- 客户号
			c_transno cr_trans.transno%type;		-- 客户身份证件号码
			c_contno cr_trans.contno%type;			-- 保单号

  begin
		open baseInfo_sor;
		loop
			-- 获取当前游标值并赋值给变量
			fetch baseInfo_sor into c_clientno,c_transno,c_contno;
			exit when baseInfo_sor%notfound;  -- 游标循环出口
				-- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0700', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
		end loop;
		close baseInfo_sor;
	END;
end PROC_AML_C0700;
/

prompt
prompt Creating procedure PROC_AML_C0801
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_C0801 (i_baseLine in date,i_oprater in varchar2) is
  v_dealNo lxistrademain.dealno%type;                         -- 交易编号(业务表)
  v_threshold_count number := getparavalue('SC0801', 'N1');   -- 阀值 累计次数
  v_threshold_month NUMBER := getparavalue ('SC0801', 'D1' ); -- 阀值 自然月
BEGIN
  -- =============================================
  -- Rule:
  -- （同一投保人的保单）付费类保全项目，付至同一第三方账户，半年达到三次及以上。
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM；
  --    抽取前一天付费类保全生效的保单；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为3次，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- i_oprater 操作人
  -- parameter out: none
  -- Author: xiesf
  -- Create date: 2019/04/02
  -- Changes log:
  --     Author     Date     Description
  -- =============================================
  DECLARE
  -- 定义游标：同一投保人半年内付费类保全项目付至同一第三方账户到达3次及以上
  cursor baseInfo_sor is
      select r.clientno, t.transno, t.contno
        from cr_trans t, cr_rel r
       where t.contno = r.contno
            -- 判断半年内支付受益人以外的第三方账户3次及以上
         and exists
       (select 1
                from cr_trans tr, cr_rel re
               where re.clientno = r.clientno
                 and tr.contno = re.contno
                    -- 交易日期当天发生身故理赔事件
                 and exists
               (select 1
                        from cr_trans tmp_tr, cr_rel tmp_re
                       where re.clientno = tmp_re.clientno
                         and tmp_tr.contno = tmp_re.contno
                         and tmp_re.custype = 'O'
                         and tmp_tr.IsThirdAccount = '1' -- 是否使用第三方账户：是
                         and tmp_tr.transtype in ('PAY01', 'PAY02') -- 交易类型：身故理赔
                         and tmp_tr.conttype = '1'
                         and tmp_tr.payway = '02'
                         and trunc(tmp_tr.transdate) = trunc(i_baseLine) -- 交易日期当天
                      )
                 and re.custype = 'O'
                 and tr.IsThirdAccount = '1' -- 是否使用第三方账户：是
                 and tr.transtype in ('PAY01', 'PAY02') -- 交易类型：身故理赔
                 and tr.conttype = '1'
                 and tr.payway = '02'
                 and trunc(tr.transdate) >
                     trunc(ADD_MONTHS(i_baseLine, -v_threshold_month)) -- 交易日期在半年内
                 and trunc(tr.transdate) <= trunc(i_baseLine) -- 交易日期在半年内
               group by re.clientno,tr.accname
              having count(tr.transno) >= v_threshold_count)
         and r.custype = 'O'
         and t.conttype = '1'
         and t.payway = '02'
         and t.transtype in ('PAY01', 'PAY02')
         and trunc(t.transdate) >
             trunc(ADD_MONTHS(i_baseLine, -v_threshold_month)) -- 交易日期在半年内
         and trunc(t.transdate) <= trunc(i_baseLine) -- 交易日期在半年内
       order by r.clientno, t.transdate desc;

     -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0801', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;

  end;
END PROC_AML_C0801;
/

prompt
prompt Creating procedure PROC_AML_C0802
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_C0802(i_baseLine in date,i_oprater in varchar2) is

	v_dealNo lxistrademain.dealno%type;													-- 交易编号(业务表)
	v_threshold_count number := getparavalue('SC0802', 'N1');		-- 阀值 累计次数
	v_threshold_month NUMBER := getparavalue ('SC0802', 'D1' );		-- 阀值 自然日

BEGIN
	-- ============================================
	-- Rule:
	-- 身故案件，若理赔金支付给受益人以外的第三方账户，半年达到三次及以上
	-- 1) 抽取保单维度
	--    单渠道：OLAS、IGM
	--    抽取前一天付费类保全生效的保单和赔付类理赔结案的保单
	-- 2) 报送数据格式同现有可疑交易格式
	-- 3) 此条规则阀值为3次，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	-- 							 i_oprater 操作人
	-- parameter out: none
	-- Author: xiesf
	-- Create date: 2019/04/01
	-- Changes log:
	--     Author     Date     Description
  --     baishuai  2020/1/19 去除已授权、已签约的第三方 
	-- ============================================
  DECLARE
  -- 定义游标：半年内身故理赔理赔金支付给受益人以外的第三方账户到达3次及以上
  cursor baseInfo_sor is
        select r.clientno, t.transno, t.contno
          from cr_trans t, cr_rel r
         where t.contno = r.contno
              -- 判断半年内支付受益人以外的第三方账户3次及以上
           and exists
         (select 1
                  from cr_trans tr, cr_rel re
                 where re.clientno = r.clientno
                   and tr.contno = re.contno
                   and not exists (select 1
                          from cr_client cl, cr_rel res
                         where cl.clientno = res.clientno
                           and res.contno = re.contno
                           and cl.name = tr.accname
                           and res.custype='B')
                      -- 交易日期当天发生身故理赔事件
                   and exists
                 (select 1
                          from cr_trans tmp_tr, cr_rel tmp_re
                         where re.clientno = tmp_re.clientno
                           and tmp_tr.contno = tmp_re.contno
                           and tmp_re.custype = 'O'
                           and isthirdaccount(tmp_tr.contno,tmp_tr.accname,'3')='yes'      -- 是否使用第三方账户：是
                           and tmp_tr.transtype = 'PAY03' -- 交易类型：身故理赔
                           and tmp_tr.conttype = '1'
                           and tmp_tr.payway = '02'
                           and trunc(tmp_tr.transdate) = trunc(i_baseLine) -- 交易日期当天
                        )
                        and re.custype = 'O'
                   and isthirdaccount(tr.contno,tr.accname,'3')='yes'     -- 是否使用第三方账户：是
                   and tr.transtype = 'PAY03' -- 交易类型：身故理赔
                   and tr.conttype = '1'
                   and tr.payway = '02'
                   and trunc(tr.transdate) >
                       trunc(ADD_MONTHS(i_baseLine, -v_threshold_month)) -- 交易日期在半年内
                   and trunc(tr.transdate) <= trunc(i_baseLine) -- 交易日期在半年内
                 group by re.clientno
                having count(tr.IsThirdAccount) >= v_threshold_count and count(distinct tr.accname)= 1)
           and r.custype = 'O'
           and t.conttype = '1'
           and t.payway = '02'
           and t.transtype = 'PAY03'
           and trunc(t.transdate) >
               trunc(ADD_MONTHS(i_baseLine, -v_threshold_month)) -- 交易日期在半年内
           and trunc(t.transdate) <= trunc(i_baseLine) -- 交易日期在半年内
         order by r.clientno, t.transdate desc;



      -- 定义游标变量
      c_clientno cr_client.clientno%type;   -- 客户号
      c_transno cr_trans.transno%type;      -- 客户身份证件号码
      c_contno cr_trans.contno%type;        -- 保单号

      v_clientno cr_client.clientno%type;   -- 客户号

  begin

    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno,c_transno,c_contno;

        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0802', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
      end loop;
    close baseInfo_sor;

  end;
end PROC_AML_C0802;
/

prompt
prompt Creating procedure PROC_AML_C0900
prompt =================================
prompt
create or replace procedure proc_aml_C0900 ( i_baseLine in date, i_oprater in varchar2 ) is

  v_dealNo lxistrademain.dealno%type;                            -- 交易编号
  v_threshold_money NUMBER := getparavalue ( 'SC0900', 'M1' );   -- 阀值 应付金额
  v_threshold_year NUMBER := getparavalue ( 'SC0900', 'D1' );    -- 阀值 自然年

begin
  -- =============================================
  -- Rule:
  -- 变更投保人后一年内办理给付类保全业务，且应付金额达到阀值
  -- 1) 抽取保单维度
  --    单渠道：OLAS、IGM
  --    抽取日前一日操作给付类保全业务的payment费用记录；
  -- 2) 报送数据格式同现有可疑交易格式
  -- 3) 此条规则阀值为5万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --                             i_oprater  操作人
  -- i_oprater 操作人
  -- parameter out: none
  -- Author: xiesf
  -- Create date: 2019/03/27
  -- Changes log:
  --     Author     Date     Description
  -- =============================================
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    Trantime,
    args5)
  select
    r.clientno,
    t.transno,
    r.contno,
    t.payamt,
    t.transdate,
    'C0900'
  from
    cr_rel r,cr_trans t
  where r.contno=t.contno
  -- 判断一年之内发生过投保人变更
  and exists(
        select
            1
        from
            cr_trans tr
        where
            tr.contno = t.contno
        and trunc(tr.transdate) <= trunc(t.transdate)
        and tr.transtype = 'BG003'      -- 交易类型为变更投保人
        and trunc(tr.transdate) > trunc(add_months(i_baseLine, -12*v_threshold_year))
        and trunc(tr.transdate) <= trunc(i_baseLine)
    )
	-- 判断当天发生给付类保全业务
	and exists(
        select
            1
        from
            cr_trans tr
        where
            tr.contno=t.contno        -- 同一保单在交易日期当天发生给付类保全业务
        and tr.payway='02'            -- 给付类
        and tr.transtype not in ( 'CLM01','CLM02','CLM03','PAY01','PAY02','PAY03','PAY04')      -- 交易类型为给付类保全业务
        and trunc(tr.transdate) = trunc(i_baseLine)
    )
	and r.custype = 'O'
	and t.conttype = '1'
	and t.payway='02'
	and t.transtype not in ('CLM01','CLM02','CLM03','PAY01','PAY02','PAY03','PAY04')              -- 交易类型为给付类保全业务
	and trunc(t.transdate) > trunc(add_months(i_baseLine, -12*v_threshold_year))
	and trunc(t.transdate) <= trunc(i_baseLine);

  declare
  -- 定义游标：保存能够满足规则的所有信息
  cursor baseInfo_sor is
    select
      CustomerNo,
      TranId,
      PolicyNo
    from
      lxassista l
    where exists(
      select
          1
      from
          lxassista lx
      where l.CustomerNo=lx.CustomerNo
      and   l.PolicyNo=lx.PolicyNo
      group by
          CustomerNo,PolicyNo
      having
          sum(abs(TranMoney)) >= v_threshold_money
    )
    order by
        CustomerNo,
        Trantime desc;

        -- 定义游标变量
        c_clientno cr_client.clientno%type;   -- 客户号
        c_transno cr_trans.transno%type;      -- 客户身份证件号码
        c_contno cr_trans.contno%type;        -- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC0900', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
  delete from LXAssistA where args5 in ('C0900');
END PROC_AML_C0900;
/

prompt
prompt Creating procedure PROC_AML_C1000
prompt =================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_C1000 ( i_baseLine IN DATE, i_oprater IN VARCHAR2 ) is

  v_dealNo lxistrademain.dealno % TYPE;                              -- 交易编号
  v_threshold_money NUMBER := getparavalue ( 'SC1000', 'M1' );      -- 阀值 应付金额
  --v_threshold_percentage NUMBER := getparavalue ( 'SC1000', 'P1' );  -- 阀值

BEGIN
-- =============================================
-- Rule:
-- 值操作整单退保，退保应付金额小于累计已交保费的50%且退保金额大于等于阀值
-- 1) 抽取保单维度
--    单渠道：OLAS、IGM
--    抽取日前一日操作整单退保保全项的保单；
-- 2) 报送数据格式同现有可疑交易格式
-- 3) 此条规则阀值为5万，实现为可配置形式
-- parameter in: i_baseLine 交易日期
--                i_oprater 操作人
-- parameter out: none
-- Author: xiesf
-- Create date: 2019/03/27
-- Changes log:
--     Author     Date     Description
--     baishuai   2020/01/02   退保损失的计算公式调整： 其中曾领取保单价值的金额不应纳入退保损失
-- =============================================
delete from lxassista;
--获取该保单下的借款金额
insert into lxassista(
       policyno,
       numargs1,
       args5)
  select t.contno, sum(t.payamt), 'SC1000_1'
    from cr_trans t, cr_rel r
   where t.contno = r.contno
     and exists (select 1
            from cr_trans tmp_t, cr_rel tmp_r
           where tmp_t.contno = tmp_r.contno
             and tmp_t.contno = t.contno
             and tmp_t.transtype = 'TB001' --保全类型:整单退保
             and tmp_t.payway = '02'
             and tmp_r.custype = 'O'
             and tmp_t.conttype = '1'
             and trunc(tmp_t.transdate) = trunc(i_baseline))
     and t.transtype = 'JK001'
     and r.Custype = 'O'
     and t.payway = '02'
     and t.conttype = '1'
     and trunc(t.transdate)<= trunc(i_baseLine)
     group by t.contno;
--获取该保单下的已还金额
insert into lxassista
  (policyno, numargs1, args5)
  select t.contno, sum(t.payamt), 'SC1000_2'
    from cr_trans t, cr_rel r
   where t.contno = r.contno
     and exists (select 1
            from cr_trans tmp_t, cr_rel tmp_r
           where tmp_t.contno = tmp_r.contno
             and tmp_t.contno = t.contno
             and tmp_t.transtype = 'TB001' --保全类型:整单退保
             and tmp_t.payway = '02'
             and tmp_r.custype = 'O'
             and tmp_t.conttype = '1'
             and trunc(tmp_t.transdate) = trunc(i_baseline))
     and t.transtype = 'HK001'
     and r.Custype = 'O'
     and t.payway = '01'
     and t.conttype = '1'
     and trunc(t.transdate) <= trunc(i_baseLine)
     group by t.contno;

  DECLARE
    --定义游标查询整单退保应付金额小于累计已交保费的50%且退保金额大于等于阀值
    cursor baseInfo_sor is
      SELECT
        r.clientno,
        t.transno,
        t.contno
      FROM
        cr_policy p,
    		cr_trans t,
				cr_rel r
			WHERE
				p.contno = t.contno
				AND t.contno = r.contno
        and (p.sumprem - NVL((select lx.numargs1 from lxassista lx where lx.policyno=t.contno and lx.args5='SC1000_1'),0)--退保损失金额大于阀值
                       + NVL((select la.numargs1 from lxassista la where la.policyno=t.contno and la.args5='SC1000_2'),0)
                       - t.payamt) >= v_threshold_money
        and t.payway='02'
        and r.custype = 'O'
        AND t.transtype = 'TB001'                 --保全类型:整单退保
        and t.conttype='1'
        and trunc(t.transdate)=trunc(i_baseLine)
        order by r.clientno,t.transdate desc;

		-- 定义游标变量
		c_clientno cr_client.clientno % TYPE;		-- 客户号
		c_transno cr_trans.transno % TYPE;			-- 交易编号
		c_contno cr_trans.contno % TYPE;				-- 保单号
	  v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1000', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
  delete from lxassista;
END PROC_AML_C1000;
/

prompt
prompt Creating procedure PROC_AML_C1100
prompt =================================
prompt
create or replace procedure proc_aml_C1100(i_baseLine in date, i_oprater in varchar2) is

  v_dealNo lxistrademain.dealno%type;	 -- 交易编号(业务表)
  v_clientno cr_client.clientno%type;  -- 客户号

  v_threshold_year number := getparavalue('SC1100', 'D1');				-- 阀值 自然年
  v_threshold_prem_before number := getparavalue('SC1100', 'M1'); -- 阀值 追加前保费
  v_threshold_prem_after number := getparavalue('SC1100', 'M2');	-- 阀值 追加后保费

begin
  -- =============================================
  -- Rule:
  -- 单张保单，投保一年内追加大额保费，且追加前保费小于20万，追加后保费大于20万（加保额、加保费、新增附约、定投）
  -- 1) “追加前保费“：
  --?    =已交保费+最近的续期保费（mode prem）*剩余缴费期数（mode数）+ 最近的定投*剩余缴费期数
  -- 2) “追加后保费“：
  -- ?   =已交保费+变更后的当期保费（mode prem）*剩余缴费期数（mode数）+ 变更后的定投*剩余缴费期数
  -- 3) 抽取保单维度
  -- ? 保单渠道：OLAS、IGM；
  -- ? 抽取日前一日操作追加保费的的保单，且保单生效日距当前时间一年内；
  --    触发交易类型：WT001/WT004+AB002（根据金额判断）/FC0C3/FC0C4
  --                  /FC0C5（根据金额判断）/FC0CA（根据金额判断）/FC0CM（根据金额判断）
  -- 4) 报送数据格式同现有可疑交易格式
  -- 5) 此条规则阀值为20万，实现为可配置形式
  -- parameter in:	i_baseLine 交易日期
  -- 								i_oprater 操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/03/22
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk  2019/03/22  初版
  --     xuexc   2019/05/11  修改错误逻辑
  -- ===========================================

  -- 备份baseline一年前至今投保保单的最近续期/定投交易信息
  insert into LXAssistA(
    TranId,
    PolicyNo,
    TranMoney,
    Trantime,
    Args1,
    Args2)
      select
          t.transno,
          t.contno,
          t.payamt,
          t.transdate,
          'C1100',
          t.transtype
      from
          cr_trans t,
          (select
               row_number() over(partition by tmp_t.contno, tmp_t.transtype order by tmp_t.transdate desc) as rn,
               tmp_t.transno,
               tmp_t.contno
           from
               cr_trans tmp_t
           where
               tmp_t.transtype in ('AB001', 'AB002') -- 交易类型：续期/定投
           and trunc(tmp_t.transdate) > add_months(trunc(i_baseline), v_threshold_year * -12)
           and trunc(tmp_t.transdate) < trunc(i_baseline)
          ) temp
      where
          t.transno = temp.transno
      and t.contno = temp.contno
      and exists(
          select 1
          from
              cr_trans tmp_t
          where
              t.contno = tmp_t.contno
          and tmp_t.transtype = 'AA001'  -- 投保
          and trunc(tmp_t.transdate) > add_months(trunc(i_baseline), v_threshold_year * -12)
          and trunc(tmp_t.transdate) < trunc(i_baseline)
          )
      and temp.rn = 1
      and t.transtype in ('AB001', 'AB002') -- 交易类型：续期/定投
      and trunc(t.transdate) > add_months(trunc(i_baseline), v_threshold_year * -12)
      and trunc(t.transdate) <= trunc(i_baseline);

  -- 备份baseline一年前至今无续期/定投的投保保单基本信息
  insert into LXAssistA(
    TranId,
    PolicyNo,
    TranMoney,
    Trantime,
    Args1,
    Args2)
      select
          t.transno,
          t.contno,
          t.payamt,
          t.transdate,
          'C1100',
          'AB001'
      from
          cr_trans t
      where
      not exists(
          select 1
          from
              LXAssistA la
          where
              t.contno = la.policyno
          and la.args1 = 'C1100'
          )
      and t.transtype = 'AA001'         -- 投保
      and trunc(t.transdate) > add_months(trunc(i_baseline), v_threshold_year * -12)
      and trunc(t.transdate) < trunc(i_baseline);

  declare
    -- 定义游标：查询投保一年内追加大额保费，且追加前保费小于阀值，追加后保费大于阀值的交易信息
    cursor baseInfo_sor is
        select
            r.clientno, t.transno, t.contno
        from
            cr_trans t, cr_rel r
        where
            t.contno = r.contno
        and exists(
            select 1
            from cr_trans tmp_t, cr_policy tmp_p
            where
                t.contno = tmp_t.contno
            and tmp_t.contno = tmp_p.contno

           -- 追加前保费小于阀值
            and (case when tmp_p.paymethod = '02'          -- 缴费方式（01:期缴 / 02:趸缴）
                      then tmp_p.sumprem-t.payamt          -- 追加前保费（趸缴）
                      else tmp_p.sumprem-t.payamt + tmp_p.restpayperiod * (
                        nvl((select sum(la.tranmoney) from lxassista la
                            where tmp_p.contno = la.policyno
                              and la.args2 in ('AB001','AB002')
                              and la.args1 = 'C1100'
                              and trunc(la.trantime) < trunc(t.transdate)),0))
                      end) < v_threshold_prem_before


            -- 追加后保费大于阀值
            and (case when tmp_p.paymethod = '02'     -- 缴费方式（01:期缴 / 02:趸缴）
                      then tmp_p.sumprem              -- 追加后保费（趸缴）
                      else tmp_p.sumprem + tmp_p.restpayperiod * (tmp_p.prem +
                          nvl((select la.tranmoney from lxassista la
                            where tmp_p.contno = la.policyno
                              and la.args2 in ('AB002')
                              and la.args1 = 'C1100'
                              and trunc(la.trantime) <= trunc(t.transdate)),0))
                      end) > v_threshold_prem_after

            and tmp_t.transtype = 'AA001'  -- 投保
            and trunc(tmp_t.transdate) > add_months(trunc(t.transdate), v_threshold_year * -12)
            and trunc(tmp_t.transdate) <= trunc(t.transdate)
            )
        and r.custype = 'O'  -- 客户类型（O:投保人）
        and t.payway = '01'  -- 资金进出方向（01:收 / 02:付）
        and t.conttype = '1' -- 保单类型(1:个单)
        and t.transtype in( 'WT001','WT004','AB002','FC0C3','FC0C4','FC0C5','FC0CA','FC0CM')
        and trunc(t.transdate) = trunc(i_baseline)
        order by
            r.clientno , t.transdate desc;

        -- 定义游标变量
        c_clientno cr_client.clientno%type; -- 客户号
        c_transno cr_trans.transno%type;    -- 交易编号
        c_contno cr_trans.contno%type;      -- 保单号

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_clientno, c_transno, c_contno;
        exit when baseInfo_sor%notfound;

        -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1100', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

      end loop;
    close baseInfo_sor;

    -- 删除辅助表C1100的辅助数据
    delete from LXAssistA where Args1 = 'C1100';
  end;
end proc_aml_C1100;
/

prompt
prompt Creating procedure PROC_AML_C1200
prompt =================================
prompt
create or replace procedure proc_aml_C1200(i_baseLine in date,i_oprater in VARCHAR2) is

	v_threshold_count number := getparavalue('SC1200','N1'); 	-- 倍数阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
-- =============================================
	-- Rule:
	-- 	溢缴保费为应缴保费的1倍
	--  1) 抽取保单维度
  --     保单渠道：OLAS、IGM
  --     操作万能追加投资（T）、新单保费（I、7）、定投（Q）的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为1倍，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
	-- =============================================
 declare
    cursor baseInfo_sor is
      select
        r.clientno,
        t.transno,
        t.contno
      from cr_trans t, cr_rel r, cr_policy p
      where t.contno = r.contno
        and r.contno = p.contno
				and p.overprem >= p.prem * v_threshold_count
        and r.custype = 'O'										-- 客户类型：O-投保人
        and t.conttype = '1'									-- 保单类型：1-个单
        and t.transtype='AA001'
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno , t.transdate desc;


				-- 定义游标变量
				c_clientno cr_client.clientno%type;   -- 客户号
				c_transno cr_trans.transno%type;      -- 客户身份证件号码
				c_contno cr_trans.contno%type;        -- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1200', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_C1200;
/

prompt
prompt Creating procedure PROC_AML_C1301
prompt =================================
prompt
create or replace procedure proc_aml_C1301(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC1301', 'M1'); -- 阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
  -- =============================================
	-- Rule:
	-- 同一投保人现金缴纳保费，含万能追加投资、新单保费、定投达到大于等于阀值，即被系统抓取，生成可疑交易；
	--  1) 抽取保单维度
  --     保单渠道：OLAS、IGM
  --     前一天操作万能追加投资（T）、新单保费（I、7）、定投（Q）的保单；(PMCL中保费用途为T、I、7、Q的记录)
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为5千，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
	-- ============================================
declare
    cursor baseInfo_sor is
     select
        r.clientno,
        t.transno,
        t.contno
      from
				cr_trans t, cr_rel r
      where
						t.contno = r.contno
        and exists ( -- 计算保单下所有i_baseline现金交易总额与阈值比较
              select 1
              from
                cr_trans temp_t,cr_rel temp_r
              where r.contno = temp_t.contno
                and r.clientno=temp_r.clientno
                and temp_r.contno=temp_t.contno
                and temp_t.transtype not in ('HK001','PAY01','PAY02','PAY03','PAY04')
                and temp_t.payway='01'
                and temp_r.custype='O'
                and temp_t.paymode='01'
                and temp_t.conttype='1'
                and trunc(temp_t.transdate) = trunc(i_baseLine)
              group by temp_r.clientno,temp_t.contno
                having sum(abs(temp_t.payamt))>=v_threshold_money
          )
        and t.transtype not in ('HK001','PAY01','PAY02','PAY03','PAY04')          --交易类型除还贷外所有收费类
        and t.payway='01'
        and t.paymode='01'                 -- 现金
        and r.custype = 'O'                -- 客户类型：O-投保人
        and t.conttype = '1'               -- 保单类型：1-个单
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno,t.transdate desc;


				-- 定义游标变量
				c_clientno cr_client.clientno%type;   -- 客户号
				c_transno cr_trans.transno%type;      -- 客户身份证件号码
				c_contno cr_trans.contno%type;        -- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1301', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;

end proc_aml_C1301;
/

prompt
prompt Creating procedure PROC_AML_C1302
prompt =================================
prompt
create or replace procedure proc_aml_C1302(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC1302', 'M1'); -- 阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
-- =============================================
	-- Rule:
	-- 操作整单退保，退保金额选择现金支付，且金额大于等于阀值，即被系统抓取，生成可疑交易；
	--  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     抽取日前一日支付 整单退保 费用的保单；
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为5千，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
	-- ============================================
 declare
    cursor baseInfo_sor is
     select
        r.clientno,
        t.transno,
        t.contno
      from
				cr_trans t, cr_rel r
      where
						t.contno = r.contno
        -- 计算保单下所有现金交易总额与阈值比较
        and exists (
              select 1
              from
                cr_trans temp_t,cr_rel temp_r
              where r.contno = temp_t.contno
                and r.clientno= temp_r.clientno
                and temp_r.contno=temp_t.contno
                and temp_r.custype='O'
                and temp_t.conttype = '1'
                and temp_t.payway ='02'
                and temp_t.paymode='01'
                and (temp_t.transtype in ( 'TB001','LQ002') -- 交易类型为整单退保、部分退保、变更引起的退费
                   or
                   temp_t.transtype like 'FC%')
                and trunc(temp_t.transdate) = trunc(i_baseLine)
              group by temp_r.clientno,temp_t.contno
                having sum(abs(temp_t.payamt))>=v_threshold_money
          )
        and r.custype = 'O'              							-- 客户类型：O-投保人
        and t.conttype = '1'            							-- 保单类型：1-个单
        and t.paymode='01'							 							-- 交易方式为现金
        and t.payway='02'                             -- 交易方式为支付
        and(t.transtype in ( 'TB001','LQ002')  				-- 交易类型为整单退保、部分退保、变更引起的退费
         or
         t.transtype like 'FC%')
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno,t.transdate desc;

				-- 定义游标变量
				c_clientno cr_client.clientno%type;  					-- 客户号
				c_transno cr_trans.transno%type;      				-- 客户身份证件号码
				c_contno cr_trans.contno%type;       					-- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1302', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_C1302;
/

prompt
prompt Creating procedure PROC_AML_C1303
prompt =================================
prompt
create or replace procedure proc_aml_C1303(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC1303', 'M1'); -- 阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
-- =============================================
	-- Rule:
	-- 理赔金额选择现金支付，且金额大于等于阀值，即被系统抓取，生成可疑交易；
	--  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     抽取日前一日 支付理赔款 的保单；；
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为5千，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/03/18
	-- Changes log:
	-- =============================================
 declare
    cursor baseInfo_sor is
     select
        r.clientno,
        t.transno,
        t.contno
      from
				cr_trans t, cr_rel r
      where
						t.contno = r.contno
         -- 计算保单下所有现金交易总额与阈值比较
         and exists (
							select 1
							from
								cr_trans temp_t,cr_rel temp_r
							where r.contno = temp_t.contno
                and r.clientno=temp_r.clientno
                and temp_t.contno=temp_r.contno
                and temp_t.transtype in('CLM01','CLM02','CLM03')
                and temp_r.custype='O'
                and temp_t.conttype = '1'
                and temp_t.payway ='02'
                and temp_t.paymode='01'
								and trunc(temp_t.transdate) = trunc(i_baseLine)
							group by temp_r.clientno,temp_t.contno
								having sum(abs(temp_t.payamt))>=v_threshold_money
					)
        and r.custype = 'O'              							-- 客户类型：O-投保人
        and t.conttype = '1'            							-- 保单类型：1-个单
        and t.paymode='01'							 							-- 交易方式为现金
        and t.payway='02'                             -- 交易方式为付
        and t.transtype in('CLM01','CLM02','CLM03')  	-- 交易类型为现金支付理赔款
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno，t.transdate desc;

				-- 定义游标变量
				c_clientno cr_client.clientno%type;  					-- 客户号
				c_transno cr_trans.transno%type;      				-- 客户身份证件号码
				c_contno cr_trans.contno%type;       					-- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1303', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_C1303;
/

prompt
prompt Creating procedure PROC_AML_C1304
prompt =================================
prompt
create or replace procedure proc_aml_C1304(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC1304', 'M1'); -- 阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
  -- =============================================
	-- Rule:
	-- 操作贷款业务，现金还贷或者现金支付贷款，且大于等于阀值，即被系统抓取，生成可疑交易；
 	--  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     抽取日前一日贷款或者还贷的保单；
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为5千，实现为可配置形式
	-- parameter in: i_baseLine 交易日期
	--							 i_oprater  操作人
	-- parameter out: none
	-- Author: zhouqk
	-- Create date: 2019/04/22
	-- Changes log:
  --     Author     Date        Description
  --     zhouqk   2019/04/22       初版
	-- =============================================
 declare
    cursor baseInfo_sor is
     select
        r.clientno,
        t.transno,
        t.contno
      from
				cr_trans t, cr_rel r
      where
						t.contno = r.contno
        and abs(t.payamt)>=v_threshold_money
        and r.custype = 'O'              							-- 客户类型：O-投保人
        and t.conttype = '1'            							-- 保单类型：1-个单
        and t.payway='02'	 							              -- 交易方式为付
        and t.paymode='01'                            -- 交易方式为现金
        and t.transtype in( 'JK001','HK001')  				-- 交易类型为现金贷款或者还贷
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno,t.transdate desc;

				-- 定义游标变量
    c_clientno cr_client.clientno%type;    -- 客户号
    c_transno cr_trans.transno%type;       -- 交易编号
    c_contno cr_trans.contno%type;         -- 保单号

    v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

     -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1304', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_C1304;
/

prompt
prompt Creating procedure PROC_AML_C1305
prompt =================================
prompt
create or replace procedure proc_aml_C1305(i_baseLine in date,i_oprater in VARCHAR2) is

  v_threshold_money number := getparavalue('SC1305', 'M1'); -- 阀值
  v_dealNo lxistrademain.dealno%type;                       -- 交易编号

begin
-- =============================================
  -- Rule:
  -- 款项上传到Payment后，客户修改领款方式转为现金支付，
  -- 现金方式领取满期金、年金、生存现金等款项，且大于等于阀值，即被系统抓取，生成可疑交易
  --  1) 抽取保单维度
  --     保单渠道：OLAS、IGM；
  --     抽取日前一日上payment的款项的保单
  --  2) 报送数据格式同现有可疑交易格式
  --  3) 此条规则阀值为5千，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/05/27
  -- Changes log:
  --     Author     Date        Description
  --     zhouqk   2019/05/27       初版
  -- =============================================
 declare
    cursor baseInfo_sor is
     select
        r.clientno,
        t.transno,
        t.contno
      from
        cr_trans t, cr_rel r
      where
            t.contno = r.contno
         -- 计算保单下所有现金交易总额与阈值比较
         and exists (
              select 1
              from
                cr_trans temp_t,cr_rel temp_r
              where r.contno = temp_t.contno
                and r.clientno=temp_r.clientno
                and temp_r.contno=temp_t.contno
                and temp_r.custype='O'
                and temp_t.transtype ='PAY04'
                and temp_t.conttype = '1'
                and temp_t.payway ='02'
                and temp_t.paymode='01'
                and trunc(temp_t.transdate) = trunc(i_baseLine)
              group by temp_r.clientno,temp_t.contno
                having sum(abs(temp_t.payamt))>=v_threshold_money
          )
        and r.custype = 'O'                           -- 客户类型：O-投保人
        and t.conttype = '1'                          -- 保单类型：1-个单
        and t.paymode='01'                            -- 交易方式为现金
        and t.payway='02'                             -- 交易方式为付
        and t.transtype = 'PAY04'   -- 交易类型为现金支付理赔款
        and trunc(t.transdate) = trunc(i_baseLine)
        order by r.clientno，t.transdate desc;

        -- 定义游标变量
        c_clientno cr_client.clientno%type;           -- 客户号
        c_transno cr_trans.transno%type;              -- 客户身份证件号码
        c_contno cr_trans.contno%type;                -- 保单号

        v_clientno cr_client.clientno%type;

  begin
    open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_transno,c_contno;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
          if v_clientno is null or c_clientno <> v_clientno then
          v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');  --获取交易编号(业务表)

          -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
          PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno, i_oprater, 'SC1305', i_baseLine);
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'1');
          v_clientno := c_clientno; -- 更新可疑主体的客户号

          else
          -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
          PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno,'');

          end if;

          -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
          PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

          -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
          PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

          -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
          PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

          -- 插入交易主体联系方式-临时表 Lxaddress_Temp
          PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);

    end loop;
    close baseInfo_sor;
  end;
end proc_aml_C1305;
/

prompt
prompt Creating procedure PROC_AML_D0100
prompt =================================
prompt
create or replace procedure proc_aml_D0100(i_baseLine in date,i_oprater in varchar2) is
  v_dealNo lxistrademain.dealno%type; -- 交易编号
  v_csnm lxistrademain.csnm%type;     -- 客户号

begin
  -- =============================================
  -- Description: 接续报告
  --            1.自可疑报告报送成功日起，对相关客户进行持续监测，每3个月作为一个监测期；
  --            2.监测期内，如果该客户依然存在同样可疑特征的可疑交易行为，系统自动生成接续报告，
  --              且接续报告中涵盖此3个月监测期内该客户该可疑特征的新增可疑交易；
  --            3.监测期内，如果该客户不存在同样可疑特征的可疑交易行为，但该客户存在其他可疑特征的
  --              可疑交易行为，系统不生成接续报告。
  -- parameter in:  i_baseLine  交易日期
  --                i_oprater   操作人
  -- parameter out: none
  -- Author: hujx
  -- Create date: 2019/03/19
  -- Changes log:
  --     Author     Date     Description
  --     hujx    2019/03/19  初版
  --     caizili 2019/04/26  增加时间和操作员参数，字段更改，逻辑更新
  -- =============================================

  -- 获取自可疑报告报送成功日起，监测期内再次发生可疑交易且未生成接续报告的交易
  declare
    cursor baseInfo_sor is
      select
          lxmain.dealno,
          lxmain.csnm,
          lxmain.stcr,
          (select m.orxn from LXMonitor m where lxmain.stcr = m.stcr and lxmain.csnm = m.csnm) as orxn,
          (select m.torp+1 from LXMonitor m where lxmain.stcr = m.stcr and lxmain.csnm = m.csnm) as torp,
          (select m.dealno from LXMonitor m where lxmain.stcr = m.stcr and lxmain.csnm = m.csnm) as m_dealno
      from
          lxistrademain lxmain
      where exists(
          select 1
          from
              LXMonitor m
          where
              lxmain.stcr = m.stcr
          and lxmain.csnm = m.csnm
          and m.nextmonitoringtime = trunc(i_baseLine) --已到达下次监测时间
          )
      and lxmain.orxn is null -- 首次上报成功的报文名称
      and trunc(lxmain.makedate) > trunc(add_months(i_baseLine, -3))
      and trunc(lxmain.makedate) <= trunc(i_baseLine)
      order by
          lxmain.csnm;

  -- 定义游标变量
  c_m_dealno LXMonitor.dealno%type;  -- 首次上报成功的交易编号
  c_dealno lxistrademain.dealno%type;-- 交易编号
  c_csnm lxistrademain.csnm%type;    -- 客户号
  c_stcr lxistrademain.stcr%type;    -- 可疑特征
  c_orxn lxistrademain.orxn%type;    --首次上报成功的报文名称
  c_torp lxistrademain.torp%type;    --上报次数

  begin
    open baseInfo_sor;
      loop
        -- 获取当前游标值并赋值给变量
        fetch baseInfo_sor into c_dealno, c_csnm, c_stcr, c_orxn, c_torp, c_m_dealno;
        exit when baseInfo_sor%notfound;  -- 游标循环出口

        -- 客户号变更的情况下
		    if v_csnm is null or c_csnm <> v_csnm then
            v_dealNo := NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)
			      v_csnm := c_csnm; -- 更新可疑主体的客户号

            --更新上报次数
            update lxmonitor set torp = c_torp where dealno = c_m_dealno;

            -- 插入可疑交易信息主表
            insert into lxistrademain_temp(
              serialno,--流水号
              dealno, -- 交易编号
              rpnc,   -- 上报网点代码
              detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
              torp,   -- 报送次数标志
              dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
              odrp,   -- 其他报送方向
              tptr,   -- 可疑交易报告触发点
              otpr,   -- 其他可疑交易报告触发点
              stcb,   -- 资金交易及客户行为情况
              aosp,   -- 疑点分析
              stcr,   -- 可疑交易特征
              csnm,   -- 客户号
              senm,   -- 可疑主体姓名/名称
              setp,   -- 可疑主体身份证件/证明文件类型
              oitp,   -- 其他身份证件/证明文件类型
              seid,   -- 可疑主体身份证件/证明文件号码
              sevc,   -- 客户职业或行业
              srnm,   -- 可疑主体法定代表人姓名
              srit,   -- 可疑主体法定代表人身份证件类型
              orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
              srid,   -- 可疑主体法定代表人身份证件号码
              scnm,   -- 可疑主体控股股东或实际控制人名称
              scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
              ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
              scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
              strs,   -- 补充交易标识
              datastate, -- 数据状态
              filename,  -- 附件名称
              filepath,  -- 附件路径
              rpnm,      -- 填报人
              operator,  -- 操作员
              managecom, -- 管理机构
              conttype,  -- 保险类型（01-个单, 02-团单）
              notes,     -- 备注
              getdatamethod,  -- 数据获取方式（01-手工录入, 02-系统抓取）
              baseline,       -- 日期基准
              nextfiletype,   -- 下次上报报文类型
              nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
              nextpackagetype,-- 下次上报报文包类型
              databatchno,    -- 数据批次号
              makedate,       -- 入库时间
              maketime,       -- 入库日期
              modifydate,     -- 最后更新日期
              modifytime,      -- 最后更新时间
              judgmentdate,   -- 终审日期
              orxn)-- 是否接续报告
              select
                getSerialno(sysdate) as serialno,
                LPAD(v_dealNo,20,'0'),
                '@N' as rpnc,
                '01' as detr,  -- 报告紧急程度（01-非特别紧急）
                c_torp as torp,-- 报送次数标示
                '01' as dorp,  -- 报送方向（01-报告中国反洗钱监测分析中心）
                '@N' as odrp,  -- 其他报送方向
                '01' as tptr,  -- 可疑交易报告触发点（01-模型筛选）
                '@N' as otpr,  -- 其他可疑交易报告触发点
                '' as stcb,    -- 资金交易及客户行为情况
                '' as aosp,    -- 疑点分析
                a.stcr as stcr,-- 可疑交易特征 接续报告的可疑特征
                a.csnm as csnm,-- 客户号
                a.senm as senm,-- 可疑主体姓名
                a.setp as setp,
                a.oitp as oitp,
                a.seid as seid,
                a.sevc as sevc,
                a.srnm as srnm,
                a.srit as srit,
                a.orit as orit,
                a.srid as srid,
                a.scnm as scnm,
                a.scit as scit,
                a.ocit as ocit,
                a.scid as scid,
                '@N' as strs,
                null as datastate,
                '' as filename,
                '' as filepath,
                i_oprater as rpnm,
                i_oprater as operator,
                a.managecom as managecom,
                a.conttype as conttype,
                '' as notes,
                '01' as getdatamethod,  -- 数据获取方式（01-系统抓取）
                i_baseLine as baseline,
                '' as nextfiletype,
                '' as nextreferfileno,
                '' as nextpackagetype,
                null as databatchno,
                to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
                to_char(sysdate,'hh24:mi:ss') as maketime,
                null as modifydate,-- 最后更新时间
                null as modifytime,
                null as judgmentdate,--终审日期
                c_orxn as ORXN --接续报告首次上报成功的报文名称
              from lxistrademain a
              where a.dealno = c_m_dealno;

            -- 插入交易主体联系方式
            insert into lxaddress_temp(
              serialno,
              DealNo,
              ListNo,
              CSNM,
              Nationality,
              LinkNumber,
              Adress,
              CusOthContact,
              DataBatchNo,
              MakeDate,
              MakeTime,
              ModifyDate,
              ModifyTime)
              select
                getSerialno(sysdate) as serialno,
                LPAD(v_dealNo,20,'0'),
                a.listno AS ListNo,
                a.csnm AS CSNM,
                a.nationality AS Nationality,
                a.linknumber AS LinkNumber,
                a.adress AS Adress,
                a.cusothcontact AS CusOthContact,
                NULL AS DataBatchNo,
                a.makedate AS MakeDate,
                a.maketime AS MakeTime,
                a.modifydate AS ModifyDate,
                a.modifytime AS ModifyTime
              from lxaddress a
              where a.dealno = c_m_dealno;
  			end if;

        -- 插入可疑交易明细信息
        insert into LXISTRADEDETAIL_temp(
          serialno,
          DealNo,
          TICD,
          ICNM,
          TSTM,
          TRCD,
          ITTP,
          CRTP,
          CRAT,
          CRDR,
          CSTP,
          CAOI,
          TCAN,
          ROTF,
          DataState,
          DataBatchNo,
          MakeDate,
          MakeTime,
          ModifyDate,
          ModifyTime)
          select
            getSerialno(sysdate) as serialno,
            LPAD(v_dealNo,20,'0'),
            a.ticd AS TICD,
            a.icnm AS ICNM,
            a.tstm AS TSTM,
            a.trcd AS TRCD,
            a.ittp AS ITTP,
            a.crtp AS CRTP,
            a.crat AS CRAT,
            a.crdr AS CRDR,
            a.cstp AS CSTP,
            a.caoi AS CAOI,
            a.tcan AS TCAN,
            a.rotf AS ROTF,
            '' as DataState,
            NULL AS DataBatchNo,
            a.makedate AS MakeDate,
            a.maketime AS MakeTime,
            a.modifydate AS ModifyDate,
            a.modifytime AS ModifyTime
          from lxistradedetail a
          where a.dealno = c_dealno;

        --插入可疑交易合同信息
        insert into lxistradecont_temp(
          serialno,
          DealNo,
          CSNM,
          ALNM,
          AppNo,
          ContType,
          AITP,
          OITP,
          ALID,
          ALTP,
          ISTP,
          ISNM,
          RiskCode,
          Effectivedate,
          Expiredate,
          ITNM,
          ISOG,
          ISAT,
          ISFE,
          ISPT,
          CTES,
          FINC,
          DataBatchNo,
          MakeDate,
          MakeTime,
          ModifyDate,
          ModifyTime)
          select
            getSerialno(sysdate) as serialno,
            LPAD(v_dealNo,20,'0'),
            a.csnm AS CSNM,
            a.alnm AS ALNM,
            a.appno AS APPNO,
            a.conttype AS ContType,
            a.aitp AS AITP,
            a.oitp AS OITP,
            a.alid AS ALID,
            a.altp AS ALTP,
            a.istp AS ISTP,
            a.isnm AS ISNM,
            a.riskcode AS RiskCode,
            a.effectivedate AS Effectivedate,
            a.expiredate AS Expiredate,
            a.itnm AS ITNM,
            a.isog AS ISOG,
            a.isat AS ISAT,
            a.isfe AS ISFE,
            a.ispt AS ISPT,
            a.ctes AS CTES,
            a.finc AS FINC,
            NULL AS DataBatchNo,
            a.makedate AS MakeDate,
            a.maketime AS MakeTime,
            a.modifydate AS ModifyDate,
            a.modifytime AS ModifyTime
          from lxistradecont a
          where a.dealno = c_dealno;

        -- 插入可疑交易被保人信息
        insert into lxistradeinsured_temp(
          serialno,
          DEALNO,
          CSNM,
          INSUREDNO,
          ISTN,
          IITP,
          OITP,
          ISID,
          RLTP,
          DataBatchNo,
          MakeDate,
          MakeTime,
          ModifyDate,
          ModifyTime)
          select
            getSerialno(sysdate) as serialno,
            LPAD(v_dealNo,20,'0') AS DealNo,
            a.csnm AS CSNM,
            a.insuredno AS INSUREDNO,
            a.istn AS ISTN,
            a.iitp AS IITP,
            a.oitp AS OITP,
            a.isid AS ISID,
            a.rltp AS RLTP,
            NULL AS DataBatchNo,
            a.makedate AS MakeDate,
            a.maketime AS MakeTime,
            a.modifydate AS ModifyDate,
            a.modifytime AS ModifyTime
          from lxistradeinsured a
          where a.dealno = c_dealno;

        -- 插入可疑交易受益人信息
        insert into lxistradebnf_temp(
          serialno,
          DealNo,
          CSNM,
          InsuredNo,
          BnfNo,
          BNNM,
          BITP,
          OITP,
          BNID,
          DataBatchNo,
          MakeDate,
          MakeTime,
          ModifyDate,
          ModifyTime)
          select
            getSerialno(sysdate) as serialno,
            LPAD(v_dealNo,20,'0') AS DealNo,
            a.csnm AS CSNM,
            a.insuredno AS InsuredNo,
            a.bnfno AS BnfNo,
            a.bnnm AS BNNM,
            a.bitp AS BITP,
            a.oitp AS OITP,
            a.bnid AS BNID,
            NULL AS DataBatchNo,
            a.makedate AS MakeDate,
            a.maketime AS MakeTime,
            a.modifydate AS ModifyDate,
            a.modifytime AS ModifyTime
          from lxistradebnf a
          where a.dealno = c_dealno;

      end loop;
    close baseInfo_sor;

    -- 更新下次监测的时间
    update lxmonitor set NextMonitoringtime = add_months(NextMonitoringtime, 3)
        where trunc(NextMonitoringtime) = trunc(i_baseLine);
  end;
end proc_aml_D0100;
/

prompt
prompt Creating procedure PROC_AML_D0600
prompt =================================
prompt
create or replace procedure PROC_AML_D0600(i_baseLine in date,
                                       i_oprater  in varchar2) is
  v_threshold_money number := getparavalue('D0600', 'M1'); -- 阀值 交易金额
  v_dealNo          lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno        cr_client.clientno%type; -- 客户号
begin
  -- =============================================
  -- Rule:
  --监测指标:激活处于保单假期的保单或失效保单
  --指标规则:激活处于保单假期的投连险或万能险保单或失效保单,且交易金额超过阈值
  --阀值：阀值=RMB 50万元
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date:  2020/01/02
  -- Changes log:
  --     Author     Date        Description
  --
  -- =============================================

  --查询交易金额超过50w且处于恢复保险合同效力，取消保单假期的保单信息
 declare
    cursor baseInfo_sor is
      select  r.clientno, t.transno, t.contno
        from cr_trans t, cr_rel r
       where t.contno = r.contno
         and t.payamt >= v_threshold_money --交易金额大于阀值
         and r.custype='O'    --投保人
         and t.conttype = '1' --1个险
         and t.transtype in ('NP200', 'NP441') --恢复保险合同效力，取消保单假期
         and trunc(t.transdate) = trunc(i_baseLine)
       order by r.clientno, t.transdate desc;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno  cr_trans.transno%type; -- 客户身份证件号码
    c_contno   cr_trans.contno%type; -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound; -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SD0600',
                                   i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');

      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    end loop;
    close baseInfo_sor;
  end;

end PROC_AML_D0600;
/

prompt
prompt Creating procedure PROC_AML_D0701
prompt =================================
prompt
create or replace procedure PROC_aml_D0701(i_baseLine in date,
                                       i_oprater  in varchar2) is
  v_threshold_money      number := getparavalue('D0701', 'M1'); -- 阀值 累计保费金额
  v_threshold_day        number := getparavalue('D0701', 'D1'); -- 阀值 自然日
  v_threshold_percentage number := getparavalue('D0701', 'P1'); -- 阀值 百分比
  v_dealNo               lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno             cr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --监测指标:短期内贷款还款比例过高
  --指标规则:贷款超过阈值且指定期限内累计还款超过一定比例
  --阀值："阀值=RMB30万元，期限=7天，还款比例=60%"
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date:  2019/12/12
  -- Changes log:
  --     Author     Date        Description 
  -- =============================================
  --清空辅助表
  delete from lxassista;

  --获取贷款人名下所有的贷款总额
  insert into lxassista
    (CustomerNo, NumArgs1, args5)
    select r.clientno, sum(t.payamt), 'D0701_01'
      from cr_trans t, cr_rel r
     where t.contno = r.contno
       and r.custype = 'O'
       and t.payway = '02' --01收 02付
       and t.transtype = 'JK001' --还款
       and t.conttype = '1' --1个险
       and trunc(t.transdate) <= trunc(i_baseLine)
       and trunc(t.transdate) > trunc(i_baseLine - v_threshold_day)
     group by r.clientno
    having sum(t.payamt) >= v_threshold_money;

    --获取贷款人名下所有的还款金额
    insert
      into lxassista(CustomerNo, NumArgs1, args5)
            select r.clientno, sum(t.payamt), 'D0701_02'
              from cr_trans t, cr_rel r
             where t.contno = r.contno
               and r.custype = 'O'
               and t.payway = '01' --01收 02付
               and t.transtype = 'HK001' --还款
               and t.conttype = '1' --1个险
               and trunc(t.transdate) <= trunc(i_baseLine)
               and trunc(t.transdate) > trunc(i_baseLine - v_threshold_day)
             group by r.clientno;

declare
      cursor baseInfo_sor is
      --获取满足条件的客户和保单信息
       select r.clientno, t.transno, t.contno
       from cr_trans t, cr_rel r
       where t.contno = r.contno
       and exists
       (select 1  from lxassista la, lxassista lx
       where la.customerno = r.clientno
       and la.customerno = lx.customerno
       and NVL(la.Numargs1,0) >= NVL(lx.numargs1,0) * v_threshold_percentage
       and lx.args5 = 'D0701_01'
       and la.args5 = 'D0701_02')
       and r.custype = 'O'
       and t.payway = '01' --01收 02付
       and t.transtype = 'HK001' --还款
       and t.conttype = '1' --1个险
       and trunc(t.transdate) = trunc(i_baseLine)
       order by r.clientno,t.transdate desc;




  -- 定义游标变量
  c_clientno cr_client.clientno%type; -- 客户号
  c_transno cr_trans.transno%type; -- 客户身份证件号码
  c_contno cr_trans.contno%type; -- 保单号


  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor
        into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound; -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SD0701',
                                   i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');

      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    end loop;
    close baseInfo_sor;
  end;
  --清空辅助表
  delete from lxassista;
end PROC_aml_D0701;
/

prompt
prompt Creating procedure PROC_AML_D0702
prompt =================================
prompt
create or replace procedure PROC_aml_D0702(i_baseLine in date, i_oprater  in varchar2) is
  v_threshold_money number := getparavalue('D0702', 'M1'); -- 阀值 累计保费金额
  v_threshold_day   number := getparavalue('D0702', 'D1'); -- 阀值 自然日
  v_dealNo          lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno        cr_client.clientno%type; -- 客户号
begin
  -- =============================================
  -- Rule:
  --监测指标:投保后快速贷款
  --指标规则:购买保单后短期内进行累计贷款超过阈值
  --阀值："阀值=RMB50万元，期限=30天"
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date:  2019/12/16
  -- Changes log:
  --     Author     Date        Description
  -- =============================================
  declare
    cursor baseInfo_sor is
      select r.clientno, t.transno, t.contno
        from cr_trans t, cr_rel r
       where t.contno = r.contno
         and exists (select 1    --30日内累计借款超过阀值
                from cr_trans tmp_t, cr_rel tmp_r
               where tmp_r.contno = tmp_t.contno
                     and tmp_t.contno=t.contno
                     and tmp_r.custype = 'O' --投保人
                     and tmp_t.payway = '02' --01收 02付
                     and tmp_t.transtype = 'JK001' --借款
                     and tmp_t.conttype = '1' --1个险
                     and trunc(tmp_t.transdate) <= trunc(i_baseLine)
                     and trunc(tmp_t.transdate) >trunc(i_baseLine - v_threshold_day)
                     group by tmp_r.contno
                     having sum(tmp_t.payamt) >= v_threshold_money)
         and exists ( --30日内发生投保的保单
              select 1
                from cr_trans tmp_t
               where tmp_t.contno = t.contno
                 and tmp_t.payway = '01'
                 and tmp_t.transtype = 'AA001'
                 and tmp_t.conttype = '1'
                 and trunc(tmp_t.transdate) <= trunc(i_baseLine)
                 and trunc(tmp_t.transdate) >trunc(i_baseLine - v_threshold_day))  
         and r.custype = 'O'
         and t.payway = '02' --01收 02付
         and t.transtype = 'JK001' --借款
         and t.conttype = '1' --1个险
         and trunc(t.transdate) = trunc(i_baseLine)
         order by r.clientno,t.transdate;

    -- 定义游标变量
    c_clientno cr_client.clientno%type; -- 客户号
    c_transno  cr_trans.transno%type; -- 客户身份证件号码
    c_contno   cr_trans.contno%type; -- 保单号


  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound; -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno, c_contno, i_oprater, 'SD0702',i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');

      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    end loop;
    close baseInfo_sor;
  end;
end PROC_aml_D0702;
/

prompt
prompt Creating procedure PROC_AML_D0703
prompt =================================
prompt
create or replace procedure PROC_aml_D0703(i_baseLine in date,i_oprater  in varchar2) is

  v_threshold_money      number := getparavalue('D0703', 'M1'); -- 阀值 贷款金额
  v_threshold_day        number := getparavalue('D0703', 'D1'); -- 阀值 自然日
  v_threshold_percentage number := getparavalue('D0703', 'P1'); -- 阀值 百分比
  v_dealNo               lxistrademain.dealno%type; -- 交易编号(业务表)
  v_clientno             cr_client.clientno%type; -- 客户号

begin
  -- =============================================
  -- Rule:
  --监测指标:退保时贷款未还
  --对于同一投保人的单张保单，累计贷款金额超过累计已交保费的50%并超过阀值，且从最后一次贷款发放日期的7天内申请退保，即被系统抓取，生成可疑交易；
  --1) 抽取保单维度
  --保单渠道：OLAS、IGM
  --2) 报送数据格式同现有可疑交易格式
  --3) 此条规则阀值为20万，实现为可配置形式
  --单张保单累计贷款金额 - 累计已交保费>20万
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date:  2019/12/12
  -- Changes log:
  --     Author     Date        Description
  -- =============================================
  --清空辅助表
  delete from lxassista;

  --获取7天内存在贷款的保单
  insert into lxassista
    (PolicyNo, args5)
    select distinct t.contno, 'D0703_1'
      from cr_trans t, cr_rel r
     where t.contno = r.contno
       and r.custype = 'O'
       and t.payway = '02'
       and t.transtype = 'JK001'
       and t.conttype = '1'
       and trunc(t.transdate) <= trunc(i_baseLine)
       and trunc(t.transdate) > trunc(i_baseLine - v_threshold_day);

  --查询单张保单下的贷款总额
  insert into lxassista
    (policyno, numargs1, args5)
    select t.contno, sum(t.payamt), 'D0703_2'
      from cr_trans t, cr_rel r
     where t.contno = r.contno
       and exists (select 1
              from lxassista la
             where la.policyno = t.contno
               and la.args5 = 'D0703_1')
       and r.custype = 'O'
       and t.payway = '02'
       and t.transtype = 'JK001'
       and t.conttype = '1'
       and trunc(t.transdate) <= trunc(i_baseLine)
     group by t.contno;

   --定义游标
declare
    cursor baseInfo_sor is
      select  r.clientno, t.transno,t.contno
      from cr_trans t, cr_rel r, cr_policy p
      where t.contno = r.contno
      and t.contno = p.contno
      and exists                 --累计贷款金额大于累计已交保费的50%
      (select 1 from lxassista la
       where la.policyno = t.contno
             and la.numargs1 > p.SumPrem * v_threshold_percentage
             and la.numargs1-p.sumprem  > v_threshold_money --单张保单累计贷款金额 - 累计已交保费>阀值
             and la.args5 = 'D0703_2'
       )      
      and t.payway = '02'
      and r.custype='O'
      and t.transtype = 'TB001'
      and t.conttype = '1'
      and trunc(t.transdate) = trunc(i_baseLine)
      order by r.clientno,t.transdate desc;




  -- 定义游标变量
  c_clientno cr_client.clientno%type; -- 客户号
  c_transno cr_trans.transno%type; -- 客户身份证件号码
  c_contno cr_trans.contno%type; -- 保单号


  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound; -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SD0703',
                                   i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');

      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    end loop;
    close baseInfo_sor;
  end;
  --清空辅助表
  delete from lxassista;
end PROC_aml_D0703;
/

prompt
prompt Creating procedure PROC_AML_D0800
prompt =================================
prompt
create or replace procedure PROC_aml_D0800(i_baseLine in date, i_oprater  in varchar2) is
        v_threshold_money number := getparavalue('D0800', 'M1'); -- 阀值 累计保费金额
        v_threshold_day   number := getparavalue('D0800', 'D1'); -- 阀值 自然日
        v_threshold_count number := getparavalue('D0800', 'N1'); -- 阀值 相同险种个数
        v_dealNo          lxistrademain.dealno%type; -- 交易编号(业务表)
        v_clientno        cr_client.clientno%type; -- 客户号
begin
  -- =============================================
  -- Rule:
  --监测指标:同一投保人购买多份相同保单
  --指标规则:一定期限内，同一投保人购买相同险种 （投连险、万能险）3份或以上，且被保人、受益人相同，合计保费超过阀值
  --阀值："期限=30天,阀值= 年化保费50万,相同险种 >= 3份"
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: baishuai
  -- Create date:  2019/12/19
  -- Changes log:
  --     Author     Date        Description
  -- =============================================
 
  --清空辅助表
  delete from lxassista;
  
   --获取一定期限内，同一投保人购买的相同险种3份或以上的保单信息
  insert into lxassista(PolicyNo, customerno, args1, args5)
    select  t.contno, r.clientno, rk.policytype, 'D0800_1'
      from cr_trans t, cr_rel r, cr_risk rk
     where t.contno = r.contno
       and t.contno = rk.contno
        and exists  --当天存在投保或者附加险
     (select 1
              from cr_trans cms_t, cr_rel cms_r
             where cms_r.contno = cms_t.contno
               and r.clientno = cms_r.clientno --同一客户
               and cms_t.payway = '01'
               and cms_r.custype = 'O'
               and cms_t.transtype in('AA001','FC0C4')
               and cms_t.conttype = '1'
               and trunc(cms_t.transdate) =trunc(i_baseLine)
            )
       and exists(--相同险种超过3份
           select 1 from cr_trans tmp_t,cr_rel tmp_r,cr_risk tmp_rk
           where tmp_t.contno=tmp_r.contno
           and tmp_t.contno=tmp_rk.contno
           and tmp_r.clientno=r.clientno--同一投保人
           and tmp_rk.policytype=rk.policytype--相同险种
           and tmp_t.payway='01'
           and tmp_r.custype='O'
           and tmp_t.transtype in ('AA001','FC0C4')
           and tmp_t.conttype='1'
           and trunc(tmp_t.transdate) > trunc(i_baseLine - v_threshold_day)
           and trunc(tmp_t.transdate) <= trunc(i_baseLine)
           group by tmp_r.clientno,tmp_rk.policytype
           having count(tmp_rk.contno)>=v_threshold_count   
       )       
       and t.payway = '01'
       and r.custype = 'O'
       and t.transtype in('AA001','FC0C4')
       and t.conttype = '1'
       and trunc(t.transdate) > trunc(i_baseLine - v_threshold_day)
       and trunc(t.transdate) <= trunc(i_baseLine)
       order by r.clientno desc;

  --获取被保人和受益人的保单信息   
insert into lxassista(PolicyNo, customerno, args5)
  select lx.policyNo, lx.customerno, 'D0800_2'
    from cr_trans t,lxassista lx
   where lx.policyno = t.contno
     and lx.args5 = 'D0800_1'
     and t.payway = '01'
     and t.transtype in('AA001','FC0C4')
     and t.conttype = '1'
     --被保人
    and exists(
       --通过子查询查到被保人的客户号对应的保单号
       select  1  from cr_rel rr where exists
       (
       --查询被保人的客户号
          select 1 from cr_rel r where exists
              (
             select 1 from cr_rel tmp_r where tmp_r.clientno = lx.customerno
                and tmp_r.custype = 'O'
                and tmp_r.contno = r.contno
              )
              and r.custype = 'I'
              and rr.clientno = r.clientno
              group by r.clientno having count(r.clientno) >= v_threshold_count
        ) 
          and t.contno = rr.contno
          and rr.custype = 'I'
       )           
     --受益人
      and exists(
       --通过子查询查到受益人的客户号对应的保单号
       select  1  from cr_rel rr where exists
       (
       --查询受益人的客户号
          select 1 from cr_rel r where exists
              (
             select 1 from cr_rel tmp_r where tmp_r.clientno = lx.customerno
                and tmp_r.custype = 'O'
                and tmp_r.contno = r.contno
              )
              and r.custype = 'B'
              and rr.clientno = r.clientno
              group by r.clientno having count(r.clientno) >= v_threshold_count
        ) 
          and t.contno = rr.contno
          and rr.custype = 'B'
       )               
     and trunc(t.transdate) > trunc(i_baseLine - v_threshold_day)
     and trunc(t.transdate) <= trunc(i_baseLine);

    --投保人累计年化保费大于50w
     declare
             cursor baseInfo_sor is
                    select r.clientno, t.transno, t.contno
                      from cr_trans t, cr_rel r
                     where t.contno = r.contno
                       and exists
                     (select 1
                              from lxassista lx, cr_policy p
                             where lx.customerno = r.clientno
                               and lx.policyno = p.contno
                               and lx.args5 = 'D0800_2'
                             group by lx.customerno
                            having sum(p.yearprem) >= v_threshold_money)
                       and exists
					               (
                       select 1 from lxassista la
                       where
                       la.policyno=t.contno
                       and la.args5='D0800_2'
                       )
                       and t.payway = '01'
                       and r.custype = 'O'
                       and t.transtype in('AA001','FC0C4')
                       and t.conttype = '1'
                       and trunc(t.transdate) = trunc(i_baseLine)
                       order by r.clientno,t.transdate desc;

                    -- 定义游标变量
                     c_clientno cr_client.clientno%type; -- 客户号
                     c_transno cr_trans.transno%type; -- 客户身份证件号码
                     c_contno cr_trans.contno%type; -- 保单号

  begin
    open baseInfo_sor;
    loop
      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor
        into c_clientno, c_transno, c_contno;
      exit when baseInfo_sor%notfound; -- 游标循环出口

      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
        v_dealNo := NEXTVAL2('AMLDEALNO', 'SN'); --获取交易编号(业务表)

        -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
        PROC_AML_INS_LXISTRADEMAIN(v_dealNo,
                                   c_clientno,
                                   c_contno,
                                   i_oprater,
                                   'SD0800',
                                   i_baseLine);
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '1');
        v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
        -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
        PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_contno, c_transno, '');

      end if;

      -- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
      PROC_AML_INS_LXISTRADECONT(v_dealNo, c_clientno, c_contno);

      -- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
      PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_contno);

      -- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
      PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_contno);

      -- 插入交易主体联系方式-临时表 Lxaddress_Temp
      PROC_AML_INS_LXADDRESS(v_dealNo, c_clientno);
    end loop;
    close baseInfo_sor;
  end;
  --清空辅助表
  delete from lxassista where args5 in ('D0800_1','D0800_2');
end PROC_aml_D0800;
/

prompt
prompt Creating procedure PROC_AML_EXTRAMID
prompt ====================================
prompt
create or replace procedure proc_aml_extraMID(
  startDate in VARCHAR2,
  endDate in VARCHAR2
) is
  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息
  v_errormsg LLogTrace.DealDesc%type;
  v_TraceId LLogTrace.TraceId%type;
begin
    -- =============================================
  -- Description: 将mid表中的数据放入到平台表中
  -- parameter in:    startDate   开始日期
  --                  endDate     结束日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/04/29
  -- Changes log:
  --     Author     Date     Description
  --     czl     2019/04/29     初版
  -- =============================================
  SELECT TO_char(sysdate, 'yyyymmddHH24mmss') into v_TraceId from dual;

 -- 先插入轨迹
   insert into LLogTrace
    (TraceId,
     FuncCode,
     StartTime,
     DealState,
     DealDesc,
     DataBatchNo,
     DataState,
     Operator,
     InsertTime,
     ModifyTime)
  values
    (v_TraceId,
     '000001',
     sysdate,
     '00',
     '执行中',
     v_TraceId,
     '01',
     'system',
     sysdate,
     sysdate);
     commit;

 --根据MID表对CR表中的数据进行去重操作
 DELETE FROM CR_Policy WHERE EXISTS(SELECT 1 FROM MID_Policy a WHERE a.ContNo = CR_POLICY.CONTNO) ;
 DELETE FROM CR_Address WHERE EXISTS(SELECT 1 FROM MID_Address a WHERE a.clientNo = CR_Address.clientNo) ;
 DELETE FROM CR_Rel WHERE EXISTS(SELECT 1 FROM MID_Rel a WHERE a.ContNo = CR_REL.ContNo);
 DELETE FROM CR_Risk WHERE EXISTS(SELECT 1 FROM MID_Risk a WHERE a.ContNo = CR_RISK.CONTNO) ;
 DELETE FROM CR_Client WHERE EXISTS(SELECT 1 FROM MID_Client a WHERE a.ClientNo = CR_CLIENT.CLIENTNO) ;
 DELETE FROM CR_Trans WHERE EXISTS(SELECT 1 FROM MID_Trans a WHERE A.TransNo = CR_TRANS.TRANSNO) ;
 DELETE FROM CR_TransDetail WHERE EXISTS(SELECT 1 FROM MID_TransDetail a WHERE A.TransNo = CR_TransDetail.TransNo AND a.contno = CR_TRANSDETAIL.CONTNO) ;

--CR_Address(客户保单关联表数据提取)
  INSERT INTO CR_ADDRESS (
    clientno,
    ListNo,
    clienttype,
    LinkNumber,
    Adress,
    CusOthContact,
  nationality,
    country,
    MakeDate,
    MakeTime,
    batchno,
    conttype)
  (
    select
      A.clientno AS clientno,
      ROW_NUMBER () OVER (ORDER BY clientno) AS ListNo,
      A.ClientType AS clienttype,
      A.linknumber AS LinkNumber,
      A.adress AS Adress,
      A.CusOthContact AS CusOthContact,
      A.Nationality AS nationality,
      A.Country AS country,
      A.MakeDate,
      A.MakeTime,
      v_TraceId AS batchno,
      A.conttype AS conttype
    from
     MID_Address  A
  );

--cr_client(客户基本信息表数据提取)
    INSERT INTO CR_CLIENT
  select clientno,
        originalclientno,
        source,
        name,
        birthday,
        age,
        sex,
        grade,
        cardtype,
        othercardtype,
        cardid,
        cardexpiredate,
        clienttype,
        workphone,
        familyphone,
        telephone,
        occupation,
        businesstype,
        income,
        grpname,
        address,
        otherclientinfo,
        zipcode,
        nationality,
        comcode,
        conttype,
        businesslicenseno,
        orgcomcode,
        taxregistcertno,
        legalperson,
        legalpersoncardtype,
        otherlpcardtype,
        legalpersoncardid,
        linkman,
        comregistarea,
        comregisttype,
        combusinessarea,
        combusinessscope,
        appntnum,
        comstaffsize,
        grpnature,
        founddate,
        holderkey,
        holdername,
        holdercardtype,
        otherholdercardtype,
        holdercardid,
        holderoccupation,
        holderradio,
        holderotherinfo,
        relaspecarea,
        fatctry,
        countrycode,
        suspiciouscode,
        fundsource,
        Makedate,
        MakeTime,
        v_TraceId,
        idverifystatus,
        isfatcaandcrs
        from mid_client;

--CR_Policy(保单信息表数据提取)
  INSERT INTO CR_POLICY
  select contno,
         conttype,
         locid,
         prem,
         amnt,
         paymethod,
         contstatus,
         effectivedate,
         expiredate,
         accountno,
         sumprem,
         mainyearprem,
         yearprem,
         agentcode,
         grpflag,
         source,
         inssubject,
         investflag,
         remainaccount,
         payperiod,
         salechnl,
         insuredpeoples,
         payinteval,
         othercontinfo,
         cashvalue,
         instfrom,
         policyaddress,
         makedate,
         maketime,
         v_TraceId,
         overprem,
         phone,
         primeyearprem,
         restpayperiod
       from MID_POLICY;

--CR_Rel(客户保单关联表数据提取)
  insert into CR_Rel
  select contno,
         clientno,
         custype,
         relaappnt,
         makedate,
         maketime,
         v_TraceId,
         policyphone,
         usecardtype,
         useothercardtype,
         usecardid
       from MID_Rel;

--CR_RISK(险种信息表数据提取)
  insert into CR_RISK(
         contno,
         riskcode,
         riskname,
         mainflag,
         risktype,
         insamount,
         prem,
         payinteval,
         effectivedate,
         expiredate,
         yearprem,
		     salechnl,
		     makedate,
		     maketime,
         BatchNo
  )
  select contno,
         riskcode,
         riskname,
         mainflag,
         risktype,
         insamount,
         prem,
         payinteval,
         effectivedate,
         expiredate,
         yearprem,
		     salechnl,
		     makedate,
		     maketime,
         v_TraceId
       from MID_RISK;

--cr_trans(交易记录表数据提取)
  insert into CR_TRANS
  select transno,
         contno,
         conttype,
         transmethod,
         transtype,
         transdate,
         transfromregion,
         transtoregion,
         curetype,
         payamt,
         payway,
         paymode,
         paytype,
         accbank,
         accno,
         accname,
         acctype,
         agentname,
         agentcardtype,
         agentothercardtype,
         agentcardid,
         agentnationality,
         opposidefinaname,
         opposidefinatype,
         opposidefinacode,
         opposidezipcode,
         tradecusname,
         tradecuscardtype,
         tradecusothercardtype,
         tradecuscardid,
         tradecusacctype,
         tradecusaccno,
         source,
         busimark,
         relationwithregion,
         useoffund,
         makedate,
         maketime,
         v_TraceId,
         accopentime,
         bankcardtype,
         bankcardothertype,
         bankcardnumber,
         rpmatchnotype,
         rpmatchnumber,
         noncountertrantype,
         noncounterothtrantype,
         noncountertrandevice,
         bankpaymenttrancode,
         foreigntranscode,
         crmb,
         cusd,
         remark,
         visitreason,
         isthirdaccount,
         nvl(requestdate,transdate)
       from MID_TRANS;

--cr_transDetail(交易记录明细表数据提取)
  insert into CR_TRANSDETAIL
  select transno,
         contno,
         subno,
         notes,
         ext1,
         ext2,
         ext3,
         ext4,
         ext5,
         makedate,
         maketime,
         v_TraceId
       from MID_TRANSDETAIL;
       commit;

  --备份MID表数据
  insert into MID_client_bak select * from MID_Client;
  insert into MID_TransDetail_bak select * from MID_TransDetail;
  insert into MID_Trans_bak select * from MID_Trans;
  insert into MID_Policy_bak select * from MID_Policy;
  insert into MID_Risk_bak select * from MID_Risk;
  insert into MID_Rel_bak select * from MID_Rel;
  insert into MID_Address_bak select * from MID_Address;

  --数据提取后清空MID表
  delete from  MID_Trans;
  delete from  MID_TransDetail;
  delete from  MID_Client;
  delete from  MID_Policy;
  delete from  MID_Risk;
  delete from  MID_Rel;
  delete from  MID_Address;

   --险种配置同步

  -- 执行完毕，更新轨迹状态
    update LLogTrace
     set dealstate  = '01',
       dealdesc   = '成功结束',
       InsertTime = to_date(startDate,'YYYY-MM-DD'),
       modifytime = to_date(startDate,'YYYY-MM-DD'),
       endtime = sysdate
     where traceid = v_TraceId;
     commit;
   -- 异常处理
    EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=errorCode||errorMsg;

  -- 将提取失败的信息记录到提取结果表中
  update LLogTrace
     set dealstate  = '02',
       dealdesc   = v_errormsg,
       InsertTime = to_date(startDate,'YYYY-MM-DD'),
       modifytime = to_date(startDate,'YYYY-MM-DD')
     where traceid = v_TraceId;
  commit;

end proc_aml_extraMID;
/

prompt
prompt Creating procedure PROC_AML_EXTRAMID_ETA
prompt ========================================
prompt
create or replace procedure PROC_AML_EXTRAMID_ETA(
  startDate in VARCHAR2,
  endDate in VARCHAR2
) is
  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息
  v_errormsg LLogTrace.DealDesc%type;
  v_TraceId LLogTrace.TraceId%type;
begin
    -- =============================================
  -- Description: 将mid表中的数据放入到平台表中
  -- parameter in:    startDate   开始日期
  --                  endDate     结束日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/04/29
  -- Changes log:
  --     Author     Date     Description
  --     czl     2019/04/29     初版
  --     czl     2019/07/11     eTA客户整合
  -- =============================================
  SELECT TO_char(sysdate, 'yyyymmddHH24mmss') into v_TraceId from dual;

  -- 先插入轨迹
   insert into LLogTrace
    (TraceId,
     FuncCode,
     StartTime,
     DealState,
     DealDesc,
     DataBatchNo,
     DataState,
     Operator,
     InsertTime,
     ModifyTime)
  values
    (v_TraceId,
     '000001',
     sysdate,
     '00',
     '执行中',
     v_TraceId,
     '01',
     'system',
     sysdate,
     sysdate);
  commit;

  --批次号
  update mid_client set BATCHNO= v_TraceId;
  update MID_TransDetail set BATCHNO= v_TraceId;
  update MID_Trans set BATCHNO= v_TraceId;
  update MID_Policy set BATCHNO= v_TraceId;
  update MID_Risk set BATCHNO= v_TraceId;
  update MID_Rel set BATCHNO= v_TraceId;
  update MID_Address set BATCHNO= v_TraceId;


  --备份MID表数据
  /*insert into MID_client_bak select * from MID_Client;
  insert into MID_TransDetail_bak select * from MID_TransDetail;
  insert into MID_Trans_bak select * from MID_Trans;
  insert into MID_Policy_bak select * from MID_Policy;
  insert into MID_Risk_bak select * from MID_Risk;
  insert into MID_Rel_bak select * from MID_Rel;
  insert into MID_Address_bak select * from MID_Address;*/

  --清空客户表辅助表
  delete from CR_Client_temp;
  delete from lxassista;

  insert into lxassista(
    customerno,
    args1,
    args2,
  args3
  )select
    clientno,
    name,
    cardid,
  source
   from mid_client;

  --OLAS/IGM客户(主客户号为OLAS/IGM客户号)，排除受益人
  insert into CR_Client_temp
  select m.clientno,
        c.originalclientno,
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        m.BATCHNO,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m
  join cr_client c
  on m.clientno=c.clientno
  and substr(c.clientno,1,1)!='B'
  and substr(m.clientno,1,1)!='B'
  and m.source='1'
  and c.source='1';

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --OLAS/IGM客户(主客户号为ETA客户号)
  insert into CR_Client_temp
  select c.clientno,
        m.clientno,
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        m.BATCHNO,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m
  join cr_client c
  on m.name=c.name
  and m.cardid=c.cardid
  and substr(c.clientno,1,1)!='B'
  and substr(m.clientno,1,1)!='B'
  and m.source='1';    --OLAS

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --ETA客户(平台表为OLAS/IGM客户信息)
  insert into CR_Client_temp
  select c.clientno,
        m.clientno,
        c.source,
        c.name,
        c.birthday,
        c.age,
        c.sex,
        c.grade,
        c.cardtype,
        c.othercardtype,
        c.cardid,
        c.cardexpiredate,
        c.clienttype,
        c.workphone,
        c.familyphone,
        c.telephone,
        c.occupation,
        c.businesstype,
        c.income,
        c.grpname,
        c.address,
        c.otherclientinfo,
        c.zipcode,
        c.nationality,
        c.comcode,
        c.conttype,
        c.businesslicenseno,
        c.orgcomcode,
        c.taxregistcertno,
        c.legalperson,
        c.legalpersoncardtype,
        c.otherlpcardtype,
        c.legalpersoncardid,
        c.linkman,
        c.comregistarea,
        c.comregisttype,
        c.combusinessarea,
        c.combusinessscope,
        c.appntnum,
        c.comstaffsize,
        c.grpnature,
        c.founddate,
        c.holderkey,
        c.holdername,
        c.holdercardtype,
        c.otherholdercardtype,
        c.holdercardid,
        c.holderoccupation,
        c.holderradio,
        c.holderotherinfo,
        c.relaspecarea,
        c.fatctry,
        c.countrycode,
        c.suspiciouscode,
        c.fundsource,
        m.Makedate,
        m.MakeTime,
        m.BATCHNO,
        c.idverifystatus,
        c.isfatcaandcrs
    from mid_client m
  join cr_client c
  on m.name=c.name
  and m.cardid=c.cardid
  and substr(c.clientno,1,1)!='B'
  and substr(m.clientno,1,1)!='B'
  and m.source='3'
  and c.source='1';    --OLAS

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --ETA客户(平台表为ETA客户信息)
  insert into CR_Client_temp
  select c.clientno,
        c.originalclientno,
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        m.BATCHNO,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m
  join cr_client c
  on m.cardid=c.cardid
  and m.name=c.name
  and substr(m.clientno,1,1)!='B'
  and substr(c.clientno,1,1)!='B'
  and m.source='3'
  and c.source='3';

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --抓取核心过来的非受益人的新客户
  insert into CR_Client_temp
  select m.clientno,
        (select c.clientno from mid_client c where c.clientno!=m.clientno and c.name=m.name and c.cardid=m.cardid and substr(c.clientno,1,1)!='B'and c.source='3') as originalclientno,
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        v_TraceId,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m
  where substr(m.clientno,1,1)!='B'
  and m.source='1';

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --抓取过来的新eTA客户
  insert into CR_Client_temp
  select m.clientno,
        '',
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        v_TraceId,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m
  where m.source='3';

  --删除已放入客户辅助表的姓名+ID
  delete from mid_client m where exists (select 1 from CR_Client_temp c where c.name=m.name and c.cardid=m.cardid);

  --抓取核心过来的新受益人
  insert into CR_Client_temp
  select m.clientno,
        '',
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        v_TraceId,
        m.idverifystatus,
        m.isfatcaandcrs
    from mid_client m;

  --根据MID表对CR表中的数据进行去重操作
 DELETE FROM CR_Policy WHERE EXISTS(SELECT 1 FROM MID_Policy a WHERE a.ContNo = CR_POLICY.CONTNO) ;
 DELETE FROM CR_Address WHERE EXISTS(SELECT 1 FROM CR_Client_temp a WHERE a.clientNo = CR_Address.clientNo) ;
 DELETE FROM CR_Rel WHERE EXISTS(SELECT 1 FROM MID_Rel a WHERE a.ContNo = CR_REL.ContNo);
 DELETE FROM CR_Risk WHERE EXISTS(SELECT 1 FROM MID_Risk a WHERE a.ContNo = CR_RISK.CONTNO) ;
 DELETE FROM CR_Client WHERE EXISTS(SELECT 1 FROM CR_Client_temp a WHERE a.ClientNo = CR_CLIENT.CLIENTNO) ;
 DELETE FROM CR_Trans WHERE EXISTS(SELECT 1 FROM MID_Trans a WHERE A.TransNo = CR_TRANS.TRANSNO) ;
 DELETE FROM CR_TransDetail WHERE EXISTS(SELECT 1 FROM MID_TransDetail a WHERE A.TransNo = CR_TransDetail.TransNo AND a.contno = CR_TRANSDETAIL.CONTNO);



  --cr_client(客户基本信息表数据提取)
    INSERT INTO CR_CLIENT
    select
        m.clientno,
        m.originalclientno,
        m.source,
        m.name,
        m.birthday,
        m.age,
        m.sex,
        m.grade,
        m.cardtype,
        m.othercardtype,
        m.cardid,
        m.cardexpiredate,
        m.clienttype,
        m.workphone,
        m.familyphone,
        m.telephone,
        m.occupation,
        m.businesstype,
        m.income,
        m.grpname,
        m.address,
        m.otherclientinfo,
        m.zipcode,
        m.nationality,
        m.comcode,
        m.conttype,
        m.businesslicenseno,
        m.orgcomcode,
        m.taxregistcertno,
        m.legalperson,
        m.legalpersoncardtype,
        m.otherlpcardtype,
        m.legalpersoncardid,
        m.linkman,
        m.comregistarea,
        m.comregisttype,
        m.combusinessarea,
        m.combusinessscope,
        m.appntnum,
        m.comstaffsize,
        m.grpnature,
        m.founddate,
        m.holderkey,
        m.holdername,
        m.holdercardtype,
        m.otherholdercardtype,
        m.holdercardid,
        m.holderoccupation,
        m.holderradio,
        m.holderotherinfo,
        m.relaspecarea,
        m.fatctry,
        m.countrycode,
        m.suspiciouscode,
        m.fundsource,
        m.Makedate,
        m.MakeTime,
        v_TraceId,
        m.idverifystatus,
        m.isfatcaandcrs
    from CR_Client_temp m
  join (select row_number() over(partition by clientNo order by clientNo,source asc) as rowno,clientNo, source from CR_Client_temp) tmp
  on m.source=tmp.source  --去重，优先取核心过来的客户
  and m.clientNo=tmp.clientNo
  and tmp.rowno=1;

  --平台表有OLAS/IGM的联系地址，则删除中间表中同一个客户ETA过来的联系地址
  delete from mid_address m where exists (select 1 from lxassista l where l.customerno=m.clientNo and not exists (select 1 from cr_client_temp c where c.clientno=l.customerno and c.source='3') and l.args3='3');

  --CR_Rel(客户保单关联表数据提取)
  insert into CR_Rel
  select distinct
     m.contno,
         c.clientno,
         m.custype,
         m.relaappnt,
         m.makedate,
         m.maketime,
         v_TraceId,
         m.policyphone,
         m.usecardtype,
         m.useothercardtype,
         m.usecardid
       from MID_Rel m
     join lxassista lx
     on m.clientno=lx.customerno
     join CR_Client_temp c
     on  c.name=lx.args1
     and c.cardid=lx.args2
     and m.usecardid=c.cardid;

  --CR_Address(联系地址表提取)
  INSERT INTO CR_ADDRESS (
    clientno,
    ListNo,
    clienttype,
    LinkNumber,
    Adress,
    CusOthContact,
  nationality,
    country,
    MakeDate,
    MakeTime,
    batchno,
    conttype)
  (
    select distinct
      c.clientno AS clientno,
      ROW_NUMBER () OVER (partition by a.clientNo ORDER BY a.clientno) AS ListNo,
      A.ClientType AS clienttype,
      A.linknumber AS LinkNumber,
      A.adress AS Adress,
      A.CusOthContact AS CusOthContact,
      A.Nationality AS nationality,
      A.Country AS country,
      sysdate,
      to_char(sysdate,'hh24:mm:ss'),
      v_TraceId AS batchno,
      A.conttype AS conttype
    from MID_Address a
  join CR_Client_temp c
  on (a.clientno=c.clientNo or a.clientNo=c.originalclientno)
  );

  --CR_Policy(保单信息表数据提取)
  INSERT INTO CR_POLICY
  select contno,
         conttype,
         nvl(
         (select distinct d.TARGETCODE from mid_trans t,ldcodemapping d where m.contno=t.contno and t.transfromregion=d.BASICCODE and d.CODETYPE='aml_com_trcd' ),
         (select distinct d.TARGETCODE from cr_trans t,ldcodemapping d where m.contno=t.contno and t.transfromregion=d.BASICCODE and d.CODETYPE='aml_com_trcd')
         ),
         prem,
         amnt,
         paymethod,
         contstatus,
         effectivedate,
         expiredate,
         accountno,
         sumprem,
         mainyearprem,
         yearprem,
         agentcode,
         grpflag,
         source,
         inssubject,
         investflag,
         remainaccount,
         payperiod,
         salechnl,
         insuredpeoples,
         payinteval,
         othercontinfo,
         cashvalue,
         instfrom,
         policyaddress,
         makedate,
         maketime,
         BATCHNO,
         overprem,
         phone,
         primeyearprem,
         restpayperiod
       from MID_POLICY m;

  --CR_RISK(险种信息表数据提取)
  insert into CR_RISK(
         contno,
         riskcode,
         riskname,
         mainflag,
         risktype,
         insamount,
         prem,
         payinteval,
         effectivedate,
         expiredate,
         yearprem,
		     salechnl,
		     makedate,
		     maketime,
         BatchNo
  )
  select contno,
         riskcode,
         riskname,
         mainflag,
         risktype,
         insamount,
         prem,
         payinteval,
         effectivedate,
         expiredate,
         yearprem,
         salechnl,
         makedate,
         maketime,
         v_TraceId
       from MID_RISK;

  --cr_trans(交易记录表数据提取)
  insert into CR_TRANS
  select transno,
         contno,
         conttype,
         transmethod,
         transtype,
         transdate,
         transfromregion,
         transtoregion,
         curetype,
         payamt,
         payway,
         paymode,
         paytype,
         accbank,
         accno,
         accname,
         acctype,
         agentname,
         agentcardtype,
         agentothercardtype,
         agentcardid,
         agentnationality,
         opposidefinaname,
         opposidefinatype,
         opposidefinacode,
         opposidezipcode,
         tradecusname,
         tradecuscardtype,
         tradecusothercardtype,
         tradecuscardid,
         tradecusacctype,
         tradecusaccno,
         source,
         busimark,
         relationwithregion,
         useoffund,
         makedate,
         maketime,
         v_TraceId,
         accopentime,
         bankcardtype,
         bankcardothertype,
         bankcardnumber,
         rpmatchnotype,
         rpmatchnumber,
         noncountertrantype,
         noncounterothtrantype,
         noncountertrandevice,
         bankpaymenttrancode,
         foreigntranscode,
         crmb,
         cusd,
         remark,
         visitreason,
         isthirdaccount,
         nvl(requestdate,transdate)
       from MID_TRANS;

  --cr_transDetail(交易记录明细表数据提取)
  insert into CR_TRANSDETAIL
  select transno,
         contno,
         subno,
         notes,
         ext1,
         ext2,
         ext3,
         ext4,
         ext5,
         makedate,
         maketime,
         v_TraceId
       from MID_TRANSDETAIL;

--  --数据提取后清空MID表
  delete from  MID_Trans;
  delete from  MID_TransDetail;
  delete from  MID_Client;
  delete from  cr_client_temp;
  delete from  MID_Policy;
  delete from  MID_Risk;
  delete from  MID_Rel;
  delete from  MID_Address;
  delete from  lxassista;



  -- 执行完毕，更新轨迹状态
    update LLogTrace
     set dealstate  = '01',
       dealdesc   = '成功结束',
       InsertTime = to_date(startDate,'YYYY-MM-DD'),
       modifytime = to_date(startDate,'YYYY-MM-DD'),
       endtime = sysdate
     where traceid = v_TraceId;
     commit;

   -- 异常处理
    EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=errorCode||errorMsg;

  -- 将提取失败的信息记录到提取结果表中
  update LLogTrace
     set dealstate  = '02',
       dealdesc   = v_errormsg,
       InsertTime = to_date(startDate,'YYYY-MM-DD'),
       modifytime = to_date(startDate,'YYYY-MM-DD')
     where traceid = v_TraceId;
     delete from LXAssistA;
  commit;

end PROC_AML_EXTRAMID_ETA;
/

prompt
prompt Creating procedure PROC_AML_GB0103
prompt ==================================
prompt
create or replace procedure proc_aml_GB0103(i_baseLine in date, i_oprater in varchar2) is

    v_threshold_money number := getparavalue('GB0103', 'M1'); -- 阀值 累计保费金额
		v_threshold_month number := getparavalue('GB0103', 'D1'); -- 阀值 自然月
		v_threshold_count number := getparavalue('GB0103', 'N1'); -- 阀值 变更次数
		v_dealNo lxistrademain.dealno%type;												-- 交易编号(业务表)
		v_clientno cr_client.clientno%type;  -- 客户号

begin
  -- =============================================
  -- Rule:
  --     投保人3个月内(按变更申请日计算）三次以上（包括三次）变更受益人、联系人、法定代表人或者负责人，且该投保单位下所有有效保单的累计已交保费总额大于等于阀值，即被系统抓取，生成可疑交易；
  --     1) 同一投保单位变更多张保单受益人、联系人、法定代表人或者负责人相同的，将变更次数进行合并记为一次变更（按各同类变更项同一天结案的为一次）。
--          其中受益人的变更的统计口径为：增加受益人、删除受益人、修改受益人；变更联系人、法定代表人或者或者人的统计口径都为变更人的姓名
  --     2) 累计已交保费逻辑同7.1.1
  --     3) 抽取保单维度
  --        保单渠道：OLAS、IGM；
  --        前一天变更职业、签名、受益人或代理人生效保全的保单
  --     4) 报送数据格式同现有可疑交易格式
  --     5) 此条规则阀值为200万，实现为可配置形式
  -- parameter in: i_baseLine 交易日期
  --               i_oprater 操作人
  -- parameter out: none
  -- Author: xn
  -- Create date: 2020/01/06
  -- Changes log:
  --     Author     Date     Description
  -- =============================================

-- 找出当天发生变更投保单位下三个月内所有变更记录
  insert into LXAssistA(
    CustomerNo,
    TranId,
    PolicyNo,
    TranMoney,
    TimeArgs1,
    Trantime,
    args1,
    args2,
    args3,
    args4,
		args5)
      select
        r.clientno,
        t.transno,
        t.contno,
        (select p.sumprem from cr_policy p where p.contno = t.contno) as sumprem,
        t.requestdate,
        t.transdate,
        t.transtype,
        td.remark,
        td.ext1,
        td.ext2,
        'GB0103_1'
      from
        cr_trans t,cr_rel r,cr_transdetail td
      where
          t.contno=r.contno
      and t.contno=td.contno
      and t.transno=td.transno
      and exists(
          select 1
          from
              cr_trans tmp_t, cr_rel tmp_r, cr_transdetail tmp_td
          where
              tmp_r.clientno = r.clientno
          and tmp_t.contno = tmp_r.contno
          and tmp_t.contno = tmp_td.contno
          and tmp_t.transno = tmp_td.transno
          and tmp_r.custype = 'O'
          and tmp_t.conttype='1'
          and tmp_td.remark ='name'  
          and tmp_t.transtype  in('AC', 'BC')
          and trunc(tmp_t.transdate)=trunc(i_baseline)
          )
      and r.custype = 'O'
      and td.remark ='name'     
      and t.transtype  in('AC', 'BC')
      and isValidCont(t.contno) = 'yes'
      and t.conttype = '1'
      and trunc(t.transdate) > trunc(add_months(i_baseLine,v_threshold_month*(-1)))  --交易日日3个月前
      and trunc(t.transdate) < trunc(i_baseLine);   --交易日当日;

-- 判断累计次数和阈值
	 insert into LXAssistA(
			CustomerNo,
			TranId,
			PolicyNo,
			TimeArgs1,
			TranMoney,
			args2,
			args5,
			args4)
      select
        CustomerNo,
        TranId,
        PolicyNo,
				TimeArgs1,
				TranMoney,
				args2,
				'B0103_2',
				args4
      from
        LXAssistA a
      where (									-- 变更为同一职业受益人代理人只算一次，变更签名不去重
        nvl((
          select count(distinct tmp.args4)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and (tmp.args2 in('OwnOccupation','AGT01'))
          group by
            tmp.customerno
				),0)
				+
				nvl((
          select count(1)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and tmp.args2='editSignStyle'
          group by
            tmp.customerno
				),0)
        +
        nvl((
          select count(distinct tranid)
          from
            LXAssistA tmp
          where tmp.customerno = a.customerno
					and tmp.args2 like 'operateType%'
          group by
            tmp.customerno
				),0)>=v_threshold_count
     )
    and (				-- 计算名下所有有效保单累计已交保费总额
				select
					sum(nvl(policy.sumprem,0))
					from cr_rel rel,cr_policy policy
					where rel.contno=policy.contno
					and rel.clientno = a.customerno
					and isValidCont(rel.contno)='yes'
					and rel.custype='O')
				>=v_threshold_money
			order by a.customerno, a.timeargs1 desc;

-- 找出以每一条记录往后推三个月满足次数的交易作为记录头
	declare
       cursor baseInfo_sor is
          select
            CustomerNo,
            PolicyNo,
						TimeArgs1
          from
            LXAssistA a
          where
						(									-- 变更为同一职业受益人代理人只算一次，变更签名不去重
							nvl((
								select count(distinct tmp.args4)
								from
									LXAssistA tmp
								where tmp.customerno = a.customerno
								and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
								and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
								and (tmp.args2 in('OwnOccupation','变更代理人')or tmp.args2 like 'operateType%')
								and tmp.args5='B0103_2'
								group by
									tmp.customerno
							),0)
							+
							nvl((
								select count(tmp.args4)
								from
									LXAssistA tmp
								where tmp.customerno = a.customerno
								and trunc(tmp.TimeArgs1) >= trunc(a.TimeArgs1)
								and trunc(tmp.TimeArgs1) < trunc(add_months(a.TimeArgs1,v_threshold_month))
								and tmp.args2 ='editSignStyle'
								and tmp.args5='B0103_2'
								group by
									tmp.customerno
							),0)
              +
              nvl((
                  select count(distinct tranid)
                  from
                    LXAssistA tmp
                  where tmp.customerno = a.customerno
					        and tmp.args2 like 'operateType%'
                  group by
                    tmp.customerno
				      ),0)>=v_threshold_count
					 )
				and a.args5 = 'B0103_2'
				order by CustomerNo,TimeArgs1 desc;

     -- 定义游标变量
    c_clientno cr_client.clientno%type;									-- 客户号(用于保存交易日期内所有万能追加投资、新单保费定投的交易信息)
    c_contno cr_trans.contno%type;											-- 保单号
		c_requestdate cr_trans.requestdate%type;

begin
open baseInfo_sor;
    loop

      -- 获取当前游标值并赋值给变量
      fetch baseInfo_sor into c_clientno,c_contno,c_requestdate;
      exit when baseInfo_sor%notfound;  -- 游标循环出口

			-- 以记录头查找三个月内的记录
			declare
				cursor baseInfo_sor_date is
					select *
					from lxassista
					where trunc(TimeArgs1) >= trunc(c_requestdate)
					and trunc(TimeArgs1) < trunc(add_months(c_requestdate,v_threshold_month))
					and args5 = 'B0103_2' and customerno = c_clientno;

			c_row baseInfo_sor_date%rowtype;

		begin
		for c_row in baseInfo_sor_date loop
      -- 当天发生的触发规则交易，插入到主表中，明细评估指标为1
      if v_clientno is null or c_clientno <> v_clientno then
      v_dealNo:=NEXTVAL2('AMLDEALNO', 'SN');	--获取交易编号(业务表)

      -- 插入可疑交易信息主表-临时表 Lxistrademain_Temp
      PROC_AML_INS_LXISTRADEMAIN(v_dealNo, c_clientno,c_contno,i_oprater, 'SB0103', i_baseLine);
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'1');
      v_clientno := c_clientno; -- 更新可疑主体的客户号

      else
      -- 插入可疑交易明细信息-临时表 Lxistradedetail_Temp
      PROC_AML_INS_LXISTRADEDETAIL(v_dealNo, c_row.policyno, c_row.tranid,'');

      end if;

			-- 插入可疑交易合同信息-临时表 Lxistradecont_Temp
			PROC_AML_INS_LXISTRADECONT(v_dealNo, c_row.customerno, c_row.policyno);

			-- 插入可疑交易被保人信息-临时表 Lxistradeinsured_Temp
			PROC_AML_INS_LXISTRADEINSURED(v_dealNo, c_row.policyno);

			-- 插入可疑交易受益人信息-临时表 Lxistradebnf_Temp
			PROC_AML_INS_LXISTRADEBNF(v_dealNo, c_row.policyno);

			-- 插入交易主体联系方式-临时表 Lxaddress_Temp
			PROC_AML_INS_LXADDRESS(v_dealNo, c_row.customerno);
		end loop;

		end;

    end loop;
    close baseInfo_sor;
  end;

  delete from LXAssistA where args5 in ('B0103_1','B0103_2');
end proc_aml_GB0103;
/

prompt
prompt Creating procedure PROC_AML_INSERTCR
prompt ====================================
prompt
create or replace procedure proc_aml_insertCR(i_count in number)
is

begin
  -- =============================================
  -- 向平台表中插入大量数据
  -- parameter in: i_count 要插入的数据条数
  -- parameter out: none
  -- Author: zhouqk
  -- Create date: 2019/06/17
  -- Changes log:
  --     Author     Date        Description
  --     zhouqk   2019/06/17      基板
  -- ============================================

  declare
     v_first_num number;
     v_end_num number;

  begin

    for v_count in 1..i_count loop
      
            v_first_num:=nextval2('LDPARA','SN');

            insert into cr_client select

            nextval2('LDPARA','SN'),

            OriginalClientNo,Source,Name,Birthday,Age,Sex,Grade,CardType,OtherCardType,CardID,CardExpireDate,ClientType,WorkPhone,FamilyPhone,Telephone,Occupation,BusinessType,Income,GrpName,Address,OtherClientInfo,ZipCode,Nationality,ComCode,ContType,BusinessLicenseNo,OrgComCode,TaxRegistCertNo,LegalPerson,LegalPersonCardType,OtherLPCardType,LegalPersonCardID,LinkMan,ComRegistArea,ComRegistType,ComBusinessArea,ComBusinessScope,AppntNum,ComStaffSize,GrpNature,FoundDate,HolderKey,HolderName,HolderCardType,OtherHolderCardType,HolderCardID,HolderOccupation,HolderRadio,HolderOtherInfo,RelaSpecArea,FATCTRY,CountryCode,SuspiciousCode,fundsource,MakeDate,MakeTime,BatchNo,IDverifystatus,IsFATCAandCRS from cr_client;

            v_end_num:=nextval2('LDPARA','SN');


            for i_no in (v_first_num+1)..(v_end_num-1) loop
              --  客户号，保单号和交易编号都是i_no   此处待商议
              
              insert into CR_Policy(ContNo,ContType,LocId,Prem,Amnt,PayMethod,ContStatus,Effectivedate,Expiredate,AccountNo,SumPrem,MainYearPrem,YearPrem,AgentCode,GrpFlag,Source,InsSubject,InvestFlag,RemainAccount,PayPeriod,SaleChnl,InsuredPeoples,PayInteval,OtherContInfo,CashValue,INSTFROM,PolicyAddress,Makedate,MakeTime,BatchNo,OverPrem,phone,PrimeYearPrem)
              values(i_no,'1','N000001','100000','200000','01','20',to_date('2018-03-22','yyyy-mm-dd'),to_date('2020-03-22','yyyy-mm-dd'),'6228273156301755774','100000','','','','','1','人身','','','0','05','1','0','@N','',to_date('2018-03-22','yyyy-mm-dd'),'',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','20190521151031','','16738490927','100000');
             
              insert into CR_Rel(ContNo,ClientNo,CusType,RelaAppnt,BatchNo,Makedate,MakeTime,PolicyPhone,UseCardType,UseOtherCardType,UseCardID)
              values(i_no,i_no,'O','1','20190521151031',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','16738490927','01','01','310112198001010439');
           
              insert into CR_Rel(ContNo,ClientNo,CusType,RelaAppnt,BatchNo,Makedate,MakeTime,PolicyPhone,UseCardType,UseOtherCardType,UseCardID)
              values(i_no,i_no,'B','1','20190521151031',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','16738490927','01','01','310112198001010439');

              insert into CR_Rel(ContNo,ClientNo,CusType,RelaAppnt,BatchNo,Makedate,MakeTime,PolicyPhone,UseCardType,UseOtherCardType,UseCardID)
              values(i_no,i_no,'I','1','20190521151031',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','16738490927','01','01','310112198001010439');
             
              insert into CR_Risk(ContNo,RiskCode,RiskName,MainFlag,RiskType,InsAmount,Prem,PayInteval,Effectivedate,Expiredate,YearPrem,SaleChnl,Makedate,MakeTime,BatchNo)
              values(i_no,'20GAA102886A','金瑞保证年金养老保险-品种A','00','01','200000','100000','0',to_date('2018-03-22','yyyy-mm-dd'),to_date('2020-03-22','yyyy-mm-dd'),'','01',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','20190521151031');
              
              insert into CR_Trans(TransNo,ContNo,ContType,TransMethod,TransType,Transdate,TransFromRegion,TransToRegion,CureType,PayAmt,PayWay,PayMode,PayType,AccBank,AccNo,AccName,AccType,AgentName,AgentCardType,AgentOtherCardType,AgentCardID,AgentNationality,OpposideFinaName,OpposideFinaType,OpposideFinaCode,OpposideZipCode,TradeCusName,TradeCusCardType,TradeCusOtherCardType,TradeCusCardID,TradeCusAccType,TradeCusAccNo,Source,BusiMark,RelationWithRegion,UseOfFund,AccOpenTime,BankCardType,BankCardOtherType,BankCardnumber,RPMatchNoType,RPMatchNumber,NonCounterTranType,NonCounterOthTranType,NonCounterTranDevice,BankPaymentTranCode,ForeignTransCode,CRMB,CUSD,Remark,Makedate,MakeTime,BatchNo,visitReason,IsThirdAccount,RequestDate)
              values(i_no,i_no,'1','','AA001',to_date('2018/6/15','yyyy-MM-dd HH24:mi:ss'),'CHN310106','CHN310106','RMB','100000','01','02','','中国工商银行','6212260443425','苏力','@N','@N','@N','@N','@N','CN','@N','@N','@N','@N','@N','@N','@N','@N','@N','@N','1','FYA07001001','@N','@N',to_date('','yyyy-mm-dd'),'@N','@N','@N','@N','@N','@N','@N','@N','@N','@N','','','@N',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','20190521151031','','0',to_date('2018-5-1','yyyy-mm-dd'));
              
              insert into CR_TransDetail(TransNo,ContNo,subno,remark,ext1,ext2,ext3,ext4,ext5,Makedate,MakeTime,BatchNo)
              values(i_no,i_no,'0018','','','','','','',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','20190521151031');
              
              insert into CR_Address(ClientNo,ListNo,ClientType,LinkNumber,Adress,CusOthContact,Nationality,Country,MakeDate,MakeTime,BatchNo,ContType)
              values(i_no,'20','03','16738490927','上海市静安区','16738490927','CN','',to_date('2018-5-1','yyyy-mm-dd'),'15:10:31','20190521151031','1');
              
              insert into lxblacklist(seqNo,recordType,nameType,name,ename,sex,birthday,idNumber,nationality,type,Description1,Description2,Description3,dataSource,risktype,risklevel,isactive,creator,operator,makedate,maketime,modifydate,modifytime)
              values(i_no,'01','','张三','zh','2',to_date('1980-1-1','yyyy-mm-dd'),'110101198903230044','CHN','1','1','1','','21','','','0','urp','aml',to_date('2019-03-13','yyyy-mm-dd'),'15:10:31',to_date('2019-03-13','yyyy-mm-dd'),'15:10:31');
              
              insert into lxriskinfo(seqno,recordtype,code,name,ename,sex,birthday,idNumber,nationality,risktype,risklevel,isActive,creator,operator,makedate,maketime,modifydate,modifytime)
              values(i_no,'01','SA0802_01','胡为','huwei','1',to_date('1994/10/04','yyyy-mm-dd'),'310106199410040038','CHN','','4','01','zhouqk','aml',to_date('2019/4/28','yyyy-mm-dd'),'13:25:11',to_date('2019/4/28','yyyy-mm-dd'),'13:25:11');

            end loop; 


    end loop;



  end;
end proc_aml_insertCR;
/

prompt
prompt Creating procedure PROC_AML_INS_G_LXISTRADEBNF
prompt ==============================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_INS_G_LXISTRADEBNF (
	i_dealno in NUMBER,
	i_contno in VARCHAR2
) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lLXISTRADEBNF_TEMP表
  -- parameter in: i_dealno 交易编号(业务表)
  --               i_contno 保单号
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/12/31  初版
  -- =============================================

  insert into LXISTRADEBNF_TEMP(
    serialno,
		DealNo,
		CSNM,
		InsuredNo,
		BnfNo,
		BNNM,
		BITP,
		OITP,
		BNID,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime)
(
			SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_contno AS CSNM,
			c.clientno AS InsuredNo,
			c.clientno AS BnfNo,
			c.NAME AS BNNM,
			c.cardtype AS BITP,
			nvl(c .OtherCardType, '@N') AS OITP,
      nvl((case c.cardtype when '营业执照号' then c.BUSINESSLICENSENO when '组织代码证号' then c.ORGCOMCODE  when '税务登记号' then c.TAXREGISTCERTNO else c.cardid end),'@N') as BNID,
			NULL AS DataBatchNo,
			sysdate AS MakeDate,
			to_char(sysdate,'HH:mm:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime
			FROM
					cr_client c,
					cr_rel r
			WHERE
					c.clientno = r.clientno
			AND r.custype = 'B'
			and r.contno=i_contno

  );
end PROC_AML_INS_G_LXISTRADEBNF;
/

prompt
prompt Creating procedure PROC_AML_INS_G_LXISTRADEDETAIL
prompt =================================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_INS_G_LXISTRADEDETAIL (
i_dealno in NUMBER,
	i_contno in VARCHAR2,
	i_transno in VARCHAR2,
	i_triggerflag in VARCHAR2
	) is
begin
  -- =============================================
  -- Description: 根据规则筛选结果更新LXISTRADEDETAIL_TEMP表
  -- parameter in: i_dealno   交易编号(业务表)
  --               i_ocontno  保单号
  --               i_transno  交易编号(平台表)
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     zhouqk    2019/12/31  初版
  -- =============================================


  insert into LXISTRADEDETAIL_TEMP(
    serialno,
    DealNo,
		TICD,
		ICNM,
		TSTM,
		TRCD,
		ITTP,
		CRTP,
		CRAT,
		CRDR,
		CSTP,
		CAOI,
		TCAN,
		ROTF,
		DataState,
		DataBatchNo,
		MakeDate,
		MakeTime,
		ModifyDate,
		ModifyTime,
		TRIGGERFLAG)
  (
    SELECT
      getSerialno(sysdate) as serialno,
			LPAD(i_dealno,20,'0') AS DealNo,
			i_transno AS TICD,
			i_contno AS ICNM,
			to_char(t.transdate,'yyyymmddHHmmss') AS TSTM,
			t.transfromregion AS TRCD,
			t.transtype AS ITTP,
			t.curetype AS CRTP,
			t.payamt AS CRAT,
			T.PAYWAY AS CRDR,
			T.PAYMODE AS CSTP,
			nvl(t.accbank,'@N') AS CAOI,
			nvl(t.accno,'@N') AS TCAN,
			nvl(t.remark, '@N') AS ROTF,
      'A01' as DataState,
			NULL  AS DataBatchNo,
		  to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') AS MakeDate,
			to_char(sysdate,'HH24:mi:ss') AS MakeTime,
			NULL AS ModifyDate,
			NULL AS ModifyTime,
			i_triggerflag AS TRIGGERFLAG
		from
			cr_trans t
		where
				t.contno = i_contno
		and t.transno = i_transno
  );

end PROC_AML_INS_G_LXISTRADEDETAIL;
/

prompt
prompt Creating procedure PROC_AML_INS_G_LXISTRADEMAIN
prompt ===============================================
prompt
CREATE OR REPLACE PROCEDURE PROC_AML_INS_G_LXISTRADEMAIN (
	i_dealno in NUMBER,
  i_clientno in varchar2,
  i_contno in varchar2,
  i_operator in varchar2,
  i_stcr in varchar2 ,
  i_baseLine in DATE) is

begin
  -- =============================================
  -- Description: 根据规则筛选结果更新lxistrademain_temp表
  -- parameter in: i_clientno 客户号
  --               i_dealno   交易编号
	--               i_operator 操作人
  --               i_stcr     可疑交易特征编码
	--               i_baseLine 日期基准
  -- parameter out: none
  -- Author: xn
  -- Create date: 2019/12/31
  -- Changes log:
  --     Author     Date     Description
  --     xn    2019/12/31  初版
  -- =============================================

  insert into lxistrademain_temp(
    serialno,
    dealno, -- 交易编号
    rpnc,   -- 上报网点代码
    detr,   -- 可疑交易报告紧急程度（01-非特别紧急, 02-特别紧急）
    torp,   -- 报送次数标志
    dorp,   -- 报送方向（01-报告中国反洗钱监测分析中心）
    odrp,   -- 其他报送方向
    tptr,   -- 可疑交易报告触发点
    otpr,   -- 其他可疑交易报告触发点
    stcb,   -- 资金交易及客户行为情况
    aosp,   -- 疑点分析
    stcr,   -- 可疑交易特征
    csnm,   -- 客户号
    senm,   -- 可疑主体姓名/名称
    setp,   -- 可疑主体身份证件/证明文件类型
    oitp,   -- 其他身份证件/证明文件类型
    seid,   -- 可疑主体身份证件/证明文件号码
    sevc,   -- 客户职业或行业
    srnm,   -- 可疑主体法定代表人姓名
    srit,   -- 可疑主体法定代表人身份证件类型
    orit,   -- 可疑主体法定代表人其他身份证件/证明文件类型
    srid,   -- 可疑主体法定代表人身份证件号码
    scnm,   -- 可疑主体控股股东或实际控制人名称
    scit,   -- 可疑主体控股股东或实际控制人身份证件/证明文件类型
    ocit,   -- 可疑主体控股股东或实际控制人其他身份证件/证明文件类型
    scid,   -- 可疑主体控股股东或实际控制人身份证件/证明文件号码
    strs,   -- 补充交易标识
    datastate, -- 数据状态
    filename,  -- 附件名称
    filepath,  -- 附件路径
    rpnm,      -- 填报人
    operator,  -- 操作员
    managecom, -- 管理机构
    conttype,  -- 保险类型（01-个单, 02-团单）
    notes,     -- 备注
		baseline,       -- 日期基准
    getdatamethod,  -- 数据获取方式（01-系统抓取,02-手工录入）
    nextfiletype,   -- 下次上报报文类型
    nextreferfileno,-- 下次上报报文文件名相关联的原文件编码
    nextpackagetype,-- 下次上报报文包类型
    databatchno,    -- 数据批次号
    makedate,       -- 入库时间
    maketime,       -- 入库日期
    modifydate,     -- 最后更新日期
    modifytime,			-- 最后更新时间
		judgmentdate,   -- 终审日期
    ORXN,           -- 接续报告首次上报成功的报文名称
		ReportSuccessDate)-- 上报成功日期
(
    select
      getSerialno(sysdate) as serialno,
      LPAD(i_dealno,20,'0') as dealno,
      '@N' as rpnc,
      '01' as detr,  -- 报告紧急程度（01-非特别紧急）
      '1' as torp,
      '01' as dorp,  -- 报送方向（01-报告中国反洗钱监测分析中心）
      '@N' as odrp,
      '01' as tptr,  -- 可疑交易报告触发点（01-模型筛选）
      '@N' as otpr,
      '' as stcb,
      '' as aosp,
      i_stcr as stcr,
      c.clientno as csnm,
      c.name as senm,
      nvl(c.cardtype,'@N') as setp,
      nvl(c.othercardtype,'@N') as oitp,
      --团单是取 营业执照号或组织代码证号或税务登记号
      nvl((case c.cardtype when '营业执照号' then c.BUSINESSLICENSENO when '组织代码证号' then c.ORGCOMCODE  when '税务登记号' then c.TAXREGISTCERTNO else c.cardid end),'@N') as seid,
      nvl(c.occupation,'@N') as sevc,
      nvl(c.legalperson,'@N') as srnm,
      nvl(c.legalpersoncardtype,'@N') as srit,
      nvl(c.otherlpcardtype,'@N') as orit,
      nvl(c.legalpersoncardid,'@N') as srid,
      nvl(c.holdername,'@N') as scnm,
      nvl(c.holdercardtype,'@N') as scit,
      nvl(c.otherholdercardtype,'@N') as ocit,
      nvl(c.holdercardid,'@N') as scid,
      '@N' as strs,
      'A01' as datastate,
      '' as filename,
      '' as filepath,
      (select username from lduser where usercode = i_operator) as rpnm,
      i_operator as operator,
      (select locid from cr_policy where contno=i_contno) as managecom,
      c.conttype as conttype,
      '' as notes,
      i_baseLine as baseline,
      '01' as getdatamethod,  -- 数据获取方式（01-系统抓取）
      '' as nextfiletype,
      '' as nextreferfileno,
      '' as nextpackagetype,
      null as databatchno,
      to_date(to_char(sysdate,'yyyy-mm-dd'),'yyyy-mm-dd') as makedate,
      to_char(sysdate,'hh24:mi:ss') as maketime,
      null as modifydate,  -- 最后更新时间
      null as modifytime,
			null as judgmentdate,--终审日期
      null as ORXN,        -- 接续报告首次上报成功的报文名称
			null as ReportSuccessDate--上报成功日期
    from
      cr_client c
    where
     c.clientno = i_clientno
  );

end PROC_AML_INS_G_LXISTRADEMAIN;
/

prompt
prompt Creating procedure PROC_AML_RULE
prompt ================================
prompt
create or replace procedure proc_aml_rule(i_baseLine in date,i_oprater in VARCHAR2) is
begin
  -- =============================================
  -- Description:  调用大额/可疑各筛选规则相关处理
  -- parameter in: i_baseLine 交易日期
  --               i_oprater  操作人
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/02/22
  -- Changes log:
  --     Author        Date      Description
  --     xuexc      2019/02/27      初版
  --     zhouqk     2019/05/27   添加条件将B0300作为每月15号运行一次
  -- =============================================

  --proc_aml_0501(i_baseLine,i_oprater);
  aml_0501(i_baseLine,i_oprater);

  PROC_AML_A0101_TEST(i_baseLine,i_oprater);

  PROC_AML_A0102_TEST(i_baseLine,i_oprater);

  PROC_AML_A0103_TEST(i_baseLine,i_oprater);

  PROC_AML_A0104_TEST(i_baseLine,i_oprater);

  proc_aml_A0200(i_baseLine,i_oprater);

  proc_aml_A0300(i_baseLine,i_oprater);

  proc_aml_A0400(i_baseLine,i_oprater);

  proc_aml_A0500(i_baseLine,i_oprater);

  proc_aml_A0601(i_baseLine,i_oprater);

  proc_aml_A0602(i_baseLine,i_oprater);

  proc_aml_A0700(i_baseLine,i_oprater);

  proc_aml_A0801(i_baseLine,i_oprater);

  proc_aml_A0802(i_baseLine,i_oprater);

  proc_aml_A0900(i_baseLine,i_oprater);

  proc_aml_B0101(i_baseLine,i_oprater);

  proc_aml_B0102(i_baseLine,i_oprater);

  proc_aml_B0103(i_baseLine,i_oprater);

  proc_aml_B0200(i_baseLine,i_oprater);

  --B0300规则每月15号跑一次
  if to_char(i_baseline,'dd')='15'then
     proc_aml_B0300(i_baseLine,i_oprater);
  end if;

  proc_aml_B0400(i_baseLine,i_oprater);

  proc_aml_C0101(i_baseLine,i_oprater);

  proc_aml_C0102(i_baseLine,i_oprater);

  proc_aml_C0103(i_baseLine,i_oprater);

  proc_aml_C0201(i_baseLine,i_oprater);

  proc_aml_C0202(i_baseLine,i_oprater);

  proc_aml_C0203(i_baseLine,i_oprater);

  proc_aml_C0300(i_baseLine,i_oprater);

  proc_aml_C0400(i_baseLine,i_oprater);

  proc_aml_C0500(i_baseLine,i_oprater);

  proc_aml_C0600(i_baseLine,i_oprater);

  proc_aml_C0700(i_baseLine,i_oprater);

  proc_aml_C0801(i_baseLine,i_oprater);

  proc_aml_C0802(i_baseLine,i_oprater);

  proc_aml_C0900(i_baseLine,i_oprater);

  proc_aml_C1000(i_baseLine,i_oprater);

  proc_aml_C1100(i_baseLine,i_oprater);

  proc_aml_C1200(i_baseLine,i_oprater);

  proc_aml_C1301(i_baseLine,i_oprater);

  --proc_aml_C1302(i_baseLine,i_oprater);
  aml_C1302(i_baseLine,i_oprater);

  --proc_aml_C1303(i_baseLine,i_oprater);
  aml_C1303(i_baseLine,i_oprater);

  --proc_aml_C1304(i_baseLine,i_oprater);
  aml_C1304(i_baseLine,i_oprater);

  proc_aml_C1305(i_baseLine,i_oprater);
  
  --新增规则5
  --AML_XX0005(i_baseLine,i_oprater);
  proc_aml_d0600(i_baseLine,i_oprater);
  
  --新规则7 
  --aml_xx0007(i_baseLine,i_oprater);
  proc_aml_d0701(i_baseLine,i_oprater);
  -- 新规则 8
  --aml_xx0008(i_baseLine,i_oprater);
  proc_aml_d0702(i_baseLine,i_oprater);

  --新规则 13
  --aml_xx0013(i_baseLine,i_oprater);
  proc_aml_d0703(i_baseLine,i_oprater);
  
  --新规则 14
  --aml_xx0014(i_baseLine,i_oprater);
  proc_aml_d0800(i_baseLine,i_oprater);
end proc_aml_rule;
/

prompt
prompt Creating procedure PROC_AML_MAIN
prompt ================================
prompt
create or replace procedure proc_aml_main(i_startDate in varchar, i_endDate in varchar,i_oprater in varchar) is
  v_dataBatchNo varchar2(28);
  v_startDate date := to_date(i_startDate, 'YYYY-MM-DD');
  v_endDate date := to_date(i_endDate, 'YYYY-MM-DD');
  v_baseLine date := v_startDate;

  v_errormsg ldbatchlog.errormsg%type;
  errorCode number; --异常代号
  errorMsg varchar2(1000);--异常信息

begin
  -- =============================================
  -- Description:	大额/可疑筛选规则抓取满足大额/可疑条件的交易记录
  --              并将抓取的交易记录保存至大额/可疑业务表中
  -- parameter in: i_startDate 交易开始日期
  --               i_endDate 交易结束日期
  -- parameter out: none
  -- Author: xuexc
  -- Create date: 2019/02/22
  -- Changes log:
  --     Author     Date     Description
  --     xuexc   2019/02/27  初版
  --     hujx    2019/03/01  1.获取v_dataBatchNo2调用时增加参数
  -- ============================================
  -- 清空大额/可疑业务临时表
  delete from Lxihtrademain_Temp;   -- 大额交易主表-临时表
  delete from Lxihtradedetail_Temp; -- 大额交易明细表-临时表
  delete from Lxistrademain_Temp;   -- 可疑交易信息主表-临时表
  delete from Lxistradedetail_Temp; -- 可疑交易明细信息-临时表
  delete from Lxistradecont_Temp;   -- 可疑交易合同信息-临时表
  delete from Lxistradeinsured_Temp;-- 可疑交易被保人信息-临时表
  delete from Lxistradebnf_Temp;    -- 可疑交易受益人信息-临时表
  delete from Lxaddress_Temp;       -- 交易主体联系方式-临时表

  -- 使用sequences获取最新的dataBatchNo
	select CONCAT(to_char(sysdate,'yyyymmdd'),LPAD(SEQ_dataBatchNo.nextval,20,'0')) into v_dataBatchNo from dual;

  loop
    begin
      proc_aml_rule(v_baseLine,i_oprater);
			v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;


  -- 更新大额/可疑业务临时表中的批次号
  update Lxihtrademain_Temp set Databatchno = v_dataBatchNo;   -- 大额交易主表-临时表
  update Lxihtradedetail_Temp set Databatchno = v_dataBatchNo; -- 大额交易明细表-临时表
  update Lxistrademain_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易信息主表-临时表
  update Lxistradedetail_Temp set Databatchno = v_dataBatchNo; -- 可疑交易明细信息-临时表
  update Lxistradecont_Temp set Databatchno = v_dataBatchNo;   -- 可疑交易合同信息-临时表
  update Lxistradeinsured_Temp set Databatchno = v_dataBatchNo;-- 可疑交易被保人信息-临时表
  update Lxistradebnf_Temp set Databatchno = v_dataBatchNo;    -- 可疑交易受益人信息-临时表
  update Lxaddress_Temp set Databatchno = v_dataBatchNo;       -- 交易主体联系方式-临时表



	--将临时表转码
	proc_aml_mappingcode(v_dataBatchNo);

	--接续报告不需要转码，单独处理
	-- 重置v_baseLine
	v_baseLine := v_startDate;
	loop
    begin
      proc_aml_D0100(v_baseLine,i_oprater);
			v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;

	-- 更新可疑业务临时表中的批次号
  update Lxistrademain_Temp set Databatchno = v_dataBatchNo where Databatchno is null;   -- 可疑交易信息主表-临时表
  update Lxistradedetail_Temp set Databatchno = v_dataBatchNo where Databatchno is null; -- 可疑交易明细信息-临时表
  update Lxistradecont_Temp set Databatchno = v_dataBatchNo where Databatchno is null;   -- 可疑交易合同信息-临时表
  update Lxistradeinsured_Temp set Databatchno = v_dataBatchNo where Databatchno is null;-- 可疑交易被保人信息-临时表
  update Lxistradebnf_Temp set Databatchno = v_dataBatchNo where Databatchno is null;    -- 可疑交易受益人信息-临时表
  update Lxaddress_Temp set Databatchno = v_dataBatchNo where Databatchno is null;       -- 交易主体联系方式-临时表

	-- 实现重提功能：判断业务表中是否存储已经提取的数据，如果业务表存在则删除临时表里面的数据，保留业务表里面的数据
	-- 重置v_baseLine
	v_baseLine := v_startDate;
	loop
    begin
      PROC_AML_DELETE_LXIHTRADE(v_baseLine);											 --删除大额业务表里面的数据
			PROC_AML_DELETE_LXISTRADE(v_baseLine);											 --删除可疑业务表里面的数据
			v_baseLine := v_baseLine + 1;
    end;
    exit when (v_endDate - v_baseLine) < 0;
  end loop;

  -- 插入轨迹表(从中间表统计数据插入到轨迹表中，此时中间表数据没有去重，但是主表的数据无需去重)
  proc_aml_dealoperatordata(v_dataBatchNo);

  -- 将大额/可疑业务临时表中数据迁移到业务表（去重）
  proc_aml_data_migration(v_dataBatchNo);

	-- 查找业务表中已经插入的数据记录到提取日志表中
  PROC_AML_INS_LX_LXCALLOG(i_oprater,v_dataBatchNo);

	-- 将成功提取的数据记录到提取结果表中
	PROC_AML_INS_LDBATCHLOG(v_dataBatchNo,'IS','01',trunc(sysdate),to_char(v_baseLine-1,'yyyy-mm-dd')||'个险规则提取成功！');

  commit;

--异常处理
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;

  errorCode:= SQLCODE;
  errorMsg:= SUBSTR(SQLERRM, 1, 200);
  v_errormsg:=to_char((v_baseLine),'yyyy-mm-dd')||errorCode||errorMsg;

	-- 将提取失败的信息记录到提取结果表中
	PROC_AML_INS_LX_LDBATCHLOG(v_dataBatchNo,'00',trunc(sysdate),v_errormsg);
  commit;


end proc_aml_main;
/


prompt Done
spool off
set define on
