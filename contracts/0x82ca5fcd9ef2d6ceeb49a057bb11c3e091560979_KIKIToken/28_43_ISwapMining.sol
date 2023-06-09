// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISwapMining {
    function swap(address account, address input, address output, uint256 amount) external returns (bool);
}