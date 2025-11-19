class ApiService {
  // TODO: Change this to your Render URL after deployment
  static const String baseUrl = 'http://localhost:8000';
  
  // Endpoints
  static String createGroup() => '$baseUrl/groups';
  static String joinGroup(int groupId) => '$baseUrl/groups/$groupId/join';
  static String getGroup(int groupId) => '$baseUrl/groups/$groupId';
  static String addExclusion(int groupId) => '$baseUrl/groups/$groupId/exclude';
  static String drawNames(int groupId) => '$baseUrl/groups/$groupId/draw';
  static String getMyTarget(int groupId, int participantId) => 
      '$baseUrl/groups/$groupId/my-target/$participantId';
}
