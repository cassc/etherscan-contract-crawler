// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDescriptor {
  function tokenURI(uint256[8] calldata) external view returns (string memory);
}