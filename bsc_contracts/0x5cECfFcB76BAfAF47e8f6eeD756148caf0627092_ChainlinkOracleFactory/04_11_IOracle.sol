// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

interface IOracle {
  // token in, USDT out
  function price(uint amount) external view returns (uint256 answer);
  // USDT in, token out
  function reversePrice(uint amount) external view returns (uint256 answer);

  function description() external view returns (string memory);
}