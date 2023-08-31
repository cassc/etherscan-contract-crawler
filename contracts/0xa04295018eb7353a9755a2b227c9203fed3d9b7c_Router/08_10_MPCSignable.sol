// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MPCManageable.sol";

abstract contract MPCSignable is MPCManageable {
  modifier onlyMPCSignable(bytes32 hash, bytes memory signature) {
    _checkMPCSignable(hash, signature);
    _;
  }

  constructor(address _MPC) MPCManageable(_MPC) {}

  function _checkMPCSignable(bytes32 hash, bytes memory signature) internal view {
    bytes32 signedMessage = _getEthSignedMessageHash(hash);

    address signer = _recoverSigner(signedMessage, signature);

    require(signer != address(0x0), "MPCSignable: Nullable signer");
    require(signer == mpc(), "MPCSignable: Must be MPC");
  }

  function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

    return ECDSA.recover(_ethSignedMessageHash, v, r, s);
  }

  function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(sig.length == 65, "MPCSignable: Bad signature length");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }
}