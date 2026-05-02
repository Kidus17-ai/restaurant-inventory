import json
import os
import boto3
import psycopg2
from datetime import datetime

def lambda_handler(event, context):
    """
    Runs every night at midnight via EventBridge.
    Checks all stock items against their thresholds.
    Sends SNS alert for any items running low.
    """

    # Get environment variables
    db_url = os.environ['DATABASE_URL']
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']

    # Connect to RDS
    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()

    # Fetch all items below their threshold
    cursor.execute("""
        SELECT name, unit, current_stock, low_threshold
        FROM items
        WHERE current_stock <= low_threshold
        ORDER BY current_stock ASC
    """)

    low_stock_items = cursor.fetchall()
    cursor.close()
    conn.close()

    # If no items are low, do nothing
    if not low_stock_items:
        print("All stock levels are healthy — no alerts needed")
        return {
            'statusCode': 200,
            'body': json.dumps('All stock levels healthy')
        }

    # Build alert message
    message_lines = [
        "RestockIQ — Nightly Stock Alert",
        f"Date: {datetime.now().strftime('%A %d %B %Y')}",
        "",
        "The following items are running low and require attention:",
        ""
    ]

    for name, unit, current_stock, low_threshold in low_stock_items:
        message_lines.append(
            f"• {name}: {current_stock} {unit} remaining (threshold: {low_threshold} {unit})"
        )

    message_lines.extend([
        "",
        "Please log into RestockIQ to review and place orders.",
        f"https://restockiq.net"
    ])

    message = "\n".join(message_lines)

    # Publish to SNS
    sns = boto3.client('sns', region_name='eu-west-2')
    sns.publish(
        TopicArn=sns_topic_arn,
        Subject="RestockIQ — Low Stock Alert",
        Message=message
    )

    print(f"Alert sent for {len(low_stock_items)} low stock items")

    return {
        'statusCode': 200,
        'body': json.dumps(f'Alert sent for {len(low_stock_items)} items')
    }