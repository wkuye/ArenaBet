import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';
class PhantomSuiWebView extends StatefulWidget {
  final void Function(String address) onAddressReceived;
  final void Function(String error) onError;

  const PhantomSuiWebView({
    super.key,
    required this.onAddressReceived,
    required this.onError,
  });

  @override
  State<PhantomSuiWebView> createState() => _PhantomSuiWebViewState();
}

class _PhantomSuiWebViewState extends State<PhantomSuiWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // =========================
      // FLUTTER BRIDGE
      // JS calls FlutterBridge
      // .postMessage(address) to
      // return address to Flutter
      // =========================
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) {
          final message = msg.message;
          if (message.startsWith('ERROR:')) {
            widget.onError(message);
          } else {
            widget.onAddressReceived(message);
          }
        },
      )
      ..loadHtmlString(_connectHtml);
  }

  // =========================
  // HTML PAGE
  // Loads inside WebView and
  // calls window.phantom.sui
  // .connect() automatically
  // =========================

  static const String _connectHtml = '''
   <!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, sans-serif;
      background: #1a1a2e;
      color: white;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      text-align: center;
      padding: 20px;
      box-sizing: border-box;
    }
    .logo { font-size: 64px; margin-bottom: 16px; }
    h2 { margin: 0 0 8px; }
    p  { color: #aaa; font-size: 14px; margin-bottom: 32px; }
    button {
      background: #ab9ff2;
      color: white;
      border: none;
      border-radius: 12px;
      padding: 16px 40px;
      font-size: 16px;
      font-weight: 700;
      cursor: pointer;
      width: 100%;
      max-width: 300px;
    }
    #status { margin-top: 16px; color: #aaa; font-size: 13px; }
  </style>
</head>
<body>
  <div class="logo">👻</div>
  <h2>Connect Phantom</h2>
  <p>Connect your Sui wallet to ArenaBet</p>
  <button onclick="connectSui()">Connect Wallet</button>
  <div id="status"></div>

  <script>
    function setStatus(msg) {
      document.getElementById('status').innerText = msg;
    }

    async function connectSui() {
      try {
        setStatus('Connecting...');

        const provider = window?.phantom?.sui;
        if (!provider) {
          setStatus('Please open this page inside Phantom app.');
          return;
        }

        const accounts = await provider.connect();

        if (!accounts || accounts.length === 0) {
          setStatus('No accounts found.');
          return;
        }

        const address = accounts[0].address;
        setStatus('Connected! Redirecting...');

        // =========================
        // REDIRECT BACK TO YOUR APP
        // with the Sui address as
        // a query param via deeplink
        // =========================
        window.location.href = 'arenabet://sui-connect?address=' + address;

      } catch (e) {
        setStatus('Error: ' + e.message);
      }
    }
  </script>
</body>
</html>
  ''';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}