// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVouchers{
    function mintBatch(address to, uint256 num, uint256 tokenType) external;
}