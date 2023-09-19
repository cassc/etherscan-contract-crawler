// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Transfer {
    function transferFrom(address, address, uint256) external;
}