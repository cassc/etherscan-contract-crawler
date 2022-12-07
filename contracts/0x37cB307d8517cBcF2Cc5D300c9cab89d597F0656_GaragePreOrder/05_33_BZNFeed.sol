// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

interface BZNFeed {
    /**
     * Returns the converted BZN value
     */
    function convert(uint256 usd) external view returns (uint256);
}