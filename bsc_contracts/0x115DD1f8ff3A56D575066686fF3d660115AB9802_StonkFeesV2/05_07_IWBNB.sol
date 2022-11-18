// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWBNB {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint wad) external;
}
