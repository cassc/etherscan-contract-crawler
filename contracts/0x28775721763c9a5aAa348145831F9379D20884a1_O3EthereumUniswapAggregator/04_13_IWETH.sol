// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;

    function transfer(address dst, uint wad) external returns (bool);
}