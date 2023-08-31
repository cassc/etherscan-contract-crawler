// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFitCoin is IERC20{
function mint(address to, uint256 amount) external;
function burn(uint256 amount) external;
function isAdmin(address account) external view returns (bool);
function setAdmin(address admin, bool enabled) external;
}