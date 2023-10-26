// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPoseidonHasher {
    function poseidon(uint256[2] calldata leftRight) external pure returns (uint256);
}