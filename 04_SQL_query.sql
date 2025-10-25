use ADY201M_PROJECT
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
select region, year, total_population from population_data
go
--2
with max_population as(
	select year, max(population_density) max_total
	from population_data
	where region != N'Cả nước'
	group by year)
select ld.region, ld.year, mp.max_total
from population_data ld, max_population mp
where ld.region != N'Cả nước' and ld.year = mp.year and ld.population_density = mp.max_total
--3
select region, round(avg(natural_increase_rate), 2) avg_natural_increase_rate
from population_data
group by region
--4
go
with stat as (
	select
		L.region,
		AVG(L.crude_birth_rate) as avg_x , AVG(L.crude_death_rate) as avg_y,
		STDEV(L.crude_birth_rate) as stdev_x,
		STDEV(L.crude_death_rate) as stdev_y,
		Count(*) as n
	from population_data as L
	group by region 
),base as (
	select
		L.region,
		L.crude_birth_rate,L.crude_death_rate,
		s.avg_x  , s.avg_y,
		s.stdev_x, s.stdev_y,
		s.n
	from population_data as L CROSS JOIN stat as s 
)
select region,
	SUM((crude_birth_rate - avg_x) *(crude_death_rate - avg_y)) /((MAX(n)-1) * MAX(stdev_x) * MAX(stdev_y)) as correlation
from base
group by region
--5
select region, year, round((urban_population / total_population *100), 2) urbanization
from population_data
--6
select REGION, area_type, Round(AVG(unemployment_rate),2) avg_total, round(AVG(urban_unemployment_rate),2) avg_urban, round(AVG(rural_unemployment_rate),2) avg_rural
from population_data
group by REGION, area_type
order by region
--7
select p.region,p.area_type,p.unemployment_rate, A.growth
from population_data as p, (
	SELECT region, year, total_population, 
	round(total_population - LAG(total_population) OVER(PARTITION BY region ORDER BY year),2) growth
	FROM population_data) as A
where p.region = A.region and p.year = A.year

--8
select region , year, immigration_rate, emigration_rate, round((immigration_rate -  emigration_rate),2) net_migration_rates
from population_data