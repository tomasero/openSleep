# Base image
FROM python:3
# Copy contents
COPY . /app
# Change work directory
WORKDIR /app
# Install the requirements
RUN pip install -r requirements.txt
# Start the application
CMD ["python", "app.py"]
