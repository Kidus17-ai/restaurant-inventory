# Use official Python image as base
FROM python:3.12-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser -m appuser

# Set working directory inside container
WORKDIR /app

# Copy requirements first (better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install gunicorn — production web server
RUN pip install gunicorn

# Copy the rest of the app
COPY . .

# Give ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 5001
EXPOSE 5001

# Run with gunicorn in production
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "run:app"]