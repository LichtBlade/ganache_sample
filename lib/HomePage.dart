import 'package:flutter/material.dart';
import 'package:web3modal_flutter/services/w3m_service/w3m_service.dart';
import 'package:reown_appkit/reown_appkit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ReownAppKitModal _appKitModal;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeState();
  }

  void initializeState() async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId:
          'd1ab4e071f6f9a4d2bed6f72e44bf4d0', // Replace with your project ID
      metadata: const PairingMetadata(
        name: 'Example App',
        description: 'Example app description',
        url: 'https://example.com/',
        icons: ['https://example.com/logo.png'],
        redirect: Redirect(
          native: 'exampleapp://',
          universal: 'https://reown.com/exampleapp',
        ),
      ),
    );

    await _appKitModal.init();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blockchain App"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Network Select Button
            AppKitModalNetworkSelectButton(appKit: _appKitModal),

            // Connect Button
            AppKitModalConnectButton(appKit: _appKitModal),

            // Visibility: Display Account Button if connected
            Visibility(
              visible: _appKitModal.isConnected,
              child: AppKitModalAccountButton(appKit: _appKitModal),
            ),

            const SizedBox(height: 20),

            // Custom button to open QR Code page directly
            ElevatedButton(
              onPressed: () {
                _appKitModal.openModalView(ReownAppKitModalQRCodePage());
              },
              child: const Text('OPEN QR CODE PAGE'),
            ),

            // Custom button to open All Wallets screen directly
          ],
        ),
      ),
    );
  }
}
