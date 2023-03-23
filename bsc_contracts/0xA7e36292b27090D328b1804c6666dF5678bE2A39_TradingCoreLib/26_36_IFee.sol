// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IFee {
  struct Fee {
    uint128 fee;
    uint128 referredFee;
    uint128 referralFee;
    bytes32 referralCode;
    address referrer;
  }

  function getOpenFee(address _user) external view returns (Fee memory);

  function getCloseFee(address _user) external view returns (Fee memory);
}