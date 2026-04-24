from flask import Blueprint, render_template, request, redirect, url_for, flash
from app import db
from app.models import Item, StockLog
from app.predictions import get_prediction

main = Blueprint('main', __name__)

@main.route('/')
def dashboard():
    items = Item.query.all()
    predictions = {item.id: get_prediction(item) for item in items}
    return render_template('dashboard.html', items=items, predictions=predictions)

@main.route('/add-item', methods=['GET', 'POST'])
def add_item():
    if request.method == 'POST':
        name = request.form.get('name')
        unit = request.form.get('unit')
        current_stock = float(request.form.get('current_stock'))
        low_threshold = float(request.form.get('low_threshold'))

        item = Item(
            name=name,
            unit=unit,
            current_stock=current_stock,
            low_threshold=low_threshold
        )
        db.session.add(item)
        db.session.commit()
        flash(f'{name} added successfully', 'success')
        return redirect(url_for('main.dashboard'))

    return render_template('add_item.html')

@main.route('/log-usage/<int:item_id>', methods=['GET', 'POST'])
def log_usage(item_id):
    item = Item.query.get_or_404(item_id)

    if request.method == 'POST':
        quantity_used = float(request.form.get('quantity_used'))
        logged_by = request.form.get('logged_by', 'staff')

        # Update current stock
        item.current_stock -= quantity_used

        # Create log entry
        log = StockLog(
            item_id=item.id,
            quantity_used=quantity_used,
            logged_by=logged_by
        )
        db.session.add(log)
        db.session.commit()
        flash(f'Usage logged for {item.name}', 'success')
        return redirect(url_for('main.dashboard'))

    return render_template('log_usage.html', item=item)

@main.route('/delete-item/<int:item_id>')
def delete_item(item_id):
    item = Item.query.get_or_404(item_id)
    
    # Delete related stock logs first before deleting item
    StockLog.query.filter_by(item_id=item.id).delete()
    
    db.session.delete(item)
    db.session.commit()
    flash(f'{item.name} deleted', 'success')
    return redirect(url_for('main.dashboard'))