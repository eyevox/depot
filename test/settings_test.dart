import 'package:depot/depot.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> authGWSettings = {
    'exampleGatewayAddress': 'https:/example.com/gw',
    'retryTimes': '3',
    'retryInterval': '10',
  };

  group('Local depot testing', () {
    Depot().localRegister<SettingsModuleFacade>(
        constructor: SettingsModuleFacade.new, module: SettingsModule(), name: SettingsModuleFacade.name);

    test('AddSettings', () async {
      // Задержка обеспечивает гарантию защиты от гонки и правильную работу ожидания сигналинга завершения загрузки настроек
      Future.delayed(Duration(milliseconds: 150), () async {
        // print('>>>> Future started');
        await Depot<SettingsModuleFacade>().request<void>().addSettings(authGWSettings);
        // print('>>>> Settings added');
        Depot<SettingsModuleFacade>().command().finalize();
      });
      // await Depot<SettingsModuleFacade>().request<void>().addSettings(authGWSettings);
      // print('>>>> Future fired');
      final result = await Depot<SettingsModuleFacade>().request<String>().getSettings('exampleGatewayAddress');
      // print('>>>> $result');
      expect(result, 'https:/example.com/gw');
    });
  });
}
