// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILido {
  function submit(address _referral) external payable returns (uint256);
}