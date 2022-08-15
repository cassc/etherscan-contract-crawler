//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}