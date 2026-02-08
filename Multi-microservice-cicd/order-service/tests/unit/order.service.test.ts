import { OrderService } from '../../src/services/order.service';

describe('OrderService Unit Tests', () => {
  describe('findAll', () => {
    it('should return an array of orders', async () => {
      const orders = await OrderService.findAll();
      expect(Array.isArray(orders)).toBe(true);
    });
  });

  describe('findById', () => {
    it('should return an order by id', async () => {
      const orderId = '123';
      const order = await OrderService.findById(orderId);
      expect(order).toBeDefined();
      expect(order.id).toBe(orderId);
    });
  });

  describe('findByUserId', () => {
    it('should return orders for a specific user', async () => {
      const userId = 'user123';
      const orders = await OrderService.findByUserId(userId);
      expect(Array.isArray(orders)).toBe(true);
    });
  });

  describe('create', () => {
    it('should create a new order', async () => {
      const orderData = { userId: 'user123', items: [] };
      const result = await OrderService.create(orderData);
      expect(result).toBeDefined();
    });
  });

  describe('calculateTotal', () => {
    it('should calculate order total', async () => {
      const items = [
        { price: 10, quantity: 2 },
        { price: 5, quantity: 1 }
      ];
      const total = await OrderService.calculateTotal(items);
      expect(typeof total).toBe('number');
    });
  });
});
