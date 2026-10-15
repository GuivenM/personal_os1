import '../api/api_client.dart';
import '../models/vision_model.dart';

class VisionApi {
  VisionApi(this._client);

  final ApiClient _client;

  Future<VisionResponse> getVision() async {
    final json = await _client.get('/vision');
    return VisionResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateVisionText(String visionText) async {
    await _client.put('/vision', body: {'vision_text': visionText});
  }

  Future<Goal> addGoal({required String title, required String horizon, String status = 'active'}) async {
    final json = await _client.post('/vision/goals', body: {
      'title': title,
      'horizon': horizon,
      'status': status,
    });
    return Goal.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateGoal(int id, {String? title, String? horizon, String? status}) async {
    await _client.put('/vision/goals/$id', body: {
      if (title != null) 'title': title,
      if (horizon != null) 'horizon': horizon,
      if (status != null) 'status': status,
    });
  }

  Future<void> deleteGoal(int id) async {
    await _client.delete('/vision/goals/$id');
  }
}
