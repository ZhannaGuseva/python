FROM python:3.7-slim

WORKDIR /app
# Add requirements file in the container
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Add source code in the container
COPY main.py .

# Define container entry point (could also work with CMD python main.py)
ENTRYPOINT ["python", "main.py"]
