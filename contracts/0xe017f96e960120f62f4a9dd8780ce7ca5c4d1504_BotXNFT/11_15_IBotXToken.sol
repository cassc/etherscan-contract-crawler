// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

interface IBotXToken {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}