
CREATE TABLE #contact_role
(login_name VARCHAR(MAX)
, profil_code VARCHAR(MAX)
) 

INSERT INTO #contact_role 
(login_name,
 profil_code )

SELECT login_name
,profil_code
FROM t_usr_login_profil
JOIN t_usr_login AS l ON g.contact_id = l.contact_id
JOIN t_usr_contact_group AS g ON grp.contact_id = l.contact_id
WHERE g.role_code = 'tech' 
AND NOT EXISTS 
( SELECT * FROM t_usr_login_profil WHERE profil_code = 'supplier_b2c' )

DELETE FROM t_usr_login_profil AS loginprofil
WHERE  loginprofil.profil_code = 'supplier_b2c'
AND loginprofil.login_name IS NOT NULL

INSERT INTO t_usr_login_profil AS loginprofil
(login_name,
 profil_code )
  
SELECT 
login_name
FROM #contact_role

UNION

SELECT
profil_code
FROM t_usr_login 


DROP TABLE #contact_role

				
				/* 0. Creation of temporary table with activities list */
CREATE TABLE #act_list 
(process_code VARCHAR(MAX)
, tdesc_name VARCHAR(MAX)
, act_code VARCHAR(MAX)
, act_label VARCHAR(MAX)
, act_display_col INT 
, act_display_line INT
, act_order INT
, act_button_val_label_en VARCHAR(MAX)
, url_link VARCHAR(MAX)
) 

INSERT INTO #act_list (
process_code
,tdesc_name
,act_code
,act_label
,act_display_col
,act_display_line
,act_order
,act_button_val_label_en
,url_link

)
/* 1. Activity list */
  SELECT 'sup_cr' AS process_code
  ,'t_sup_supplier' AS tdesc_name 
  ,'test' AS act_code 
  ,'Test' AS act_label
  ,0 AS act_display_col
  ,1 AS act_display_line
  ,3 AS act_order
  ,'Validate' AS act_button_label_en
  ,'/sup/supplier_manage/{0}' AS url_link
  
  UNION
  
   SELECT 'sup_cr' AS process_code
  ,'t_sup_supplier' AS tdesc_name 
  ,'test2' AS act_code 
  ,'Test2' AS act_label
  ,0 AS act_display_col
  ,2 AS act_display_line
  ,3 AS act_order
  ,'Validate' AS act_button_label_en
  ,'/sup/supplier_manage/{0}' AS url_link
  
  
/* 2. Activities creation */
INSERT INTO t_wfl_activity (process_code
,act_code
,act_type
,act_label_en
,act_display_line
,act_display_col
,act_order
,act_confirm_val
,act_confirm_ref
,login_name_created
,created
,act_button_val_label_en

)

SELECT a.process_code
,a.act_code
,'E' AS act_type
,a.act_label AS act_label_en
,a.act_display_line 
,a.act_display_col
,a.act_order
,0 AS act_confirm_val
,0 AS act_confirm_ref
,@login_name AS login_name_created
,getUTCDATE() AS created
,a.act_button_val_label_en 


FROM #act_list AS a
WHERE NOT EXISTS (SELECT 1 FROM t_wfl_activity AS wa WHERE wa.process_code = a.process_code AND wa.act_code = a.act_code)

/* 3. Setting up activity administrator */
;INSERT INTO t_wfl_activity_actor_function (
process_code
,act_code
,afct_code
,aaf_type
,aaf_order

)
SELECT 
  act.process_code
  ,act.act_code
  ,'admin' AS afct_code
  ,'admin' AS aaf_type
  ,0 AS aaf_order

  FROM #act_list AS a
  INNER JOIN t_wfl_activity AS act ON act.process_code = a.process_code AND act.act_code = a.act_code
  WHERE NOT EXISTS ( SELECT 1 FROM t_wfl_activity_actor_function AS af WHERE af.process_code = act.process_code AND af.act_code = act.act_code AND af.aaf_type = 'admin' AND af.afct_code = 'admin')

/* 4. Setting up URL */
INSERT INTO t_wfl_process_opener (
process_code
,tdesc_name
,act_code
,page_url
,process_scope_enabled 
)
SELECT act.process_code
, a.tdesc_name
, a.act_code
, a.url_link AS page_url
,0 AS process_scope_enabled

FROM #act_list AS a  
INNER JOIN t_wfl_activity AS act ON act.process_code = a.process_code AND act.act_code = a.act_code 
WHERE NOT EXISTS ( SELECT 1 FROM t_wfl_process_opener AS pop WHERE act.process_code = pop.process_code AND a.tdesc_name = pop.tdesc_name AND a.act_code = pop.act_code AND a.url_link = pop.page_url)


/*5. Drop temporary table with activities list*/
DROP TABLE #act_list\