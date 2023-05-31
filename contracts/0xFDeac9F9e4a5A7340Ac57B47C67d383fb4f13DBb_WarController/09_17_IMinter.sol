// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IMinter {
  function mint(address vlToken, uint256 amount) external;
  function mintMultiple(address[] calldata vlTokens, uint256[] calldata amounts) external;
}