// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IBalance {
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256);
}