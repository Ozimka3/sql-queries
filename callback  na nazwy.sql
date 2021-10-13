--update for column names on sourcing
UPDATE t_rfp_field
SET
field_label_pl =
CASE
WHEN field_code='ITEM_CODE' THEN 'Kod'
WHEN field_code='ITEM_FAMILY' THEN 'Kategoria zakupowa'
WHEN field_code='ITEM_GROUP' THEN 'Grupa'
WHEN field_code='ITEM_LABEL' THEN 'Artykuł'
WHEN field_code='ITEM_ORDER' THEN 'Zamówienie'
WHEN field_code='ITEM_PARENT' THEN 'Źródło'
WHEN field_code='ITEM_TYPE' THEN 'Typ kodu' 
WHEN field_code='TARGET_AMOUNT' THEN 'Cena docelowa' 
WHEN field_code='DELIV_DATE' THEN 'Data dostawcy'
WHEN field_code='REF_AMOUNT' THEN 'Cena referencyjna'
WHEN field_code='item_cbd_form' THEN 'Formuła cenowa'
WHEN field_code='item_logistics_cost' THEN 'Koszty logistyczne'
WHEN field_code='item_other_cost' THEN 'Inne koszty'
WHEN field_code='QTY' THEN 'Ilość'
WHEN field_code='UNIT' THEN 'Jednostka'
WHEN field_code='UNIT_PRICE' THEN 'Cena jednostkowa'
WHEN field_code='TOTAL' THEN 'Suma'
END


UPDATE wli
SET wli.contact_id_performer = wli.contact_id_origin
FROM t_wfl_worklist AS wli
WHERE wli.x_id =@x_id AND wli.tdesc_name = 't_ord_order'
AND wli.act_code = 'INI'

UPDATE ord
SET ord.status_code='can'
FROM t_ord_order AS ord
WHERE ord.basket_id IN
(
SELECT bsk.basket_id FROM t_ord_basket AS bsk
WHERE bsk._basket_id_multi_from=
(
 SELECT _basket_id_multi_from FROM t_ord_basket AS bsk
JOIN t_ord_order AS ord ON ord.basket_id=bsk.basket_id
WHERE ord.ord_id=@ord_id
)
AND bsk.status_code !='del'
AND bsk.status_code !='can'
  )
AND ord.status_code !='del'
AND ord.status_code !='can'

DECLARE @bsk_org INT
SET @bsk_org = (SELECT TOP 1 bsk._basket_id_multi_from FROM t_ord_order AS ord 
			   INNER JOIN t_ord_basket AS bsk ON bsk.basket_id = ord.basket_id
			   WHERE ord.ord_id = @ord_id)
			   
DELETE wli FROM t_wfl_worklist AS wli
WHERE wli.tdesc_name = 't_ord_order' AND CAST(x_id AS VARCHAR) IN (SELECT ord.ord_id FROM t_ord_order AS ord INNER JOIN t_ord_basket AS bsk ON bsk.basket_id = ord.basket_id WHERE bsk._basket_id_multi_from = @bsk_org)

--updating adendment labels 
UPDATE bsk
SET
bsk.basket_label_pl = 'Aneks nr.' + CONVERT(varchar,(ord.ord_amendment_num +1)) + ' ' + ord.ord_label_pl
FROM t_ord_basket AS bsk
JOIN t_ord_order AS ord ON ord.ord_id=bsk.ord_id_previous
WHERE bsk.basket_id=@basket_id
AND ord.ord_amendment_num >= 0
AND bsk.ord_id_previous IS NOT NULL
--AND (bsk.basket_label_pl LIKE 'Wniosek o aneks%')

UPDATE bsk
SET
bsk.basket_label_en = 'Amendment nr.' +CONVERT(varchar,(ord.ord_amendment_num +1)) + ' ' + ord.ord_label_en
FROM t_ord_basket AS bsk
JOIN t_ord_order AS ord ON ord.ord_id=bsk.ord_id_previous
WHERE bsk.basket_id=@basket_id
AND ord.ord_amendment_num >= 0 
AND bsk.ord_id_previous IS NOT NULL
--AND (bsk.basket_label_en LIKE 'Amendment request%')


--nn_account_autocompletion
--USTAWIENIE KONTA wg typu Kosztu w danej spółce
UPDATE alloc
SET alloc.acc_code = la._acc_code
	,alloc.lcomp_id = la._lcomp_id
FROM t_ord_allocation AS alloc
INNER JOIN x_orga_all x ON x.orga_level = alloc.orga_level AND x.orga_node = alloc.orga_node
--Ledger Account (Konto) na podstawie Cost Type oraz Spółki.
--Wybieramy jedno konto, i sprawdzamy ile ich jest
OUTER APPLY
(
	SELECT MAX(la._acc_code) _acc_code, la._lcomp_id _lcomp_id, COUNT(1) ile
	FROM t_ord_account_account_category_ la 
	WHERE alloc.aca_code = la._aca_code 
		AND la._lcomp_id = x.lcomp_id 
		AND la.status_code = 'val'
	GROUP BY la._aca_code, la._lcomp_id

) la

WHERE alloc.oitem_id=@oitem_id 
	AND alloc.orga_level IS NOT NULL 
	AND alloc.orga_node IS NOT NULL 
	AND alloc.aca_code IS NOT NULL 
	AND la.ile=1
	
--cost type 	
	UPDATE alloc
SET alloc.aca_code=bsk._aca_code
FROM t_ord_allocation AS alloc
LEFT JOIN t_ord_item oi ON oi.oitem_id=alloc.oitem_id
LEFT JOIN t_ord_basket AS bsk ON bsk.basket_id=oi.basket_id
WHERE alloc.oitem_id=@oitem_id 
AND alloc.aca_code IS NULL
AND bsk._aca_code IS NOT NULL
AND oi.status_code !='del'
AND bsk.status_code !='del'

-- quick allocation 
INSERT INTO t_ord_item_orga_all_
( 
  _oitem_id
  ,_orga_id
  )
 SELECT 
 oitem_id _oitem_id
 ,boall._orga_id _orga_id
 FROM 
 t_ord_item AS oitem
 JOIN t_ord_basket AS bsk ON bsk.basket_id = oitem.basket_id
 JOIN t_ord_basket_orga_all_ AS boall ON boall._basket_id = bsk.basket_id
 WHERE oitem.oitem_id = @oitem_id
 AND (oitem._oitem_default_allocation IS NULL OR oitem._oitem_default_allocation = 0)
 AND NOT EXISTS ( SELECT 1 FROM t_ord_item_orga_all_ AS ioall
	 WHERE ioall._oitem_id = oitem.oitem_id AND ioall._orga_id = boall._orga_id)
				 A
--zaciagniecie wartosci domyslnych z nagłowka
UPDATE oitem				 
SET oitem._cce_code_cost_center_a = bsk.cce_code
,oitem._aca_code_cost_type_b = bsk._aca_code
,oitem._oitem_default_allocation = 1
FROM t_ord_item AS oitem
JOIN t_ord_basket AS bsk ON bsk.basket_id = oitem.basket_id
 WHERE oitem.oitem_id = @oitem_id
 AND (oitem._oitem_default_allocation IS NULL OR oitem._oitem_default_allocation = 0)


