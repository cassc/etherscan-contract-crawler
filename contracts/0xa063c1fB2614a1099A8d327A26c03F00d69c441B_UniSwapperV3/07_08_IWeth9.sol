//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWeth9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}