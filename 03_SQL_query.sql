use ADY201M
/*
1. Dân số trung bình theo vùng qua các năm
Mục đích: Quan sát xu hướng tăng trưởng dân số theo thời gian.
2. Mật độ dân số cao nhất theo năm
Mục đích: Tìm vùng có mật độ dân số lớn nhất mỗi năm.
3. So sánh tỷ lệ tăng tự nhiên theo vùng
Mục đích: Xem vùng nào có tốc độ tăng dân số tự nhiên cao/thấp nhất.
4. Mối tương quan giữa tỷ suất sinh thô và tỷ suất chết thô
Mục đích: Kiểm tra sự cân bằng nhân khẩu học.
5. Mức độ đô thị hóa (tỷ lệ dân thành thị so với tổng dân)
Mục đích: Đánh giá quá trình đô thị hóa của các vùng.
6. Tỷ lệ thất nghiệp trung bình theo vùng và khu vực
Mục đích: So sánh thất nghiệp giữa thành thị và nông thôn.
7. Kết hợp 3 bảng để phân tích mối quan hệ giữa tăng dân số và thất nghiệp
Mục đích: Xem vùng có tăng dân số mạnh có tỷ lệ thất nghiệp cao không.
8. Phân tích xu hướng di cư (nhập, xuất, thuần) theo vùng
Mục đích: Xem vùng nào thu hút hay mất dân cư.
*/
--1
select region, year, avg_population_thousand from population_data
go
--2
with max_population as(
	select year, max(population_density) max_total
	from population_data
	group by year)
select ld.region, ld.year, mp.max_total
from population_data ld, max_population mp
where ld.year = mp.year and ld.population_density = mp.max_total
go
--3
with avg_natural_growth_rate as(
	select region, avg(natural_growth_rate) avg_value
	from population_data
	group by region
)
select *
from avg_natural_growth_rate
where avg_value = (select max(avg_value) from avg_natural_growth_rate)
	or avg_value = (select min (avg_value) from avg_natural_growth_rate)

--5
select region, year, round((urban_population / total_population *100), 2) urbanization
from population_data
--6
select REGION, area_type, Round(AVG(unemployment_rate),2) avg_total, round(AVG(urban_unemployment_rate),2) avg_urban, round(AVG(rural_unemployment_rate),2) avg_rural
from population_data
group by REGION, area_type
order by region
go
--7
with subtable as(
	select region, year, total_population, ROUND(
            ( (total_population - LAG(total_population) OVER (PARTITION BY region ORDER BY year))
              / NULLIF(LAG(total_population) OVER (PARTITION BY region ORDER BY year), 0)
            ) * 100, 2) population_growth_pct, unemployment_rate
	from population_data 
)
SELECT region, ROUND(AVG(population_growth_pct), 2) population_growth_pct, ROUND(AVG(unemployment_rate), 2) unemployment_rate
FROM subtable
GROUP BY region
ORDER BY population_growth_pct DESC;
--8
select region , year, immigration_rate, emigration_rate, round((immigration_rate -  emigration_rate),2) net_migration_rates
from population_data