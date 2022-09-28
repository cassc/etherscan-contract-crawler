// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
  function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claims(address) external view returns (uint256);
  function claim(address, uint256) external;
  function pay(uint256,uint256) external;
  function treasuryWallet() external view returns (address);
}