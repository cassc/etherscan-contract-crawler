// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVerifier {
  function verify(bytes32 domain, bytes32 structHash, bytes[] calldata signatures) external view returns (bool);
}