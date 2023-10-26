// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHasher {
  function poseidon(bytes32[2] calldata inputs) external pure returns (bytes32);

  function poseidon(bytes32[3] calldata inputs) external pure returns (bytes32);

  function MiMCSponge(
    uint256 in_xL,
    uint256 in_xR
  ) external pure returns (uint256 xL, uint256 xR);
}