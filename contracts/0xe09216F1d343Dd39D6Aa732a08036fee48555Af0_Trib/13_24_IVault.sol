// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IVault {
  function reserve() external view returns (address);

  function deposit(uint256) external returns (bool);

  function redeem(uint256) external returns (bool);

  // @dev Must return the total balance in reserve.
  function getBalance() external view returns (uint256);
}