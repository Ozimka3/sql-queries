
--insert na 3WM odrzucenia
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
  ,wli_comment
)


SELECT ISNULL(A.wli_seq,0)+1
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
,wli_comment

FROM t_wfl_worklist 

OUTER APPLY 
(SELECT TOP 1 wli_seq FROM t_wfl_worklist_history AS twflh
 WHERE
 t_wfl_worklist.x_id = twflh.x_id AND
 t_wfl_worklist.contact_id_performer = twflh.contact_id_performer AND
 t_wfl_worklist.pex_id = twflh.pex_id AND 
 t_wfl_worklist.act_id = twflh.act_id 
	ORDER BY wli_seq
) A
						   
WHERE tdesc_name = 't_ord_invoice' 
AND x_id = @x_id
AND act_code NOT IN ('ini', 'can') AND wli_date_ref IS NOT NULL 