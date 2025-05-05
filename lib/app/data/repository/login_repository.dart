
import 'package:abaixaai/app/data/model/user_model.dart';
import 'package:abaixaai/app/data/service/sign_in.dart';

class LoginRepository {
  final SignInService signInService = SignInService();

  Future<UserModel?> signInGoogle(){
    return signInService.signInGoogle();
  }

  Future<UserModel?> trySignInGoogle(){
    return signInService.trySignInGoogle();
  }
  logoutGoogle(){
    signInService.logoutGoogle();
  }
}