--przekazywanie flagi
UPDATE INV
SET inv._inv_acc_manual = 1 
FROM t_ord_invoice AS inv
JOIN t_ord_invoice_order AS io ON io.invoice_id=inv.invoice_id
JOIN t_ord_order AS ord ON ord.ord_id=io.ord_id
WHERE inv.invoice_id=@invoice_id
AND CAST(ord._ord_acc_manual AS int)=1
AND (inv._inv_acc_manual IS NULL OR inv._inv_acc_manual=0)

--alert na invoice 
SELECT i.invoice_id 
FROM t_ord_invoice AS i
JOIN t_ord_invoice_order AS invord ON invord.invoice_id = i.invoice_id
JOIN t_ord_order AS ord ON ord.ord_id = invord.ord_id
JOIN t_ord_basket AS bsk ON ord.basket_id = bsk.basket_id
JOIN x_orga_all AS xi ON i.orga_id = xi.orga_id
JOIN x_orga_all AS xo ON bsk.orga_id = xo.orga_id
WHERE xi.lcomp_id != xo.lcomp_id
AND i.status_code LIKE 'ap%' 

--sql filter na selektor dostawcy b2c

cce.cce_code IN
(SELECT alloc.cce_code FROM t_ord_allocation AS alloc
 JOIN t_ord_item AS oitem ON oitem.oitem_id = alloc.oitem_id
 JOIN t_ord_order AS ord ON ord.ord_id = oitem.ord_id
 JOIN t_ord_delivery AS deliv ON ord.sup_id = deliv.sup_id
 WHERE deliv.deliv_id = {deliv})

--insert kontraktorów
INSERT INTO t_wfl_worklist
(
  process_code
  ,x_id
  ,tdesc_name
  ,act_code
  ,contact_id_performer
  ,wli_date_val
  ,wli_date_ini
  ,contact_id_origin
  ,wli_list_act_path
  ,act_id
  ,pex_id	
)
SELECT DISTINCT wli.process_code  process_code
  ,@x_id x_id
  ,wli.tdesc_name tdesc_name
  ,'c_access' act_code
  ,wline._contact_id_contractor contact_id_performer
  ,@timestamp wli_date_val
  ,@timestamp wli_date_ini
  ,wline._contact_id_contractor contact_id_origin
  ,'INI' wli_list_act_path
  ,act.act_id act_id
  ,wli.pex_id pex_id
FROM t_wfl_worklist AS wli
JOIN t_ord_delivery AS deliv ON deliv.deliv_id = wli.x_id
JOIN t_ord_worklog_line_ AS wline ON deliv.deliv_id =wline._deliv_id
JOIN t_wfl_activity AS act ON act.process_code = wli.process_code AND act.act_code = 'c_access'
WHERE wli.tdesc_name = 't_ord_delivery'
AND wli.x_id = @x_id
AND wli.act_code = 'INI'
AND deliv._rmode_code = 'C'
AND NOT EXISTS
(
   SELECT 1
   FROM t_wfl_worklist b2c
   WHERE b2c.tdesc_name = 't_ord_delivery'
   AND b2c.x_id = wli.x_id
   AND b2c.act_code = 'c_access'
   AND b2c.contact_id_performer = wline._contact_id_contractor
  
)

--insert supplier admina
INSERT INTO t_wfl_worklist
(
  process_code
  ,x_id
  ,tdesc_name
  ,act_code
  ,contact_id_performer
  ,wli_date_val
  ,wli_date_ini
  ,contact_id_origin
  ,wli_list_act_path
  ,act_id
  ,pex_id	
)
SELECT DISTINCT wli.process_code  process_code
  ,@x_id x_id
  ,wli.tdesc_name tdesc_name
  ,'c_access' act_code
  ,grpcontact.contact_id contact_id_performer
  ,@timestamp wli_date_val
  ,@timestamp wli_date_ini
  ,grpcontact.contact_id contact_id_origin
  ,'INI' wli_list_act_path
  ,act.act_id act_id
  ,wli.pex_id pex_id
FROM t_wfl_worklist AS wli
JOIN t_ord_delivery AS deliv ON deliv.deliv_id = wli.x_id
JOIN t_sup_supplier AS sup ON deliv.sup_id = sup.sup_id
JOIN t_usr_contact_group AS grpcontact ON sup.grp_id = grpcontact.grp_id
JOIN t_wfl_activity AS act ON act.process_code = wli.process_code AND act.act_code = 'c_access'
WHERE wli.tdesc_name = 't_ord_delivery'
AND wli.x_id = @x_id
AND wli.act_code = 'INI'
AND deliv._rmode_code = 'C'
AND grpcontact.role_code = 'supplier_admin'
AND NOT EXISTS
(
   SELECT 1
   FROM t_wfl_worklist b2c
   WHERE b2c.tdesc_name = 't_ord_delivery'
   AND b2c.x_id = wli.x_id
   AND b2c.act_code = 'c_access'
   AND b2c.contact_id_performer = grpcontact.contact_id
)

-- insert na t_wfl_worklist_history


INSERT INTO t_wfl_worklist_history 
(
  wli_seq
  ,process_code
  ,x_id
  ,tdesc_name
  ,act_code
  ,contact_id_performer
  ,wli_date_val
  ,wli_date_ref
  ,contact_id_origin
  ,act_id
  ,pex_id
)


SELECT 
ISNULL(A.wli_seq,1)
,process_code
,x_id
,tdesc_name
,act_code
,contact_id_performer
,wli_date_val
,wli_date_ref
,contact_id_origin
,act_id
,pex_id

FROM t_wfl_worklist 

OUTER APPLY 
(SELECT TOP 1 wli_seq FROM t_wfl_worklist_history 
 ORDER BY wli_seq
						) A
						   
WHERE tdesc_name = 't_ord_invoice' 
AND x_id = @x_id
AND act_code NOT IN ('ini', 'can') AND wli_date_ref IS NOT NULL 


-- insert na worklog line duplikacja lini

INSERT INTO t_ord_worklog_line_ 
(
  _wline_qty
  ,_cce_code
  ,_work_id
  ,_wline_price
  ,_tva_code
  ,status_code
  ,_login_name_wck
  ,_contact_id_contractor
  ,_deliv_id
  ,_wline_chk
  ,_year_id
  ,_month_id
  ,	_orga_id
  ,_dwsubj_id_a
  ,_dwdesc_id_a
  ,_unit_code
  ,_wline_date_from
  ,_wline_date_to
  ,_wline_amount
  ,_wline_alloc_amount
  ,_etype_code
  ,_unit_code_currency
  ,_contact_id_wck
  ,_unit_code_unit_code_currency
  ,_wline_ordered_amount
  ,_wline_selected
)


SELECT 
 _wline_qty
  ,_cce_code
  ,_work_id
  ,_wline_price
  ,_tva_code
  ,status_code
  ,_login_name_wck
  ,_contact_id_contractor
  ,_deliv_id
  ,_wline_chk
  ,_year_id
  ,_month_id
  ,	_orga_id
  ,_dwsubj_id_a
  ,_dwdesc_id_a
  ,_unit_code
  ,_wline_date_from
  ,_wline_date_to
  ,_wline_amount
  ,_wline_alloc_amount
  ,_etype_code
  ,_unit_code_currency
  ,_contact_id_wck
  ,_unit_code_unit_code_currency
  ,_wline_ordered_amount
  ,_wline_selected
  FROM t_ord_worklog_line_
  WHERE _deliv_id = @deliv_id
  AND _wline_selected = 1

UPDATE wline
SET wline._wline_selected = 0
FROM t_ord_worklog_line_ AS wline
WHERE wline._deliv_id=@deliv_id


SELECT sup.sup_name_en, Change.sup_name FROM t_sup_supplier AS sup
OUTER APPLY
  ( SELECT TOP 1 cr.sup_name_en sup_name FROM t_sup_supplier AS cr 
   WHERE cr.sup_id_from  = sup.sup_id 
  ORDER BY cr.sup_id DESC) Change
WHERE sup.sup_id = 7867


SELECT * FROM t_sup_supplier AS sup
JOIN t_sup_supplier AS cr ON cr.sup_id_from = sup.sup_id
WHERE sup.sup_id = 7867
