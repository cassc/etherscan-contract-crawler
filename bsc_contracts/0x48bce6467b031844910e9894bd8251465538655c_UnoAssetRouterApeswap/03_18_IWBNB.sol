// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
interface IWBNB {
    function deposit() external payable;
    function withdraw(uint wad) external;
}