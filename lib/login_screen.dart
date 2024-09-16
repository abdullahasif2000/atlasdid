import 'package:flutter/material.dart';
import 'MaterialInputScreen.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  late ApiService apiService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://10.7.1.145/devm/Did-Material/public/index.php');
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.login(_email, _password);

        print('Login response: $response');

        if (response['status'] == 200) {
          final accessToken = response['access_token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MaterialInputScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid credentials')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/images/Atlas.png',
                  height: 80.0,
                ),
              ),
              SizedBox(height: 30.0),
              Text(
                'SIGN INTO YOUR ACCOUNT',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30.0),
              Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 8,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/login.png',
                        height: 60.0,
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(bottom: 16.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Enter Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _email = value!;
                              },
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 16.0),
                            child: TextFormField(
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Enter Password',
                                prefixIcon: Icon(Icons.key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _password = value!;
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.yellow[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: 25.0,
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.0),
              Text(
                '© 2024 Atlas. All Rights Reserved',
                style: TextStyle(
                  color: Colors.red[900],
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}