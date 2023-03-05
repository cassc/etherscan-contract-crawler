// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDVaultWithdrawer {
  function receiveVaultWithdrawalETH() external payable;
}