// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYieldSlice {
    function generatorToken() external view returns (IERC20);
    function yieldToken() external view returns (IERC20);

    function lock(uint256 amount, uint256 yield, uint256 npv, address who) external returns (uint256);
    function unlock(uint256 id) external returns (uint256);

    function claimable(uint256 id) external view returns (uint256);
    function claim(uint256 id) external returns (uint256);
}