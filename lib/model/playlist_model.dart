
/// 📁 مدل پلی‌لیست برای نگهداری اطلاعات پلی‌لیست

class PlaylistModel {
  int? id;
  String? title;
  String? url;
  String? filename;
  String? contentType;

  PlaylistModel({
    
    this.id,
    this.title,
    this.url,
    this.filename,
    this.contentType,

  });

  PlaylistModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    url = "http://${json['url']}";
    filename = json['filename'];
    contentType = json['content_type'];
  }
}