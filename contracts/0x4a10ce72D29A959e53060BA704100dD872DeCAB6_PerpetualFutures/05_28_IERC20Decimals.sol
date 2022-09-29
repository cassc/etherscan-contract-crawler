// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}