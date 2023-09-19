// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ChiErrors {
  error ZeroAddress();
  error NotMinter(address _account);
  error ZeroAmount();
  error UnderMinAmount(uint256 _amount);
  error OverMaxAmount(uint256 _amount);
  error NotEnoughAmount(uint256 _amount);
  error NotStarted(uint256 _timestamp);
  error Ended(uint256 _timestamp);
  error InvalidProof(address _account);
}