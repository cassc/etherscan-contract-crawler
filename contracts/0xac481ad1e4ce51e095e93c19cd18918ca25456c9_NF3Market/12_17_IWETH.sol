// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IWETH {
    function deposit() external payable;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}