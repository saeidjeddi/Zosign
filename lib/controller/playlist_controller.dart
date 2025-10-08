import 'package:get/get.dart';
import 'package:xixigol/components/url.dart';
import 'package:xixigol/model/playlist_model.dart';
import 'package:xixigol/services/dio_service.dart';

class PlaylistController extends GetxController {
  RxBool loading = false.obs;
  RxList<PlaylistModel> playlistList = RxList();

  getPlayList() async {
    loading.value = true;
    playlistList.clear();

    var response = await DioServices().getMethod(UrlPlaylist.playlist);

    if (response != null && response.statusCode == 200) {
      print("----------------------- Playlist -----------------------");
      print(response.data);
      for (var item in response.data) {
        playlistList.add(PlaylistModel.fromJson(item));

      }
    }

    loading.value = false;
  }
}
