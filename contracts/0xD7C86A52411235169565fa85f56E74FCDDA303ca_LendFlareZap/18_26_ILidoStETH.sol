// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ILidoStETH {
  function submit(address _referral) external payable returns (uint256);
}