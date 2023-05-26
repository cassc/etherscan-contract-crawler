// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOrbsNFT {
    function requestMint(address beneficiary, uint256 amount)
        external
        returns (bytes32);
}