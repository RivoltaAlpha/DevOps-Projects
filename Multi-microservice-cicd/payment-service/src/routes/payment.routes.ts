export const paymentRoutes = (app: any) => {
  app.get('/api/payments', (req: any, res: any) => {
    res.json({ message: 'Get all payments' });
  });

  app.get('/api/payments/order/:orderId', (req: any, res: any) => {
    res.json({ message: `Get payments for order ${req.params.orderId}` });
  });

  app.post('/api/payments', (req: any, res: any) => {
    res.json({ message: 'Process payment' });
  });
};
