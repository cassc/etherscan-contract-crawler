pragma solidity 0.8.13;

/**
 * Helper library to recover admin signatures approving certain user's
 * as KYCed in the earthfund ecosystem.
 */

library SigRecovery {
  function recoverApproval(
    bytes memory _KYCId,
    address _user,
    uint256 _causeId,
    uint256 _expiry,
    bytes memory _signature
  ) internal pure returns (address recoveredAddress) {
    bytes32 messageHash = recreateApprovalHash(
      _KYCId,
      _user,
      _causeId,
      _expiry
    );

    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

    recoveredAddress = ecrecover(messageHash, v, r, s);
  }

  function recreateApprovalHash(
    bytes memory _KYCId,
    address _user,
    uint256 _causeId,
    uint256 _expiry
  ) internal pure returns (bytes32 messageHash) {
    messageHash = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encode(_KYCId, _user, _causeId, _expiry))
      )
    );
  }

  /// @notice Helper function for splitting the signature into its three parts; r s v.
  /// @dev This functions output is used when calling the ecrecover helper function
  /// @param sig  The signature to split
  /// @return r Output from the ECDSA signature
  /// @return s The other output from the ECDSA signature
  /// @return v The signature recovery ID
  function _splitSignature(bytes memory sig)
    private
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "Sig: Invalid signature length");

    assembly {
      // First 32 bytes holds the signature length, skips first 32 bytes as that is the prefix
      r := mload(add(sig, 32))
      // Gets the following 32 bytes of the signature
      s := mload(add(sig, 64))
      // Get the final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }
  }
}