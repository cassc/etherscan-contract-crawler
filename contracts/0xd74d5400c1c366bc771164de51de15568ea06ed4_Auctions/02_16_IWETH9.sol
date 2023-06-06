// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH9 is IERC20 {
  event  Deposit(address indexed dst, uint wad);
  event  Withdrawal(address indexed src, uint wad);

  function deposit() external payable;
  function withdraw(uint wad) external;
}