// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IYieldSource {
    function yieldToken() external virtual view returns (IERC20);
    function generatorToken() external virtual view returns (IERC20);
    function setOwner(address) external virtual;
    function deposit(uint256 amount, bool claim) external virtual;
    function withdraw(uint256 amount, bool claim, address to) external virtual;
    function harvest() external virtual;
    function amountPending() external virtual view returns (uint256);
    function amountGenerator() external virtual view returns (uint256);
}