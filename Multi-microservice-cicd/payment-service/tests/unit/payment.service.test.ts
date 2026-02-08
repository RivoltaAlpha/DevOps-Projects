import { PaymentService } from '../../src/services/payment.service';

describe('PaymentService Unit Tests', () => {
  describe('findAll', () => {
    it('should return an array of payments', async () => {
      const payments = await PaymentService.findAll();
      expect(Array.isArray(payments)).toBe(true);
    });
  });

  describe('findById', () => {
    it('should return a payment by id', async () => {
      const paymentId = '123';
      const payment = await PaymentService.findById(paymentId);
      expect(payment).toBeDefined();
      expect(payment.id).toBe(paymentId);
    });
  });

  describe('findByOrderId', () => {
    it('should return payments for a specific order', async () => {
      const orderId = 'order123';
      const payments = await PaymentService.findByOrderId(orderId);
      expect(Array.isArray(payments)).toBe(true);
    });
  });

  describe('processPayment', () => {
    it('should process a payment', async () => {
      const paymentData = { 
        orderId: 'order123', 
        amount: 100,
        currency: 'USD'
      };
      const result = await PaymentService.processPayment(paymentData);
      expect(result).toBeDefined();
    });
  });

  describe('calculateFees', () => {
    it('should calculate payment fees correctly', async () => {
      const amount = 100;
      const fees = await PaymentService.calculateFees(amount);
      expect(typeof fees).toBe('number');
      expect(fees).toBeGreaterThan(0);
    });
  });

  describe('validatePaymentDetails', () => {
    it('should validate payment details', async () => {
      const paymentData = {
        cardNumber: '4242424242424242',
        cvv: '123',
        expiryDate: '12/25'
      };
      const isValid = await PaymentService.validatePaymentDetails(paymentData);
      expect(typeof isValid).toBe('boolean');
    });
  });
});
