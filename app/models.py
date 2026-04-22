from app import db
from datetime import datetime

class Item(db.Model):
    __tablename__ = 'items'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    unit = db.Column(db.String(20), nullable=False)
    current_stock = db.Column(db.Float, nullable=False, default=0)
    low_threshold = db.Column(db.Float, nullable=False, default=10)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    logs = db.relationship('StockLog', backref='item', lazy=True)

    def __repr__(self):
        return f'<Item {self.name}>'


class StockLog(db.Model):
    __tablename__ = 'stock_logs'

    id = db.Column(db.Integer, primary_key=True)
    item_id = db.Column(db.Integer, db.ForeignKey('items.id'), nullable=False)
    quantity_used = db.Column(db.Float, nullable=False)
    logged_by = db.Column(db.String(100), nullable=False, default='staff')
    logged_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<StockLog {self.item_id} - {self.quantity_used}>'