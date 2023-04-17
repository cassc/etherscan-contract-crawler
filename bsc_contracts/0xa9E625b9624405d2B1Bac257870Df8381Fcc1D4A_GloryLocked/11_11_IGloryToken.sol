// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IGloryToken {
    function approve(address spender, uint256 amount) external;

    function mint(address receiver, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}