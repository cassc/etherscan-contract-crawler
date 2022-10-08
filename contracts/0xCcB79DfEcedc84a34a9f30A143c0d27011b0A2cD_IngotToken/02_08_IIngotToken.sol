//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iIngotToken {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}