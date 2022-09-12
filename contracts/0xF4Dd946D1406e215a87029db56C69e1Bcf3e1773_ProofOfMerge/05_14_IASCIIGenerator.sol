// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IASCIIGenerator {
    /**
     * @notice Generate full NFT metadata
     */
    function generateMetadata() external view returns (string memory);
}