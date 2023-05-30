// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}