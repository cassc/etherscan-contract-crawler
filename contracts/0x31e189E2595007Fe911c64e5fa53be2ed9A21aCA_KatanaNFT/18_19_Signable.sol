// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ISignable.sol';

abstract contract Signable is ISignable {
  struct Signature {
    bytes32 nonce;
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  bytes32 private _uniq;
  mapping(bytes32 => bool) private _signatures;

  constructor() {
    _uniq = keccak256(abi.encodePacked(block.timestamp, address(this)));
  }

  function uniq() public view virtual override(ISignable) returns (bytes32) {
    return _uniq;
  }

  modifier verifySignature(bytes memory message, Signature memory signature) {
    address _signer = this.signer();
    require(_signer != address(0), 'Signable: signer not initialised');

    bytes32 signatureHash = keccak256(abi.encode(signature));
    require(!_signatures[signatureHash], 'Signable: signature already used');

    require(
      _signer ==
        ecrecover(
          keccak256(abi.encode(_uniq, signature.nonce, msg.sender, message)),
          signature.v,
          signature.r,
          signature.s
        ),
      'Signable: invalid signature'
    );
    _signatures[signatureHash] = true;
    _;
  }
}