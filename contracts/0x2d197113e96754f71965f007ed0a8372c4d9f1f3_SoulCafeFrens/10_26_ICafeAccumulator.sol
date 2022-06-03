// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ICafeAccumulator {
    function pull(address) external returns (uint256);
}