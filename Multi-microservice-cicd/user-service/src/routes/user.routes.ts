export const userRoutes = (app: any) => {
  // Routes will be implemented here
  app.get('/api/users', (req: any, res: any) => {
    res.json({ message: 'Get all users' });
  });
};
