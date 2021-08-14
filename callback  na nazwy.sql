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




