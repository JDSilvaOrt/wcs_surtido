import 'package:ntlm/ntlm.dart';
import 'package:xml/xml.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'credentials_service.dart'; 

class StockItemResponse {
  final String epc;
  final String inventoryId;
  final bool success;

  StockItemResponse({
    required this.epc,
    required this.inventoryId,
    required this.success,
  });
}

class StockItemService {
  
  static Future<StockItemResponse?> fetchInventoryId(String epcScanned) async {
    try {
      log("StockItemService: Solicitando Inventory ID para EPC: $epcScanned");
      
      final List<StockItemResponse> responses = await _fetchInventoryIdsFromSoap([epcScanned]);

      if (responses.isEmpty) {
        log("StockItemService: No se recibieron respuestas del servicio SOAP.");
        return null; 
      }

      final responseForEpc = responses.first;
      log("StockItemService: Respuesta recibida para $epcScanned. Éxito: ${responseForEpc.success}");
      return responseForEpc;

    } catch (e) {
      log("StockItemService: Ocurrió un error en fetchInventoryId: $e");
      // Limpiamos el mensaje de error para que la notificación roja en pantalla sea clara
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  static Future<List<StockItemResponse>> _fetchInventoryIdsFromSoap(List<String> epcList) async {
    // 1. OBTENEMOS EL CLIENTE NTLM
    final NTLMClient client;
    try {
      client = await CredentialsService.getNtlmClient();
    } catch(e) {
      throw Exception("Error de credenciales: $e");
    }

    // 2. OBTENEMOS LA URL DINÁMICA DE LA CONFIGURACIÓN
    final prefs = await SharedPreferences.getInstance();
    final String soapUrlStr = prefs.getString('soap_url') ?? 'http://172.30.27.22/RivStockItemSkuService/RivStockItemSkuServiceIIS/xppservice.svc';
    
    final url = Uri.parse(soapUrlStr);
    const soapAction = 'http://tempuri.org/RivStockItemSkuService/sendInfoList';
    const company = 'RIVE';

    String generarLineasXml() {
      final buffer = StringBuffer();
      for (var epc in epcList) {
        buffer.writeln('''
        <dyn:RivStockItemSkuContract>
            <dyn:itemBarCode>$epc</dyn:itemBarCode>
        </dyn:RivStockItemSkuContract>
        ''');
      }
      return buffer.toString();
    }

    final soapBody = '''<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:dat="http://schemas.microsoft.com/dynamics/2010/01/datacontracts"
                  xmlns:tem="http://tempuri.org"
                  xmlns:dyn="http://schemas.datacontract.org/2004/07/Dynamics.Ax.Application">
    <soapenv:Header>
        <dat:CallContext>
            <dat:Company>$company</dat:Company>
        </dat:CallContext>
    </soapenv:Header>
    <soapenv:Body>
        <tem:RivStockItemSkuServiceSendInfoListRequest>
            <tem:_contractLine>
                ${generarLineasXml()}
            </tem:_contractLine>
        </tem:RivStockItemSkuServiceSendInfoListRequest>
    </soapenv:Body>
</soapenv:Envelope>''';

    try {
      // 3. ENVIAMOS LA PETICIÓN
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': soapAction,
        },
        body: soapBody,
      );

      // 4. VALIDAMOS EL 401 U OTROS ERRORES
      if (response.statusCode == 401) {
        throw Exception('Error 401: Usuario o contraseña NTLM incorrectos o sin permisos.');
      } else if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      // 5. PARSEAMOS LA RESPUESTA XML
      final xml = XmlDocument.parse(response.body);
      const ns = 'http://schemas.datacontract.org/2004/07/Dynamics.Ax.Application';
      final responseElements = xml.findAllElements('RivStockItemSkuResponse', namespace: ns);

      if (responseElements.isEmpty) {
        return [];
      }

      return responseElements.map((node) {
        final epc = node.getElement('epc', namespace: ns)?.innerText ?? '';
        final inventoryId = node.getElement('inventoryId', namespace: ns)?.innerText ?? '';
        final success = node.getElement('success', namespace: ns)?.innerText.toLowerCase() == 'true';
        return StockItemResponse(epc: epc, inventoryId: inventoryId, success: success);
      }).toList();

    } catch (e) {
      throw Exception('Fallo en la comunicación SOAP: $e');
    }
  }
}