import 'dart:convert' as convert;
import 'package:cryptography/cryptography.dart';

class MyCrypt {
  final AesGcm aesGcm;
  MyCrypt() : aesGcm = AesGcm.with256bits();

  static const nonceLength = 12;
  static const macLength = 16;

  Future<SecretKey> getSecretKey(String key) async {
    return await aesGcm.newSecretKeyFromBytes(convert.base64.decode(key));
  }

  Future<String> generateSecretKey() async {
    final secretKey = await aesGcm.newSecretKey();
    final bytes = await secretKey.extractBytes();
    final keyAsString = convert.base64.encode(bytes);
    return keyAsString;
  }

  Future<String> encrypt(String text, String key) async {
    final secretKey = await getSecretKey(key);
    final secretBox = await aesGcm.encryptString(
      text,
      secretKey: secretKey,
    );
    // print(
    //     'Nonce = ${secretBox.nonce.length} and mac = ${secretBox.mac.bytes.length}');
    return convert.base64.encode(secretBox.concatenation());
  }

  Future<String> decrypt(String cipherText, String key) async {
    final secretKey = await getSecretKey(key);
    final data = convert.base64.decode(cipherText);
    final secretBox = SecretBox.fromConcatenation(data,
        nonceLength: nonceLength, macLength: macLength);
    final clearText = await aesGcm.decryptString(
      secretBox,
      secretKey: secretKey,
    );
    return clearText;
  }
}
