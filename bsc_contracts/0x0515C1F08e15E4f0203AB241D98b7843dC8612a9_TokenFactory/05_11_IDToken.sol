// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDToken {
    function mint(uint256 amount, address account) external;
    function burn(uint256 amount, address account) external;
    function burn(address account) external;
}