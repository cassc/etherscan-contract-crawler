// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKochiVest {
  enum EVestType {
    linear
  }

  struct SVestMetadata {
    EVestType vest_type;
    address beneficiary;
    address token;
    uint256 amount;
    uint256 startline;
    uint256 deadline;
  }

  function vest(
    EVestType vest_type,
    address beneficiary,
    address token,
    uint256 amount,
    uint256 startline,
    uint256 deadline
  ) external;

  function vestETH(
    EVestType vest_type,
    address beneficiary,
    uint256 startline,
    uint256 deadline
  ) external payable;

  function releasable(address user, address token) external view returns (uint256);

  function release(address _token) external;

  function releasableETH(address user) external view returns (uint256);

  function releaseETH() external;

  event Vested(EVestType vest_type, address indexed beneficiary, address indexed token, uint256 amount, uint256 startline, uint256 deadline);

  event Released(address indexed beneficiary, address indexed token, uint256 amount);
}