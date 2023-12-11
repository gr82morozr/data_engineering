# Start JupyterLab in the background
jupyter lab --ip=* --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' --notebook-dir=/home/spark/notebooks &


# Start the Spark Master process in the background
/opt/spark/bin/spark-class org.apache.spark.deploy.master.Master -h spark-master 