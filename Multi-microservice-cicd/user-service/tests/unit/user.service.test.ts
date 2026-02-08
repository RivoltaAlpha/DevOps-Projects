import { UserService } from '../../src/services/user.service';

describe('UserService Unit Tests', () => {
  describe('findAll', () => {
    it('should return an array of users', async () => {
      const users = await UserService.findAll();
      expect(Array.isArray(users)).toBe(true);
    });
  });

  describe('findById', () => {
    it('should return a user by id', async () => {
      const userId = '123';
      const user = await UserService.findById(userId);
      expect(user).toBeDefined();
      expect(user.id).toBe(userId);
    });
  });

  describe('create', () => {
    it('should create a new user', async () => {
      const userData = { email: 'test@example.com', name: 'Test User' };
      const result = await UserService.create(userData);
      expect(result).toBeDefined();
    });
  });
});
