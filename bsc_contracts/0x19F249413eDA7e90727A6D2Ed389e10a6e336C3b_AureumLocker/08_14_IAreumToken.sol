pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IAreumToken {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}