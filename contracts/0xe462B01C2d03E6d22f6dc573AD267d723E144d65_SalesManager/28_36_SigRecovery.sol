// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title SigRecovery
/// @dev This contract provides some helpers for signature recovery
library SigRecovery {
  /// @dev This method prefixes the provided message parameter with the message signing prefix, it also hashes the result as this hash is used in signature recovery
  /// @param _message The message to prefix
  function prefixMessageHash(
    bytes32 _message
  ) internal pure returns (bytes32 prefixedMessageHash) {
    prefixedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _message)
    );
  }

  /// @dev This method splits the signature, extracting the r, s and v values
  /// @param _sig The signature to split
  function splitSignature(
    bytes memory _sig
  ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_sig.length == 65, "Sig: Invalid signature length");

    assembly {
      // First 32 bytes holds the signature length, skips first 32 bytes as that is the prefix
      r := mload(add(_sig, 32))
      // Gets the following 32 bytes of the signature
      s := mload(add(_sig, 64))
      // Get the final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(_sig, 96)))
    }
  }

  /// @dev This method prefixes the provided message hash, splits the signature and uses ecrecover to return the signing address
  /// @param _message The message that was signed
  /// @param _signature The signature
  function recoverAddressFromMessage(
    bytes memory _message,
    bytes memory _signature
  ) internal pure returns (address recoveredAddress) {
    bytes32 hashOfMessage = prefixMessageHash(keccak256(_message));

    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    recoveredAddress = ecrecover(hashOfMessage, v, r, s);
  }
}