class ArticleModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorRole;
  final DateTime createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorRole,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        "title": title,
        "content": content,
        "imageUrl": imageUrl,
        "authorRole": authorRole,
        "createdAt": createdAt,
      };

  factory ArticleModel.fromMap(String id, Map<String, dynamic> map) {
    return ArticleModel(
      id: id,
      title: map["title"],
      content: map["content"],
      imageUrl: map["imageUrl"],
      authorRole: map["authorRole"],
      createdAt: map["createdAt"].toDate(),
    );
  }
}
