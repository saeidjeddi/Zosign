class PlaylistModel {
  int? id;
  String? title;
  String? url;
  String? filename;
  String? content_type;

  PlaylistModel({
    this.id,
    this.title,
    this.url,
    this.filename,
    this.content_type,
  });

  PlaylistModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    url = "http://${json['url']}";
    filename = json['filename'];
    content_type = json['content_type'];
  }
}
