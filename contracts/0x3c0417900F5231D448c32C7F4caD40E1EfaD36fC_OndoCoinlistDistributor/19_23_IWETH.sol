// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}