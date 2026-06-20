import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WCService {
  // =========================
  // SINGLETON
  // same instance everywhere
  // =========================
  static final WCService _instance = WCService._internal();
  factory WCService() => _instance;
  WCService._internal();

  static const _projectId = '7edfebf5fab6bb242644aa83ca3dde72';
  static const _suiChain = 'sui:testnet';

  Web3App? _wcClient;
  SessionData? _session;

  String? get walletAddress {
    if (_session == null) return null;
    final accounts = _session!.namespaces['sui']?.accounts ?? [];
    if (accounts.isEmpty) return null;
    return accounts.first.split(':').last;
  }

  bool get isConnected => _session != null;

  // =========================
  // INIT
  // safe to call multiple times
  // =========================
  Future<void> init() async {
    if (_wcClient != null) return; // already initialized

    _wcClient = await Web3App.createInstance(
      projectId: _projectId,
      metadata: const PairingMetadata(
        name: 'ArenaBet',
        description: 'ArenaBet — Reaction Betting App',
        url: 'https://arenabet.app',
        icons: ['https://arenabet.app/icon.png'],
        redirect: Redirect(
          native: 'arenabet://',
          universal: 'https://arenabet.app',
        ),
      ),
    );

    // restore existing session
    final sessions = _wcClient!.sessions.getAll();
    if (sessions.isNotEmpty) {
      _session = sessions.first;
      debugPrint('WC session restored: $walletAddress');
    }

    _wcClient!.onSessionDelete.subscribe((args) {
      debugPrint('WC session deleted');
      _session = null;
    });

    _wcClient!.onSessionExpire.subscribe((args) {
      debugPrint('WC session expired');
      _session = null;
    });
  }

  // =========================
  // CONNECT
  // =========================
  Future<String?> connect() async {
    await init();

    try {
      final connectResponse = await _wcClient!.connect(
        requiredNamespaces: {
          'sui': const RequiredNamespace(
            chains: [_suiChain],
            methods: [
              'sui:signAndExecuteTransactionBlock',
              'sui:signTransactionBlock',
            ],
            events: ['accountsChanged', 'chainChanged'],
          ),
        },
      );

      final wcUri = connectResponse.uri.toString();
      debugPrint('WC URI: $wcUri');

      final phantomUri = Uri.parse(
        'phantom://wc?uri=${Uri.encodeComponent(wcUri)}'
        '&ref=${Uri.encodeComponent('https://arenabet.app')}',
      );

      final launched = await launchUrl(
        phantomUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(
          Uri.parse(
            'https://phantom.app/ul/wc?uri=${Uri.encodeComponent(wcUri)}',
          ),
          mode: LaunchMode.externalApplication,
        );
      }

      _session = await connectResponse.session.future;
      debugPrint('WC connected: $walletAddress');
      return walletAddress;
    } catch (e) {
      debugPrint('WC connect error: $e');
      return null;
    }
  }

  // =========================
  // DEPOSIT TO ADMIN
  // =========================
  Future<String?> depositToAdmin({required String txBytes}) async {
    await init();

    if (_session == null) {
      debugPrint('No WC session — connecting first');
      final address = await connect();
      if (address == null) return null;
    }

    try {
      // reconnect relay — fixes code 1002 drop when app backgrounds
      await _wcClient!.core.relayClient.connect();
      await Future.delayed(const Duration(milliseconds: 800));

      // bring Phantom to foreground
      await launchUrl(
        Uri.parse('phantom://'),
        mode: LaunchMode.externalApplication,
      );

      final result = await _wcClient!.request(
        topic: _session!.topic,
        chainId: _suiChain,
        request: SessionRequestParams(
          method: 'sui:signAndExecuteTransactionBlock',
          params: {
            'transactionBlock': txBytes,
            'account': walletAddress,
            'chain': _suiChain,
            'options': {'showEffects': true, 'showEvents': true},
          },
        ),
      );

      debugPrint('Deposit result: $result');
      return result['digest'] as String?;
    } catch (e) {
      debugPrint('depositToAdmin error: $e');
      return null;
    }
  }

  // =========================
  // DISCONNECT
  // =========================
  Future<void> disconnect() async {
    if (_wcClient == null || _session == null) return;
    try {
      await _wcClient!.disconnectSession(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
      _session = null;
      debugPrint('WC disconnected');
    } catch (e) {
      debugPrint('WC disconnect error: $e');
    }
  }
}
