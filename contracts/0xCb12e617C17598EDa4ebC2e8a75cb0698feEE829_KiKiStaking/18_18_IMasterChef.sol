// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

interface IMasterChef{
    
  function processDeposit(address account, uint _amount) external;

  function processWithdraw(address account, uint _amount) external;
}