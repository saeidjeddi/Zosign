



import 'package:dio/dio.dart';

class DioServices {

  Future<dynamic> getMethod(String url) async {
     Dio dio = Dio();

  dio.options.headers["content-type"] = "application/json";
  
  try {
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.json),
    );

    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      return e.response; 
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}







}




