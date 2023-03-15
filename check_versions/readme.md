### запуск: 
```./check_charts_version_v2.sh <LOCation name>```

#### работа:
- двумя курлами получаем
  - список чартов (*charts)
  - список хостов остальных типов чартов
- из чартов делаем компуты
- объединяем со списком хостов остальных типов чартов
- в цикле по хостам определяем версию docker image контейнера metrix, пишем в файл рядом
- запускаем charts.py для рендера красивой таблички (чарт, тип [pro/free/wgt/mobile...], версия)
- удаляем файл с результатами