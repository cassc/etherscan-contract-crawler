// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IToken {
    function mint(address _addr, uint256 _amount) external;

    function burn(address _addr, uint256 _amount) external;
}