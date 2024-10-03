import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class SendEth extends StatefulWidget {
  const SendEth({super.key});

  @override
  State<SendEth> createState() => _SendEthState();
}

class _SendEthState extends State<SendEth> {
  String rpcUrl = "http://10.0.2.2:7545"; // For Android emulator
  String wsUrl = "ws://10.0.2.2:7545/";

  double phimcoin = 0.0;
  double ethToPhpRate = 0.0;
  double ethAmount = 0.0;
  double convertedPhimcoinValue = 0.0;
  double currentEthBalance = 0.0;

  TextEditingController phimcoinController =
      TextEditingController(); // Controller for Phimcoin input

  @override
  void initState() {
    super.initState();
    fetchEtherPrice();
    fetchEthBalance();
  }

  Future<void> fetchEtherPrice() async {
    const url =
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=php';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Decode the JSON response
        var data = jsonDecode(response.body);
        setState(() {
          ethToPhpRate =
              data['ethereum']['php'].toDouble(); // Ether price in PHP
        });
      } else {
        throw Exception('Failed to load Ether price');
      }
    } catch (e) {
      print("Error fetching Ether price: $e");
    }
  }

  // Fetch the current balance of the Ethereum wallet
  Future<void> fetchEthBalance() async {
    // Create Web3 client
    Web3Client client = Web3Client(
      rpcUrl,
      http.Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(wsUrl).cast<String>();
      },
    );

    // Private key
    String privateKey =
        "0xb92508c3bb483e1f2d48b49f419594fc6d3b8a0f6ee0aa2657a9497d8edc5796";

    // Obtain credentials from private key
    Credentials credentials =
        await client.credentialsFromPrivateKey(privateKey);

    // Get your Ethereum address from the credentials
    EthereumAddress ownAddress = await credentials.extractAddress();

    // Fetch balance
    EtherAmount balance = await client.getBalance(ownAddress);
    setState(() {
      currentEthBalance =
          balance.getValueInUnit(EtherUnit.ether); // Convert balance to ETH
    });
  }

  // Convert Phimcoin (PHP) to Ether (ETH)
  void convertPhimcoinToEth(double phimcoinAmount) {
    setState(() {
      ethAmount =
          phimcoinAmount / ethToPhpRate; // Convert PHP (Phimcoin) to ETH
      convertedPhimcoinValue =
          phimcoinAmount; // Store the converted Phimcoin value
      phimcoin += convertedPhimcoinValue;
    });
  }

  Future<void> sendEther() async {
    // Create Web3 client
    Web3Client client = Web3Client(
      rpcUrl,
      http.Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(wsUrl).cast<String>();
      },
    );

    // Private key (use a test key for Ganache or testnets)
    String privateKey =
        "0xb92508c3bb483e1f2d48b49f419594fc6d3b8a0f6ee0aa2657a9497d8edc5796";

    // Obtain credentials from private key
    Credentials credentials =
        await client.credentialsFromPrivateKey(privateKey);

    EthereumAddress receiver =
        EthereumAddress.fromHex("0xBf7a5d0b8F19998eED5ff46B6785e6a3066b2c1c");

    EthereumAddress ownAddress = await credentials.extractAddress();
    print("Own Address: $ownAddress");

    try {
      // Convert ethAmount (ETH) to Wei
      BigInt weiAmount =
          BigInt.from(ethAmount * 1e18); // Multiply ETH by 10^18 to get Wei

      // Send Ether transaction
      var result = await client.sendTransaction(
        credentials,
        Transaction(
          from: ownAddress,
          to: receiver,
          value: EtherAmount.inWei(weiAmount), // Use the Wei amount
          gasPrice:
              EtherAmount.inWei(BigInt.from(1000000000)), // Set a gas price
          maxGas: 21000, // Set gas limit
        ),
        chainId:
            1337, // Ganache default chain ID (for other networks, adjust accordingly)
      );
      print("Transaction Hash: $result \n\n Successful Transaction");

      // After sending ETH, fetch the updated balance
      fetchEthBalance();
    } catch (e) {
      print("Transaction failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Convert Phimcoin to ETH and Send \n PhimCoin: ${phimcoin.toString()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the current ETH balance
            Text(
              currentEthBalance > 0
                  ? "Current ETH Balance: ${currentEthBalance.toStringAsFixed(8)} ETH"
                  : "Fetching ETH balance...",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            // Display Ether to PHP conversion rate (Phimcoin rate)
            Text(
              ethToPhpRate > 0
                  ? "1 ETH = ₱${ethToPhpRate.toStringAsFixed(2)} PHP"
                  : "Fetching Ether price in PHP...",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            // TextField to input the amount of Phimcoin (PHP equivalent)
            TextField(
              controller: phimcoinController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter amount of Phimcoin (PHP) to convert',
              ),
              keyboardType: TextInputType.number, // Numeric input
            ),
            const SizedBox(height: 20),

            // Display the exact converted ETH value
            Text(
              ethAmount > 0
                  ? "Equivalent ETH: ${ethAmount.toStringAsFixed(8)} ETH"
                  : "Enter Phimcoin to see ETH conversion",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            // Display the converted Phimcoin value after transaction
            Text(
              convertedPhimcoinValue > 0
                  ? "Transferred Phimcoin Value: ₱${convertedPhimcoinValue.toStringAsFixed(2)}"
                  : "No Phimcoin value calculated yet",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (phimcoinController.text.isNotEmpty) {
                  double phimcoinAmount = double.parse(phimcoinController.text);
                  convertPhimcoinToEth(
                      phimcoinAmount); // Convert Phimcoin to ETH
                  sendEther(); // Send the converted ETH
                } else {
                  print("Please enter a valid Phimcoin amount");
                }
              },
              child: const Text('Convert Phimcoin to ETH and Send'),
            ),
          ],
        ),
      ),
    );
  }
}
