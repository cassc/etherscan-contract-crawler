pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}