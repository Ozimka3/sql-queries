
SELECT 
pdt.pdt_label_pl AS ' Nazwa produktu '
,pdt.pdt_code AS ' Kod produktu'
,pitem.item_label_pl AS 'Nazwa itemu'
,pitem.item_code AS 'Kod itemu'
,pitem.ctr_id AS 'Kontrakt ID'
,pdttype.pdttype_label_pl AS 'Produkt/Usługa'
,pitem.item_public_price_entry AS 'Cena'
,pitem.tva_value AS 'Stawka VAT'
,status.status_label_pl AS 'Status'
,pitem.item_begin_date AS 'Data obowiązywania od'
,pitem.item_end_date AS 'Data obowiązywania do'
FROM t_pdt_item AS pitem
LEFT JOIN t_pdt_product AS pdt ON pdt.pdt_id = pitem.pdt_id
LEFT JOIN t_pdt_product_type AS pdttype ON pdttype.pdttype_code = pdt.pdttype_code
LEFT JOIN t_bas_status AS status ON status.status_code = pitem.status_code AND status.tdesc_name='t_pdt_item'