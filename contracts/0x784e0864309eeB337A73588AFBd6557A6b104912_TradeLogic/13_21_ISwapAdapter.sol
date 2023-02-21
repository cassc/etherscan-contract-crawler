// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapAdapter {
    function swap(
        address selling,
        address buying,
        uint256 amount,
        bytes memory data
    ) external returns (uint256);
}