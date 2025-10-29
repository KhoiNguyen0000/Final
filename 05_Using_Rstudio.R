library('ggplot2')
library('dplyr')
# Change your path here
data <- read.csv('~/Uni/FPT_Subjects/Fall_2025/ADY201m/Final/Datasets/Clean_data/Locality_Analyst.csv')
colnames(data)
# getting mean data

mean_data <- data%>%
  group_by(Vùng) %>%
  summarise(Mat_do_tb = mean(`Mật.độ.dân.số..Người.km2.`,na.rm = TRUE))

# plotting data average population density each region

ggplot(mean_data,aes(y=Vùng,x=Mat_do_tb,fill=Vùng))+
         geom_bar(stat='identity')+
         labs(titlle = 'Mật đô dân số trung bình từng Tỉnh 2011-2024',
              x = 'Mật độ dân số trung bình (Người/km2)',
              y = 'Tỉnh') +
         theme_minimal()

# getting population of Vietnam 

all_data <- data%>%
  group_by(Năm) %>%
  summarise(Tong_dan_so = sum(`Tổng.dân.số`),na.rm = TRUE)


# plotting Vietnam population from 2011-2024

ggplot(all_data,aes(x=Năm,y=Tong_dan_so,fill = Năm)) + 
  geom_bar(stat='identity') +
  labs(title = 'Tổng dân số Việt Nam 2011-2024',
       x = 'Năm',
       y = 'Tổng dân số') +
  theme_minimal()



