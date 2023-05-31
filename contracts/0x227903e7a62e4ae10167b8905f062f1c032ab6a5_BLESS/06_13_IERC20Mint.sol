// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC20Mint {
    function mint(address to, uint256 amount) external;
}