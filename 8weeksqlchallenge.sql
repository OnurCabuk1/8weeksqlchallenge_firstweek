  -- 1. Her müşterinin restoranda harcadığı toplam tutar nedir?
  select*from sales;

  select*from menu;

  --sales tablosunda ürün fiyatları yazmadığı için sales ve menu tablolarını joın komutu ile bağlayacağız.

  select*from sales s
  join menu m on m.product_id = s.product_id;

  -- menu tablosundan gelen price sütununu sales ve menu tablosundan customer_id sütunları ile ilişkilendirip toplama yapıyoruz ve her bir müşterinnin ne kadar harcama yaptığını görüyoruz.

select
	customer_id,
	sum(price)
from
	sales s
join 
	menu m
on 
	m.product_id=s.product_id 
group by 1
order by 2 desc;

-- çıktıya göre "A" kodlu müşteri 76, "B" kodlu müşteri 74, "C" kodlu müşteri 36 birimlik harcama yapmış.
-- bizim için en değerli müşteri A ve B müşterileri oluyor.

-- 2. Her müşteri restoranı kaç gün ziyaret etti?

select * from sales s
join menu m on m.product_id=s.product_id;

-- her bir müşterinin restoranı ziyaret ettiği benzersiz tarihleri bulalım.

select distinct customer_id, order_date 
from sales s join menu m
on s.product_id=m.product_id;

-- şimdi de her bir müşterinin restoranı toplamda kaç kez ziyaret ettiğini gösterelim.

select customer_id,
count (distinct order_date) as visit_count
from sales s join menu m
on s.product_id=m.product_id
group by customer_id
order by 2 desc;

--çıktıya baktığımızda müşteri "B" 6, müşteri "A" 4 ve müşteri "C" 2 kez restoranı ziyaret etmiş

-- 3. Her müşterinin satın aldığı ilk ürün neydi?

--ilk olarak müşterilerin satın alma tarihlerini bulalım

select *
from sales s join menu m
on s.product_id=m.product_id
order by customer_id, order_date;

--şimdi de müşterilerin yaptığı ilk alışverişleri gösteren çıktıyı elde edelim.

select customer_id,order_date,product_name,
row_number() over (partition by customer_id
order by order_date) 
from sales s 
join menu m 
on m.product_id = s.product_id
order by customer_id,order_date;

--burdaki çıktımızda A müşterisi cury ve sushi siparişlerini aynı gün verdiği için yazdığımız komut rastgele bir sıralama yapmış
--bunu düzeltmek için row_number yerine rank komutunu kullanabiliriz.

select customer_id,order_date,product_name,
rank() over (partition by customer_id
order by order_date) 
from sales s 
join menu m 
on m.product_id = s.product_id
order by customer_id,order_date;

-- bu bütün tarihleri gösteren çıktı

with first_order as (
select distinct customer_id, order_date,product_name,
rank() over (partition by customer_id order by order_date) rn
from sales s join menu m on m.product_id=s.product_id
	)
	select customer_id,
		   product_name
	from first_order
	where rn = 1
	order by 1;

--bu çıktıda ise müşterilerin verdiği ilk siparişlerin ismini product_name sütununda görüyoruz.

--4. Menüde en çok satın alınan ürün hangisidir ve tüm müşteriler tarafından kaç kez satın alınmıştır?

select * from 
sales s	
join menu m on m.product_id = s.product_id
order by customer_id,order_date;

select product_name,
	count(s.product_id)
from sales s	
join menu m on m.product_id = s.product_id
group by 1
order by 2 DESC
limit 1;

-- müşteriler tarafından en çok satın alınan ürün 'ramen' dir ve toplam 8 kez satın alınmıştır.

-- 5. Her müşteri için en popüler ürün hangisiydi?
with favourite_product as(
select
	s.customer_id,
	m.product_name,
count (s.product_id) as total_sales,
row_number () over(partition by s.customer_id order by count (s.product_id) DESC) as rank
from
	sales s
join menu m on m.product_id = s.product_id
group by 1,2
	)
select  
	customer_id,
	product_name,
	total_sales
from
	favourite_product
where 
	rank=1;


-- 6. Müşteri üye olduktan sonra ilk olarak hangi ürünü satın aldı?

select * from 
	sales s
	left join menu m on m.product_id=s.product_id
	left join members mem on mem.customer_id=s.customer_id;

-- "C" müşterisi üye olmadığı için bu tablomuzda görünmüyor o yüzden bu sorguyu kullanmamıza gerek yok.
with first_product as (
select s.customer_id,
		order_date,
		product_name,
row_number() over(partition by s.customer_id order by order_date) as rank
	from 
	sales s
	left join menu m on m.product_id=s.product_id
	left join members mem on mem.customer_id=s.customer_id
where order_date >= join_date
order by 1,2
   )
select customer_id,
	   product_name
	from first_product
	where rank=1;

-- çıktıya göre "A" müşterisinin aldığı ilk ürün curry, "B" müşterisinin sushi olmuştur.

-- 7. Müşteri üye olmadan hemen önce hangi ürünü satın aldı?

with before_membership
 as (
select s.customer_id,
		order_date,
		product_name,
		rank() over(partition by s.customer_id order by order_date DESC) as rank
	from 
	sales s
	left join menu m on m.product_id=s.product_id
	left join members mem on mem.customer_id=s.customer_id
where order_date < join_date
order by 1,2
   )
select customer_id,
	   product_name
	from before_membership
	where rank=1;

--çıktıya göre "A" müşterisinin üye olmadan önceki son siparişi sushi ve curry, "B" müşterisinin ise sushi olmuş.

-- 8. Her üyenin üye olmadan önce harcadığı toplam kalem ve tutar nedir?

select s.customer_id,
	   count (s.product_id),
	   sum(price)
	   from sales s
left join menu m on m.product_id=s.product_id
left join members mem on s.customer_id = mem.customer_id
where order_date < join_date
group by 1;

-- "B" müşterisi üye olmadan önce 3 kez alışveriş yapmış ve 40 birimlik harcama yapmış, "A" müşterisi ise 2 kez alışveriş yapmış ve 25 birimlik harcama yapmış.

-- 9. Harcanan her 1 dolar 10 puana eşitse ve suşi 2 kat puan çarpanına sahipse, her müşterinin kaç puanı olur?

select customer_id,
		product_name,
		price,
case when product_name= 'sushi' then price*10*2
else price*10 
end points 
from sales s join menu m on m.product_id = s.product_id;

-- bu komut ile her bir müşterinin aldığı ürünleri ve puanlarını ayrı ayrı görüyoruz.

with total_points as (
select customer_id,
		product_name,
		price,
case when product_name= 'sushi' then price*10*2
else price*10 
end points 
from sales s join menu m on m.product_id = s.product_id
	)
select customer_id,
	   sum(points)
from total_points
group by 1
order by 2 DESC;

-- çıktımıza baktığımızda "B" müşterisi 940 puan, "A" müşterisi 860 puan, "C" müşterisi 360 puan olarak görünüyor.

-- 10. Bir müşteri programa katıldıktan sonraki ilk haftada (katılma tarihi dahil) sadece suşide değil, tüm yiyeceklerde 2 kat puan kazanır - A ve B müşterisi Ocak ayı sonunda kaç puana sahip olur?

select customer_id,
	   join_date start_date,
	   join_date+6 end_date
from members;
-- bu sorgu ile A ve B müşterilerinin üye oldukları ilk haftayı filtrelemiş olduk.

with first_week as (
select s.customer_id,
	   join_date start_date,
	   join_date+6 end_date,
	   order_date,
	   product_name,
	   price,
case when order_date between join_date and join_date+6 then price * 20
when product_name='sushi'then price *20
else price * 10 end as points 
from sales s
join menu m on m.product_id = s.product_id
join members mem on mem.customer_id = s.customer_id
where order_date <= '2021-01-31'
	)
select customer_id,
	   sum(points)
	   from first_week
	   group by 1;

-- "A" müşterisinin 1370 "B" müşterisinin 820 puanı var.

--BONUS SORU
select s.customer_id,
		product_name,
		order_date,
		price,
		join_date,
case
	when order_date >= join_date then 'Y'
	else 'N' end as member
	from sales s
	join menu m on  m.product_id = s.product_id
	left join members mem on mem.customer_id = s.customer_id
order by 1,2;

-- çıktıda alışveriş yapılan tarihte alışverişi yapan müşteri üyemiz mi değil mi onu görüyoruz.

--BONUS SORU 2.

--ranking adındaki bir sütunda alışverişi yaptığı sırada üye değilse satır 'null' görünsün. üye olduğu zaman yaptığı alışverişleri tarih sırasına göre sırala. 

with tablo as (
select s.customer_id,
		product_name,
		order_date,
		price,
		join_date,
case
	when order_date >= join_date then 'Y'
	else 'N' end as member
	from sales s
	join menu m on  m.product_id = s.product_id
	left join members mem on mem.customer_id = s.customer_id
order by 1,2
	)
select * , 
 	case 
	 when member='N' then null 
	 else 
	 rank () over(partition by customer_id, member order by order_date) end as ranking
	 from tablo;