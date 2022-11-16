// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}