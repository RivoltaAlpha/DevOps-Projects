export const orderRoutes = (app: any) => {
  app.get('/api/orders', (req: any, res: any) => {
    res.json({ message: 'Get all orders' });
  });

  app.get('/api/orders/user/:userId', (req: any, res: any) => {
    res.json({ message: `Get orders for user ${req.params.userId}` });
  });
};
