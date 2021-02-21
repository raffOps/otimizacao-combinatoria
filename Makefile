julia:
	docker build -t julia .
jupyter:
	docker run -it -v ${PWD}:/otc -p 8090:8090 julia jupyter notebook --port 8090
