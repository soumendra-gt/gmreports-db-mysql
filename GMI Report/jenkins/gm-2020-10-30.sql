USE gm_reports;

ALTER TABLE cdr_data_details_vw MODIFY COLUMN RECORD_OPENING_TIME datetime(6);
ALTER TABLE cdr_data_details_vw MODIFY COLUMN START_TIME datetime(6);
ALTER TABLE cdr_data_details_vw MODIFY COLUMN STOP_TIME datetime(6);
ALTER TABLE cdr_sms_details MODIFY COLUMN SENT_TIME datetime(6);
ALTER TABLE cdr_sms_details MODIFY COLUMN FINAL_TIME datetime(6);
ALTER TABLE cdr_voice_completed MODIFY COLUMN IAMRECDAT datetime(6);
ALTER TABLE cdr_voice_completed MODIFY COLUMN ANMRECDAT datetime(6);
ALTER TABLE cdr_voice_incompleted MODIFY COLUMN IAMRECDAT datetime(6);
ALTER TABLE cdr_voice_incompleted MODIFY COLUMN ANMRECDAT datetime(6);


DROP PROCEDURE IF EXISTS gm_data_report;
DELIMITER $$
CREATE PROCEDURE `gm_data_report`(
	IN `in_start_date` varchar(50),
	IN `in_end_date` varchar(50),
	IN `in_account_id` VARCHAR(50)
)
    COMMENT 'gm_data_report_new'
BEGIN
  -- **********************************************************************
  -- Procedure: gm_data_report_new
  -- Author: Parul Shrivastava
  -- Date: Nov 1, 2019
  
   -- Modified by : Rahul Panwar
  -- Date: JUne, 2020 
  -- Inputs: in_start_date,in_end_date
  -- Output: This procedure is used to returns cdr data on the basis of 
  -- the served imsi and STOP_TIME
  
  -- Description: Procedure returns the report genarted 
  -- **********************************************************************

	-- Declaration of the variables 
	DECLARE date_duration VARCHAR(50);
	DECLARE start_date varchar(50);
	
   -- typecasting for start_date
   SET start_date:= CAST(in_start_date AS DATEtime);
   
   -- Using 2020 year as a reference year for calculating the billing cycle
	SET @TEMP_BILLING_CYCLE_DATE = (SELECT YEAR(in_start_date)+MONTH(in_start_date)-2020);

	-- preparing billing dates accordign to current date month start date and end date 
    SET date_duration= LAST_DAY(CONVERT( in_start_date, DATE ));
    SET @temp_date = DATE_SUB(in_start_date,INTERVAL DAYOFMONTH(in_start_date)-1 DAY);
	-- select concat(@temp_date ,' - ',date_duration);
	 
	-- prepare the data report with the multiple tables joins 

   Set @temp_start_date=concat(in_start_date ,' 00:00:00');
   --  Set @recored_count=(select count(*) from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('2020-06-15 06:29:00'));
   Set @IMSI_count=(select count(distinct IMSI) from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date(@temp_start_date));
   -- select @recored_count;
   -- select * from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('2020-06-15 06:29:00') limit 1 offset 3;
 
   -- getting wholshale plan history
	  DROP TEMPORARY TABLE IF EXISTS temp_wholesale_plan_history;
    CREATE TEMPORARY TABLE  temp_wholesale_plan_history
    (imsi varchar(20),
    start_date datetime,
    end_date datetime,
	 plan varchar(20));
 -- DECLARE  temp_start_date datetime;
 
  -- loop distinct imsi list.
   SET @j =0;
   loop_loop_1: LOOP
   Set @temp_start_date=concat(in_start_date ,' 00:00:00'); 
     IF @j+1 <= @IMSI_count THEN
--       SELECT @i,CAST(@i AS INT);
     -- SET @sql_statement = concat("insert into temp_wholesale_plan_history  select imsi, '",@temp_start_date,"' as start_date,CREATE_DATE as end_date,new_Value as plan  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') order by CREATE_DATE limit 1 offset ", @i,";");
     -- prepare stmt1 from @sql_statement;
     --  execute stmt1;
      -- deallocate prepare stmt1;
      
      -- prepare statement for getting history
      SET @sql_statement = concat("set @temp_imsi_list=(select Distinct IMSI  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') order by CREATE_DATE limit 1 offset ", @j,");");
      prepare stmt1 from @sql_statement;
       execute stmt1;
      deallocate prepare stmt1;
      SET @j = @j + 1;
     -- select @temp_imsi_list;
     --  Set @temp_start_date=concat(in_start_date ,' 00:00:00');    
   Set @recored_count=(select count(*) from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date(@temp_start_date)  and IMSI = @temp_imsi_list);
 --  select @recored_count;
  
   -- loop using for n number of recored's
   SET @i =0;
   loop_loop: LOOP
     IF @i+1 <= @recored_count THEN
     
       IF @i+2 <= @recored_count THEN
        SET @sql_statement = concat("set @temp_end_date=(select  CREATE_DATE  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') and IMSI ='",@temp_imsi_list,"'  order by CREATE_DATE limit 1 offset ", @i+1,");");
    -- select @sql_statement;
      prepare stmt1 from @sql_statement;
      execute stmt1;
      deallocate prepare stmt1;
      else 
      set @temp_end_date=concat(in_start_date,' 23:59:59');
      end if;
      -- SELECT @i,CAST(@i AS INT);
      -- SET @sql_statement = concat("insert into temp_wholesale_plan_history  select imsi, '",@temp_start_date,"' as start_date,CREATE_DATE as end_date,new_Value as plan  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') and IMSI ='",@temp_imsi_list,"' order by CREATE_DATE limit 1 offset ", @i,";");
      SET @sql_statement = concat("insert into temp_wholesale_plan_history  select imsi, CREATE_DATE as start_date,'",@temp_end_date,"' as end_date,new_Value as plan  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') and IMSI ='",@temp_imsi_list,"' order by CREATE_DATE limit 1 offset ", @i,";");
      prepare stmt1 from @sql_statement;
       execute stmt1;
      deallocate prepare stmt1;
	   SET @sql_statement = concat("set @temp_start_date=(select  date_add(CREATE_DATE, interval 1 second)  from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('",in_start_date,"') and IMSI ='",@temp_imsi_list,"'  order by CREATE_DATE limit 1 offset ", @i,");");
    -- select @sql_statement;
      prepare stmt1 from @sql_statement;
    execute stmt1;
      deallocate prepare stmt1;
     SET @i = @i + 1;
     -- select @sql_statement ;
       -- select * from wholesale_plan_history where date(wholesale_plan_history.CREATE_DATE)=date('2020-06-15 06:29:00') limit 1 offset CAST(@i AS INT);
       ITERATE loop_loop;
     END IF;
     LEAVE loop_loop;
   END LOOP loop_loop;
       
	
		  ITERATE loop_loop_1;
     END IF;
     LEAVE loop_loop_1;
   END LOOP loop_loop_1;



	
	DROP TABLE IF EXISTS temp_cdr_data_return_table;
    CREATE TEMPORARY TABLE temp_cdr_data_return_table
	SELECT 
	report_metadata.ICCID AS ICCID,
	report_metadata.MSISDN AS MSISDN,
	report_metadata.IMSI AS IMSI,
-- 	report_metadata.ACCOUNT_NAME AS SUPPLIER_ACCOUNT_ID ,
   gm_country_code_mapping.country_Code AS SUPPLIER_ACCOUNT_ID ,
	@TEMP_BILLING_CYCLE_DATE AS BILLING_CYCLE_DATE,
	-- '5' AS BILLING_CYCLE_DATE,
-- 	report_metadata.WHOLE_SALE_NAME AS PLAN,
	temp_wholesale_plan_history.plan AS PLAN,
	cdr_data_details_vw.START_TIME AS ORIGINATION_DATE,
   sum(cdr_data_details_vw.UPLINK_BYTES) AS TRANSMIT_BYTE,
   sum(cdr_data_details_vw.DOWNLINK_BYTES) AS RECEIVE_BYTES,
	sum(cdr_data_details_vw.TOTAL_BYTES) AS DATAUSAGE,
	-- sum(cdr_data_details_vw.TOTAL_BYTES * rounded_config ) AS DATAUSAGE_ROUNDING,
   cdr_data_details_vw.APN_ID AS APN,
	cdr_data_details_vw.SERVED_PDP_ADDRESS AS DEVICE_IP_ADDRESS,
	LEFT(cdr_data_details_vw.SERVED_MSISDN,6) AS OPERATOR_NETWORK,
  -- concat(cdr_data_details_vw.ULI_MCC,case when CHAR_LENGTH(cdr_data_details_vw.ULI_MNC)=1 then  concat('0',cdr_data_details_vw.ULI_MNC) else cdr_data_details_vw.ULI_MNC end ) AS OPERATOR_NETWORK,
	cdr_data_details_vw.RECORD_OPENING_TIME AS ORIGINATION_PLAN_DATE,
	sum(cdr_data_details_vw.DURATION_SEC) AS SESSION_DURATION,
   -- pgw_svc_data.SERVICE_DATA_FLOW_ID  ,
	cdr_data_details_vw.CAUSE_FOR_CLOSING AS CALL_TERMINATION_REASON,
  	cdr_data_details_vw.SERVICE_DATA_FLOW_ID AS RATING_STREAM_ID,
    -- 6 PARAMTER MISING     
   cdr_data_details_vw.SERVING_NODE_IPADDR AS SERVING_SWITCH,
   case when cdr_data_details_vw.RAT_TYPE=1 then '3' when cdr_data_details_vw.RAT_TYPE=6 then '4' when cdr_data_details_vw.RAT_TYPE=2 then '2' else '4' end  AS CALL_TECHNOLOGY_TYPE,
   cdr_data_details_vw.PGW_ADDRESS AS GGSN_IP_ADDRESS,
   cdr_data_details_vw.LOCAL_SEQUENCE_NUMBER as Record_Sequence_Number
	from	((report_metadata
	INNER JOIN cdr_data_details_vw
 	ON report_metadata.IMSI = cdr_data_details_vw.SERVED_IMSI
	left join gm_country_code_mapping on report_metadata.ACCOUNT_COUNTRIE=gm_country_code_mapping.account
	left join temp_wholesale_plan_history on temp_wholesale_plan_history.IMSI=report_metadata.IMSI
	and (cdr_data_details_vw.START_TIME between  temp_wholesale_plan_history.start_date and temp_wholesale_plan_history.end_date)))
	   WHERE 
		  date(cdr_data_details_vw.STOP_TIME) = date(start_date)
	   and report_metadata.MNO_ACCOUNTID=in_account_id
	group by cdr_data_details_vw.SERVED_IMSI, cdr_data_details_vw.CHARGING_ID,cdr_data_details_vw.SERVICE_DATA_FLOW_ID;

	SELECT temp_cdr_data_return_table.*,
		CASE WHEN ICCID IS NULL OR MSISDN IS NULL OR IMSI IS NULL OR SUPPLIER_ACCOUNT_ID IS NULL 
					OR BILLING_CYCLE_DATE IS NULL OR PLAN IS NULL OR ORIGINATION_DATE IS NULL OR TRANSMIT_BYTE IS NULL OR RECEIVE_BYTES IS NULL 
					OR DATAUSAGE IS NULL OR APN IS NULL OR DEVICE_IP_ADDRESS IS NULL
					OR OPERATOR_NETWORK IS NULL OR ORIGINATION_PLAN_DATE IS NULL OR SESSION_DURATION IS NULL 
					OR CALL_TERMINATION_REASON IS NULL OR RATING_STREAM_ID IS NULL OR SERVING_SWITCH IS NULL OR CALL_TECHNOLOGY_TYPE IS NULL 
			THEN 1 ELSE 0 END AS MANDATORY_COL_NULL
	FROM temp_cdr_data_return_table	ORDER BY MANDATORY_COL_NULL DESC;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS gm_sms_delivered_report;
DELIMITER $$
CREATE PROCEDURE `gm_sms_delivered_report`(IN `in_start_date` varchar(50), IN `in_end_date` varchar(50)

, IN `in_account_id` VARCHAR(50))
    COMMENT 'gm_sms_delivered_report_new'
BEGIN
  -- **********************************************************************
  -- Procedure: gm_sms_delivered_report_new
  -- Author: Parul Shrivastava
  -- Date: Nov 1, 2019
  
  -- Inputs: in_start_date,in_end_date
  -- Output: This procedure is returns the delivered sms report on the basis
  -- of the final time and sms status 
  -- Description: Procedure returns the sms delivered report genarted 
  -- **********************************************************************
	
   -- Declaring the variables 
	DECLARE date_duration VARCHAR(50);
	DECLARE start_date varchar(50);

   SET start_date:= CAST(in_start_date AS DATEtime);
   -- Using 2020 year as a reference year for calculating the billing cycle
	SET @TEMP_BILLING_CYCLE_DATE = (SELECT YEAR(in_start_date)+MONTH(in_start_date)-2020);

  CALL `gm_utility_get__wholesale_plan_history`(in_start_date);

	-- Preparing the billing dates
    SET date_duration= LAST_DAY(CONVERT( in_start_date, DATE ));
    SET @temp_date = DATE_SUB(in_start_date,INTERVAL DAYOFMONTH(in_start_date)-1 DAY);
	-- select concat(@temp_date ,' - ',date_duration);
	
  -- preparing the reports data from the different table on the basis of the SMS type and time 
	DROP TABLE IF EXISTS temp_cdr_sms_delivered_return_table;
    CREATE TEMPORARY TABLE temp_cdr_sms_delivered_return_table
    SELECT 
    report_metadata.ICCID AS ICCID,
	report_metadata.MSISDN AS MSISDN,
	report_metadata.IMSI AS IMSI,
   gm_country_code_mapping.country_Code AS SUPPLIER_ACCOUNT_ID ,
   -- report_metadata.ACCOUNT_NAME AS SUPPLIER_ACCOUNT_ID ,
   @TEMP_BILLING_CYCLE_DATE AS BILLING_CYCLE_DATE,
   -- '5' AS BILLING_CYCLE_DATE,
	cdr_sms_details.SMS_TYPE AS CALL_DIRECTION,
	-- report_metadata.WHOLE_SALE_NAME AS PLAN,
	 temp_wholesale_plan_history.plan AS PLAN,
   cdr_sms_details.SENT_TIME AS ORIGINATION_DATE,
   case when cdr_sms_details.SMS_TYPE='MO' then cdr_sms_details.ORIGINATION_GT
	when cdr_sms_details.SMS_TYPE='MT' then cdr_sms_details.DESTINATION_GT 
	else NULL end AS SERVING_SWITCH,
	case when cdr_sms_details.SMS_TYPE='MO' then cdr_sms_details.SOURCE
	when cdr_sms_details.SMS_TYPE='MT' then cdr_sms_details.DESTINATION
	else NULL end  AS ORIGINATION_ADDRESS ,
   case when cdr_sms_details.SMS_TYPE='MO' then cdr_sms_details.DESTINATION
	when cdr_sms_details.SMS_TYPE='MT' then cdr_sms_details.SOURCE
	else NULL end AS DESTINATION_ADDRESS,
    -- cdr_sms_details.DESTINATION_GT,
	/*  case when cdr_sms_details.SMS_TYPE='MO' then cdr_sms_details.ORIGINATION_GT
	when cdr_sms_details.SMS_TYPE='MT' then cdr_sms_details.DESTINATION_GT
	else NULL end  AS OPERATOR_NETWORK */
    LEFT(report_metadata.MSISDN,6) AS OPERATOR_NETWORK
	FROM (report_metadata
	INNER JOIN cdr_sms_details
	ON report_metadata.MSISDN = cdr_sms_details.SOURCE 
	OR report_metadata.MSISDN = cdr_sms_details.DESTINATION
	left join gm_country_code_mapping on report_metadata.ACCOUNT_COUNTRIE=gm_country_code_mapping.account
	left join temp_wholesale_plan_history on temp_wholesale_plan_history.IMSI=report_metadata.IMSI
	and (cdr_sms_details.FINAL_TIME between  temp_wholesale_plan_history.start_date and temp_wholesale_plan_history.end_date))	
   WHERE date(cdr_sms_details.FINAL_TIME)=date(start_date)
	and cdr_sms_details.SMS_STATUS = 'Success'
	and report_metadata.MNO_ACCOUNTID=in_account_id;
	-- GROUP BY IMSI,MSISDN ,CALL_DIRECTION ,ORIGINATION_DATE ;

	SELECT temp_cdr_sms_delivered_return_table.*,
	CASE WHEN ICCID IS NULL OR MSISDN IS NULL OR IMSI IS NULL OR SUPPLIER_ACCOUNT_ID IS NULL
			OR BILLING_CYCLE_DATE IS NULL OR CALL_DIRECTION IS NULL OR PLAN IS NULL OR ORIGINATION_DATE IS NULL
			OR SERVING_SWITCH IS NULL OR ORIGINATION_ADDRESS IS NULL OR DESTINATION_ADDRESS IS NULL 
            OR OPERATOR_NETWORK IS NULL
		THEN 1 ELSE 0 END AS MANDATORY_COL_NULL
	FROM temp_cdr_sms_delivered_return_table
    ORDER BY MANDATORY_COL_NULL DESC;
END$$
DELIMITER ;
