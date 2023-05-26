//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISpendable is IERC20 {
  function getSpendable(address) external view returns (uint256);
  function spend(address, uint256) external;
  function credit(address, uint256) external;
}