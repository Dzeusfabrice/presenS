import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = "https://attendance-backend.basilo-store-api.workers.dev";

  print("--- Testing API Connectivity ---");

  // Test 1: GET /locations (Public?)
  print("\n1. Testing GET /locations (Should be public for registration):");
  try {
    final res = await http.get(Uri.parse("$baseUrl/locations"));
    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");
  } catch (e) {
    print("Error: $e");
  }

  // Test 2: POST /auth/login (With dummy)
  print("\n2. Testing POST /auth/login (With dummy data):");
  try {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'test@example.com', 'password': 'dummy'}),
    );
    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");
  } catch (e) {
    print("Error: $e");
  }

  print("\n--- End of Test ---");
}
