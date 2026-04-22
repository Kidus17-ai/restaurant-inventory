from app.models import StockLog
from datetime import datetime, timedelta
from collections import defaultdict

def get_prediction(item):
    """
    Predicts when an item will run out based on a 3 day forward average
    of day-of-week usage patterns. Falls back to simple average if not
    enough data exists.
    """

    logs = StockLog.query.filter_by(item_id=item.id).all()

    # Not enough data — fall back to simple prediction
    if len(logs) < 7:
        return get_simple_prediction(item, logs)

    # Group usage by day of week (0=Monday, 6=Sunday)
    day_usage = defaultdict(list)
    for log in logs:
        day = log.logged_at.weekday()
        day_usage[day].append(log.quantity_used)

    # Calculate average usage per day of week
    day_averages = {}
    for day, usages in day_usage.items():
        day_averages[day] = sum(usages) / len(usages)

    # Get overall average as fallback for days with no data
    overall_average = sum(day_averages.values()) / len(day_averages)

    # Get next 3 days including today
    today = datetime.utcnow().weekday()
    next_3_days = [(today + i) % 7 for i in range(3)]

    # Calculate average usage across next 3 days
    next_3_day_usages = []
    days_with_data = 0
    for day in next_3_days:
        if day in day_averages:
            next_3_day_usages.append(day_averages[day])
            days_with_data += 1
        else:
            # No data for this day yet — use overall average as fallback
            next_3_day_usages.append(overall_average)

    # Average across the 3 days
    daily_usage = sum(next_3_day_usages) / len(next_3_day_usages)

    # Determine confidence based on how many of the 3 days have real data
    if days_with_data == 3:
        confidence = 'high'
    elif days_with_data >= 1:
        confidence = 'medium'
    else:
        confidence = 'low'

    # Avoid division by zero
    if daily_usage == 0:
        return {
            'days_remaining': None,
            'runout_date': None,
            'confidence': 'low',
            'message': 'No usage recorded yet'
        }

    # Calculate days remaining based on 3 day forward average
    days_remaining = item.current_stock / daily_usage
    runout_date = datetime.utcnow() + timedelta(days=days_remaining)

    return {
        'days_remaining': round(days_remaining, 1),
        'runout_date': runout_date.strftime('%A %d %B'),
        'confidence': confidence,
        'message': f'Based on 3 day forward average from {len(logs)} usage logs'
    }


def get_simple_prediction(item, logs):
    """
    Fallback prediction using simple rolling average.
    Used when not enough day-specific data exists yet.
    """

    if not logs:
        return {
            'days_remaining': None,
            'runout_date': None,
            'confidence': 'low',
            'message': 'No usage data yet — predictions will appear after logging begins'
        }

    # Simple average across all logs
    total_usage = sum(log.quantity_used for log in logs)
    daily_average = total_usage / len(logs)

    if daily_average == 0:
        return {
            'days_remaining': None,
            'runout_date': None,
            'confidence': 'low',
            'message': 'No usage recorded yet'
        }

    days_remaining = item.current_stock / daily_average
    runout_date = datetime.utcnow() + timedelta(days=days_remaining)

    return {
        'days_remaining': round(days_remaining, 1),
        'runout_date': runout_date.strftime('%A %d %B'),
        'confidence': 'low',
        'message': f'Early estimate based on {len(logs)} logs — accuracy improves over time'
    }