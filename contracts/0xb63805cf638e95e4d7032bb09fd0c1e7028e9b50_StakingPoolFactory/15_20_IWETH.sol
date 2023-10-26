// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  
  function withdraw(uint wad) external;
}