// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPrimordiaKey {
    function burn(address account, uint256 amount) external;

    function totalSupply(uint256 id) external returns (uint256);
}