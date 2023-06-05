// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ISignatureVerifier {
  function verifySignature(bytes32 _hash, bytes memory _signature) external view returns (bool);
}