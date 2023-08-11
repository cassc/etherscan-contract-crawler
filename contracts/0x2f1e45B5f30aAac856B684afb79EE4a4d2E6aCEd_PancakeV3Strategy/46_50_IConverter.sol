// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IConverter {
    function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}