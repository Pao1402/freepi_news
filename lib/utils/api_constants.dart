class ApiConstants {
  ApiConstants._();

  // API pública temporal para desarrollar y probar la aplicación.
  // Cuando Freepi proporcione su portal activo, cambiaremos esta URL.
  static const String baseUrl = 'https://techcrunch.com/wp-json/wp/v2';

  static const String postsEndpoint = '/posts';
  static const String categoriesEndpoint = '/categories';

  static const int postsPerPage = 10;
}