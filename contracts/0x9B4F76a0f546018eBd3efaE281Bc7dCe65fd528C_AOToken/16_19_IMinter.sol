// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMinter {
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}