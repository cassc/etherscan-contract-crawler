// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICHI {
    function mint(uint256 value) external;

    function free(uint256 value) external returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}