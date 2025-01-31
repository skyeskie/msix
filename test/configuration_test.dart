import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'package:msix/src/configuration.dart';
import 'package:test/test.dart';

const tempFolderPath = 'test/configuration_temp';
const yamlTestPath = '$tempFolderPath/test.yaml';

void main() {
  var log = Logger.verbose();
  late Configuration config;
  const yamlContent = '''

name: testAppName

msix_config:  
  ''';

  setUp(() async {
    config = Configuration([], log)
      ..pubspecYamlPath = yamlTestPath
      ..buildFilesFolder = tempFolderPath;

    await Directory('$tempFolderPath/').create(recursive: true);
    await Future.delayed(Duration(milliseconds: 150));
  });

  tearDown(() async {
    if (await Directory('$tempFolderPath/').exists()) {
      await Future.delayed(Duration(milliseconds: 150));
      await Directory('$tempFolderPath/').delete(recursive: true);
      await Future.delayed(Duration(milliseconds: 150));
    }
  });

  group('app name:', () {
    test('valid app name', () async {
      await File(yamlTestPath).writeAsString('name: testAppName123');
      await config.getConfigValues();
      expect(config.appName, 'testAppName123');
    });

    test('with out app name', () async {
      await File(yamlTestPath).writeAsString('name:');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate(
              (String error) => error.contains('App name is empty'))));
    });

    test('with out app name property', () async {
      await File(yamlTestPath).writeAsString('description:');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate(
              (String error) => error.contains('App name is empty'))));
    });
  });

  test('valid description', () async {
    await File(yamlTestPath)
        .writeAsString('description: description123' + yamlContent);
    await config.getConfigValues();
    expect(config.appDescription, 'description123');
  });

  group('msix version:', () {
    test('valid version in yaml', () async {
      await File(yamlTestPath)
          .writeAsString(yamlContent + 'msix_version: 1.2.3.4');
      await config.getConfigValues();
      expect(config.msixVersion, '1.2.3.4');
    });

    test('invalid version letter in yaml', () async {
      await File(yamlTestPath)
          .writeAsString(yamlContent + 'msix_version: 1.s.3.4');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate((String error) =>
              error.contains('msix version can be only in this format'))));
    });

    test('invalid version space in yaml', () async {
      await File(yamlTestPath)
          .writeAsString(yamlContent + 'msix_version: 1.s. 3.4');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate((String error) =>
              error.contains('msix version can be only in this format'))));
    });

    test('valid version in long argument', () async {
      await File(yamlTestPath).writeAsString(yamlContent);
      var customConfig = Configuration(['--version', '1.2.3.4'], log)
        ..pubspecYamlPath = yamlTestPath
        ..buildFilesFolder = tempFolderPath;
      await customConfig.getConfigValues();
      expect(customConfig.msixVersion, '1.2.3.4');
    });

    test('invalid version letter in long argument', () async {
      await File(yamlTestPath).writeAsString(yamlContent);
      var customConfig = Configuration(['--version', '1.s.3.4'], log)
        ..pubspecYamlPath = yamlTestPath
        ..buildFilesFolder = tempFolderPath;
      await customConfig.getConfigValues();
      await expectLater(
          customConfig.validateConfigValues,
          throwsA(predicate((String error) =>
              error.contains('msix version can be only in this format'))));
    });

    test('setting version with old -v options', () async {
      await File(yamlTestPath).writeAsString(yamlContent);
      var customConfig = Configuration(['-v', '1.2.3.4'], log)
        ..pubspecYamlPath = yamlTestPath
        ..buildFilesFolder = tempFolderPath;
      await customConfig.getConfigValues();
      expect(config.msixVersion, isNull);
    });
  });

  group('certificate:', () {
    test('exited certificate path with password', () async {
      const pfxTestPath = '$tempFolderPath/test.pfx';
      await File(pfxTestPath).create();
      await File(yamlTestPath).writeAsString(yamlContent +
          '''certificate_path: $pfxTestPath  
  certificate_password: 1234''');
      await config.getConfigValues();
      expect(config.certificatePath, pfxTestPath);
    });

    test('invalid certificate path', () async {
      await File(yamlTestPath).writeAsString(
          yamlContent + 'certificate_path: $tempFolderPath/test123.pfx');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate((String error) =>
              error.contains('The file certificate not found in'))));
    });

    test('certificate without password', () async {
      const pfxTestPath = '$tempFolderPath/test.pfx';
      await File(pfxTestPath).create();
      await File(yamlTestPath)
          .writeAsString(yamlContent + 'certificate_path: $pfxTestPath');
      await config.getConfigValues();
      await expectLater(
          config.validateConfigValues,
          throwsA(predicate((String error) =>
              error.contains('Certificate password is empty'))));
    });
  });
}
