//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFT {
  function maxSupply() external view returns (uint16);

  function totalSupply() external view returns (uint256);

  function mint(address to) external;
}