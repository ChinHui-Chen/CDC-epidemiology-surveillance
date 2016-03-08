#mongoimport -h localhost:3001 --db meteor --collection articles --file ../demo3.json --fields DiseaseName,Relevance,Source,Title,Snippet,Url,Language,Location,Lat,Lng,PublishTime,CrawlTime
mongoimport -h localhost:3001 --db meteor --collection articles --file ../demo2.json
