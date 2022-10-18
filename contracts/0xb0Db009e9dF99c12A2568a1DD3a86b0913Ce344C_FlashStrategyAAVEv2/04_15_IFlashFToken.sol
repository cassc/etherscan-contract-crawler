// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashFToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function decimals() external returns (uint8);
}