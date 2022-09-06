// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISuseiStaking {
    function stakeFor(uint256[] calldata ids_, address owner_) external;
}