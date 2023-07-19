// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface MKRLike {
    function lock(uint256 amount) external;

    function free(uint256 amount) external;
}