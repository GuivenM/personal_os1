import '../api/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardApi {
  DashboardApi(this._client);

  final ApiClient _client;

  Future<DashboardResponse> getDashboard() async {
    final json = await _client.get('/dashboard');
    return DashboardResponse.fromJson(json as Map<String, dynamic>);
  }
}
