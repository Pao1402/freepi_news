import 'package:dio/dio.dart';

import '../models/news_category.dart';
import '../models/news_post.dart';
import '../utils/api_constants.dart';

class WordPressService {
  WordPressService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;

  Future<List<NewsPost>> getPosts({
    String search = '',
    int? categoryId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        '_embed': true,
        'per_page': perPage,
        'page': page,
        'orderby': 'date',
        'order': 'desc',
      };

      if (search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (categoryId != null) {
        queryParameters['categories'] = categoryId;
      }

      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: queryParameters,
      );

      if (response.data is! List) {
        throw Exception(
          'La API no devolvió una lista de noticias.',
        );
      }

      final postsJson = response.data as List<dynamic>;

      return postsJson
          .whereType<Map<String, dynamic>>()
          .map(NewsPost.fromJson)
          .toList();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final statusCode = error.response?.statusCode;

      /*
       * WordPress devuelve un error 400 cuando se solicita
       * una página que ya no existe.
       *
       * Si ocurre después de la primera página, significa
       * que llegamos al final de la lista y no que haya
       * fallado la conexión.
       */
      final isInvalidPaginationPage =
          page > 1 &&
          responseData is Map &&
          (responseData['code'] ==
                  'rest_post_invalid_page_number' ||
              responseData['code'] ==
                  'rest_invalid_page_number');

      if (isInvalidPaginationPage) {
        return [];
      }

      /*
       * Algunas instalaciones de WordPress responden
       * únicamente con HTTP 400, sin incluir correctamente
       * el código rest_post_invalid_page_number.
       */
      if (page > 1 && statusCode == 400) {
        return [];
      }

      throw Exception(
        _getDioErrorMessage(error),
      );
    } catch (error) {
      /*
       * Evita agregar "Exception:" dos veces cuando el error
       * ya fue creado dentro del bloque anterior.
       */
      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      throw Exception(
        'No fue posible cargar las noticias: $message',
      );
    }
  }

  Future<List<NewsCategory>> getCategories() async {
    try {
      final response = await _dio.get(
        ApiConstants.categoriesEndpoint,
        queryParameters: {
          'per_page': 100,
          'orderby': 'count',
          'order': 'desc',
          'hide_empty': true,
        },
      );

      if (response.data is! List) {
        throw Exception(
          'La API no devolvió una lista de categorías.',
        );
      }

      final categoriesJson = response.data as List<dynamic>;

      return categoriesJson
          .whereType<Map<String, dynamic>>()
          .map(NewsCategory.fromJson)
          .where((category) => category.count > 0)
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _getDioErrorMessage(error),
      );
    } catch (error) {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      throw Exception(
        'No fue posible cargar las categorías: $message',
      );
    }
  }

  String _getDioErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'La conexión tardó demasiado tiempo.';
    }

    if (error.type == DioExceptionType.sendTimeout) {
      return 'La solicitud tardó demasiado tiempo en enviarse.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'El servidor tardó demasiado tiempo en responder.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar. Revisa tu conexión a internet.';
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 400) {
        return 'La solicitud enviada a la API no es válida.';
      }

      if (statusCode == 401 || statusCode == 403) {
        return 'No tienes autorización para consultar esta información.';
      }

      if (statusCode == 404) {
        return 'No se encontró el endpoint de noticias.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'El servidor de noticias presenta un error interno.';
      }

      return 'La API respondió con el código '
          '${statusCode ?? "desconocido"}.';
    }

    if (error.type == DioExceptionType.cancel) {
      return 'La solicitud fue cancelada.';
    }

    if (error.type == DioExceptionType.badCertificate) {
      return 'El certificado de seguridad del sitio no es válido.';
    }

    return 'Ocurrió un error inesperado al conectar con la API.';
  }
}