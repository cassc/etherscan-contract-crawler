// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface VaultInterface {

  function deposit(uint256 amount_) external returns (uint256);

  function withdraw(uint256 maxShares, address recipient) external returns (uint256);

  function balanceOf(address user_) view external returns(uint256);

  function pricePerShare() external view returns (uint256);
}