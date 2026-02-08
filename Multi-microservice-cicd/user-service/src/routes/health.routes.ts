export const healthRoutes = (app: any) => {
  app.get('/health', (req: any, res: any) => {
    res.json({ 
      status: 'UP',
      service: 'user-service',
      timestamp: new Date().toISOString()
    });
  });

  app.get('/ready', (req: any, res: any) => {
    res.json({ ready: true });
  });

  app.get('/live', (req: any, res: any) => {
    res.json({ alive: true });
  });
};
